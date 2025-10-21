import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/events_provider.dart';
import '../providers/calendars_provider.dart';
import '../providers/settings_provider.dart';
import '../models/event_model.dart';
import '../widgets/calendar_grid.dart';
import '../widgets/event_form_bottom_sheet.dart';
import '../widgets/calendar_filter_chips.dart';
import '../widgets/app_drawer.dart';
import '../utils/drag_selection_manager.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<MonthData> _visibleMonths = [];
  bool _isLoadingMore = false;
  bool _initialized = false;

  // Drag selection manager
  final DragSelectionManager _dragManager = DragSelectionManager();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _dragManager.addListener(_onDragSelectionChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initializeMonths();
      // Listen to events and calendars after build is complete
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<EventsProvider>(context, listen: false).listenToEvents();
        Provider.of<CalendarsProvider>(context, listen: false).listenToCalendars();
      });
      _initialized = true;
    }
  }

  void _initializeMonths() {
    final now = DateTime.now();

    // Load 3 months before and 9 months after current month for better scrolling
    // This ensures enough content to enable scrolling
    for (int i = -3; i <= 9; i++) {
      final date = DateTime(now.year, now.month + i, 1);
      _visibleMonths.add(MonthData(year: date.year, month: date.month));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentMonth();
    });
  }

  void _scrollToCurrentMonth() {
    final now = DateTime.now();
    _scrollToMonth(now.year, now.month);
  }

  void _scrollToMonth(int year, int month) {
    // Check if the month is in visible months
    int monthIndex = _visibleMonths.indexWhere(
      (m) => m.year == year && m.month == month,
    );

    // Scroll to the month
    if (monthIndex != -1) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          // Calculate position: subtract 1 month height to show a bit of previous month
          final targetPosition = (monthIndex - 1).clamp(0, monthIndex) * 400.0;
          _scrollController.animateTo(
            targetPosition,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  void _onScroll() {
    if (_isLoadingMore || !_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final minScroll = _scrollController.position.minScrollExtent;
    final viewportHeight = _scrollController.position.viewportDimension;

    // Load next months when approaching bottom (within 2 months worth of scroll)
    if (currentScroll >= maxScroll - (viewportHeight * 0.5)) {
      _loadNextMonths();
    }

    // Load previous months when approaching top (within 1 month worth of scroll)
    if (currentScroll <= minScroll + (viewportHeight * 0.3)) {
      _loadPreviousMonths();
    }
  }

  void _loadNextMonths() {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    final lastMonth = _visibleMonths.last;
    // Add 6 months at a time for smoother experience
    for (int i = 1; i <= 6; i++) {
      final nextDate = DateTime(lastMonth.year, lastMonth.month + i, 1);
      _visibleMonths.add(MonthData(year: nextDate.year, month: nextDate.month));
    }

    setState(() {
      _isLoadingMore = false;
    });
  }

  void _loadPreviousMonths() {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    // Store current scroll position
    final currentScrollOffset = _scrollController.offset;

    final firstMonth = _visibleMonths.first;
    // Add 6 months at a time for smoother experience
    final monthsToAdd = <MonthData>[];
    for (int i = 6; i >= 1; i--) {
      final prevDate = DateTime(firstMonth.year, firstMonth.month - i, 1);
      monthsToAdd.add(MonthData(year: prevDate.year, month: prevDate.month));
    }

    _visibleMonths.insertAll(0, monthsToAdd);

    setState(() {
      _isLoadingMore = false;
    });

    // Restore scroll position after adding previous months
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        // Estimate the height of months added (approximate)
        final estimatedMonthHeight = 400.0;
        final addedHeight = monthsToAdd.length * estimatedMonthHeight;
        _scrollController.jumpTo(currentScrollOffset + addedHeight);
      }
    });
  }

  void _openEventForm(DateTime startDate, DateTime endDate, {EventModel? event}) async {
    final result = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EventFormBottomSheet(
        startDate: startDate,
        endDate: endDate,
        event: event,
      ),
    );

    // If a date was returned, scroll to that month (for newly created events)
    if (result != null && mounted) {
      _scrollToMonth(result.year, result.month);
    }
  }

  void _onEventTap(EventModel event) {
    final startDate = DateTime(
      event.dateStart.year,
      event.dateStart.month + 1, // Convert from 0-based to 1-based
      event.dateStart.date,
    );
    final endDate = DateTime(
      event.dateEnd.year,
      event.dateEnd.month + 1, // Convert from 0-based to 1-based
      event.dateEnd.date,
    );
    _openEventForm(startDate, endDate, event: event);
  }

  // Called when drag selection changes
  void _onDragSelectionChanged() {
    setState(() {
      // Just trigger rebuild to show selected dates
    });
  }

  // Called when drag ends
  void _onDragEnd() {
    final result = _dragManager.endDrag();
    if (result != null) {
      _openEventForm(result['start']!, result['end']!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue[50]!.withOpacity(0.3),
              Colors.purple[50]!.withOpacity(0.2),
              Colors.pink[50]!.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
        children: [
          // Calendar filter chips at the very top
          SafeArea(
            bottom: false,
            child: const CalendarFilterChips(),
          ),
          // Weekday labels - subtle
          Container(
            padding: const EdgeInsets.only(
              left: 8,
              right: 8,
              top: 4,
              bottom: 4,
            ),
            child: _buildWeekdayHeader(),
          ),
          // Calendar content
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(
                top: 0,
                left: 8,
                right: 8,
                bottom: 8,
              ),
              itemCount: _visibleMonths.length,
              itemBuilder: (context, index) {

                final monthData = _visibleMonths[index];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: CalendarGrid(
                    year: monthData.year,
                    month: monthData.month,
                    dragManager: _dragManager,
                    onDragEnd: _onDragEnd,
                    onDateTap: (date) => _openEventForm(date, date),
                    onEventTap: _onEventTap,
                  ),
                );
              },
            ),
          ),
        ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Menu button on the left
            Builder(
              builder: (context) => _buildMenuButton(context),
            ),
            // Today button on the right
            _buildTodayButton(),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildMenuButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Scaffold.of(context).openDrawer(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.85),
                  Colors.white.withOpacity(0.75),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withOpacity(0.9),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 24,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.menu_rounded,
                  size: 18,
                  color: Colors.grey[800],
                ),
                const SizedBox(width: 10),
                Text(
                  'Menu',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[900],
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeekdayHeader() {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    // Weekday labels based on week start preference
    final weekdays = settingsProvider.weekStartsOnMonday
        ? ['M', 'T', 'W', 'T', 'F', 'S', 'S'] // Monday first
        : ['S', 'M', 'T', 'W', 'T', 'F', 'S']; // Sunday first

    return Row(
      children: weekdays.map((day) {
        return Expanded(
          child: Center(
            child: Text(
              day,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600]!.withOpacity(0.65),
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTodayButton() {
    final now = DateTime.now();
    final dateText = '${now.day} ${_getShortMonthName(now.month)}';

    return GestureDetector(
      onTap: _scrollToCurrentMonth,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.85),
                  Colors.white.withOpacity(0.75),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withOpacity(0.9),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 24,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Up arrow icon
                Icon(
                  Icons.arrow_upward_rounded,
                  size: 18,
                  color: Colors.blue[700],
                ),
                const SizedBox(width: 10),
                // Date text
                Text(
                  dateText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[900],
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getShortMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }


  @override
  void dispose() {
    _scrollController.dispose();
    _dragManager.removeListener(_onDragSelectionChanged);
    _dragManager.dispose();
    super.dispose();
  }
}

class MonthData {
  final int year;
  final int month;

  MonthData({required this.year, required this.month});
}

class TriangleArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final path = Path();

    // Triangle pointing up
    path.moveTo(size.width / 2, 0); // Top point
    path.lineTo(size.width, size.height); // Bottom right
    path.lineTo(0, size.height); // Bottom left
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
