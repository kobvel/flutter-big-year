import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calendars_provider.dart';
import '../providers/events_provider.dart';
import '../models/calendar_model.dart';
import '../utils/color_mapper.dart';

class CalendarFilterChips extends StatefulWidget {
  const CalendarFilterChips({super.key});

  @override
  State<CalendarFilterChips> createState() => _CalendarFilterChipsState();
}

class _CalendarFilterChipsState extends State<CalendarFilterChips> {
  final ScrollController _scrollController = ScrollController();
  String? _highlightedCalendarId;
  List<String> _previousSelectedIds = [];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _checkForNewSelection(List<String> selectedIds, List<CalendarModel> calendars) {
    // Check if a new calendar was just selected (not in previous list)
    for (final id in selectedIds) {
      if (!_previousSelectedIds.contains(id)) {
        // New calendar selected, scroll to it with a delay to ensure it's rendered
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToCalendar(id, calendars);
        });
        break; // Only scroll to the first new one
      }
    }
    _previousSelectedIds = List.from(selectedIds);
  }

  void _scrollToCalendar(String calendarId, List<CalendarModel> calendars) {
    final index = calendars.indexWhere((c) => c.id == calendarId);
    if (index == -1) return;

    // Calculate scroll position (approximate chip width + padding)
    const chipWidth = 100.0; // Approximate
    final scrollPosition = index * chipWidth;

    _scrollController.animateTo(
      scrollPosition,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );

    // Highlight the calendar temporarily
    setState(() {
      _highlightedCalendarId = calendarId;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _highlightedCalendarId = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<CalendarsProvider, EventsProvider>(
      builder: (context, calendarsProvider, eventsProvider, child) {
        final calendars = calendarsProvider.calendars;
        final selectedIds = eventsProvider.selectedCalendarIds;

        if (calendars.isEmpty) {
          return const SizedBox.shrink();
        }

        // Auto-initialize selection to show all calendars on first load
        final allIds = calendars.map((c) => c.id!).toList();
        if (!eventsProvider.isInitialized && allIds.isNotEmpty) {
          // Use post-frame callback to avoid calling during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            eventsProvider.initializeCalendarSelection(allIds);
          });
        }

        // Clean up any deleted calendar IDs from selection
        WidgetsBinding.instance.addPostFrameCallback((_) {
          eventsProvider.cleanupDeletedCalendars(allIds);
        });

        // Check for newly selected calendars and auto-scroll
        _checkForNewSelection(selectedIds, calendars);

        // Check if all calendars are selected
        // Note: empty list now means "hide all", not "show all"
        final allIdsSet = allIds.toSet();
        final selectedIdSet = selectedIds.toSet();
        final allSelected = selectedIdSet.length == allIdsSet.length &&
            selectedIdSet.containsAll(allIdsSet);
        final noneSelected = selectedIds.isEmpty;

        return SizedBox(
          width: double.infinity,
          height: 44,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Single filter toggle button with badge
                _buildFilterToggleButton(
                  context,
                  selectedCount: selectedIds.length,
                  totalCount: calendars.length,
                  onTap: () {
                    // Cycle through states: All → None → All
                    if (allSelected || selectedIds.isEmpty) {
                      // If all selected or none selected, toggle to opposite
                      if (allSelected) {
                        eventsProvider.setSelectedCalendars([]);
                      } else {
                        final allIds = calendars.map((c) => c.id!).toList();
                        eventsProvider.setSelectedCalendars(allIds);
                      }
                    } else {
                      // If partial selection, go to all
                      final allIds = calendars.map((c) => c.id!).toList();
                      eventsProvider.setSelectedCalendars(allIds);
                    }
                  },
                ),
                const SizedBox(width: 12),
                // Horizontal scrolling calendar chips
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.zero,
                    itemCount: calendars.length,
                    itemBuilder: (context, index) {
                      final calendar = calendars[index];
                      final isSelected = selectedIds.contains(calendar.id);
                      final isHighlighted = calendar.id == _highlightedCalendarId;

                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: AnimatedScale(
                          scale: isHighlighted ? 1.1 : 1.0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: _buildGlassCalendarChip(
                            context,
                            calendar: calendar,
                            isSelected: isSelected,
                            isHighlighted: isHighlighted,
                            onTap: () {
                              eventsProvider.toggleCalendarSelection(calendar.id!);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterToggleButton(
    BuildContext context, {
    required int selectedCount,
    required int totalCount,
    required VoidCallback onTap,
  }) {
    final bool allSelected = selectedCount == totalCount;
    final bool noneSelected = selectedCount == 0;

    // Determine state and styling
    final String badgeText = allSelected
        ? 'All'
        : noneSelected
            ? 'None'
            : '$selectedCount/$totalCount';

    final Color badgeBgColor = allSelected
        ? Colors.green.withOpacity(0.2)
        : noneSelected
            ? Colors.grey.withOpacity(0.2)
            : Colors.blue.withOpacity(0.2);

    final Color badgeBorderColor = allSelected
        ? Colors.green.withOpacity(0.6)
        : noneSelected
            ? Colors.grey.withOpacity(0.6)
            : Colors.blue.withOpacity(0.6);

    final Color badgeTextColor = allSelected
        ? Colors.green[800]!
        : noneSelected
            ? Colors.grey[800]!
            : Colors.blue[800]!;

    final IconData icon = allSelected
        ? Icons.visibility_rounded
        : noneSelected
            ? Icons.visibility_off_rounded
            : Icons.filter_list_rounded;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.7),
                  Colors.white.withOpacity(0.5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withOpacity(0.9),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: Colors.grey[800],
                ),
                const SizedBox(width: 6),
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeBgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: badgeBorderColor,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: badgeTextColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCalendarChip(
    BuildContext context, {
    required CalendarModel calendar,
    required bool isSelected,
    required bool isHighlighted,
    required VoidCallback onTap,
  }) {
    final chipColor = calendar.color != null
        ? _parseColor(calendar.color!)
        : Colors.blue[400]!;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isSelected
                    ? [
                        chipColor.withOpacity(0.45),
                        chipColor.withOpacity(0.3),
                      ]
                    : [
                        Colors.white.withOpacity(0.5),
                        Colors.white.withOpacity(0.35),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? chipColor.withOpacity(0.8)
                    : Colors.white.withOpacity(0.7),
                width: isHighlighted ? 2.5 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? chipColor.withOpacity(0.25)
                      : Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
                if (isHighlighted)
                  BoxShadow(
                    color: chipColor.withOpacity(0.5),
                    blurRadius: 16,
                    spreadRadius: 2,
                    offset: const Offset(0, 0),
                  ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  calendar.emoji,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 4),
                Text(
                  calendar.name,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected
                        ? _getContrastColor(chipColor)
                        : Colors.grey[800],
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isSelected) ...[
                  const SizedBox(width: 3),
                  Icon(
                    Icons.check_circle_rounded,
                    size: 11,
                    color: _getContrastColor(chipColor),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getContrastColor(Color backgroundColor) {
    // Calculate luminance
    final luminance = backgroundColor.computeLuminance();
    // Return dark color for light backgrounds, light color for dark backgrounds
    return luminance > 0.5 ? Colors.grey[900]! : Colors.white;
  }

  Color _parseColor(String colorString) {
    return ColorMapper.parseColor(colorString);
  }
}
