import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event_model.dart';
import '../providers/events_provider.dart';
import '../utils/drag_selection_manager.dart';
import '../utils/color_mapper.dart';

class CalendarDayCell extends StatefulWidget {
  final DateTime date;
  final DragSelectionManager dragManager;
  final VoidCallback onDragEnd;
  final Function(DateTime) onDateTap;
  final Function(EventModel)? onEventTap;
  final bool isOtherMonth;
  final double cellWidth;

  const CalendarDayCell({
    super.key,
    required this.date,
    required this.dragManager,
    required this.onDragEnd,
    required this.onDateTap,
    this.onEventTap,
    this.isOtherMonth = false,
    this.cellWidth = 50.0, // Default fallback
  });

  @override
  State<CalendarDayCell> createState() => _CalendarDayCellState();
}

class _CalendarDayCellState extends State<CalendarDayCell> {
  bool _isHovered = false;
  bool _wasSelected = false;

  @override
  void initState() {
    super.initState();
    // Listen to drag manager changes to update when selection changes
    widget.dragManager.addListener(_onDragChanged);
  }

  @override
  void dispose() {
    widget.dragManager.removeListener(_onDragChanged);
    super.dispose();
  }

  void _onDragChanged() {
    if (!mounted) return;

    // Check if pointer is over this cell
    final pointerPos = widget.dragManager.currentPointerPosition;
    if (pointerPos != null && widget.dragManager.isActive) {
      if (_isPositionOverCell(pointerPos)) {
        widget.dragManager.updateDrag(widget.date);
      }
    }

    // Only rebuild if this cell's selection state changed
    final isNowSelected = widget.dragManager.isDateSelected(widget.date);
    if (isNowSelected != _wasSelected) {
      _wasSelected = isNowSelected;
      setState(() {
        // Rebuild only when selection state changes for this cell
      });
    }
  }

  // Check if a global position is over this cell
  bool _isPositionOverCell(Offset globalPosition) {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return false;

    final localPosition = box.globalToLocal(globalPosition);
    final size = box.size;

    return localPosition.dx >= 0 &&
        localPosition.dx <= size.width &&
        localPosition.dy >= 0 &&
        localPosition.dy <= size.height;
  }

  @override
  Widget build(BuildContext context) {
    final eventsProvider = Provider.of<EventsProvider>(context);
    final events = widget.isOtherMonth ? <EventModel>[] : eventsProvider.getEventsForDate(widget.date);
    final isToday = !widget.isOtherMonth && _isToday(widget.date);
    final isPast = widget.date.isBefore(
      DateTime.now().subtract(const Duration(days: 1)),
    );
    final isWeekend = widget.date.weekday == 6 || widget.date.weekday == 7;
    final isSelected = !widget.isOtherMonth && widget.dragManager.isDateSelected(widget.date);

    // Check if this cell has any multi-day events
    final hasMultiDayEvents = events.any((e) => e.isMultiDay());

    // Check if neighboring cells are selected for border removal
    final selectedDates = widget.dragManager.getSelectedDates();
    final prevDate = widget.date.subtract(const Duration(days: 1));
    final nextDate = widget.date.add(const Duration(days: 1));
    final isPrevSelected = selectedDates.contains(DateTime(prevDate.year, prevDate.month, prevDate.day));
    final isNextSelected = selectedDates.contains(DateTime(nextDate.year, nextDate.month, nextDate.day));

    // Check if this is the start or end of selection
    final isSelectionStart = isSelected && !isPrevSelected;
    final isSelectionEnd = isSelected && !isNextSelected;

    return GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        // Simple tap
        onTap: () {
          if (!widget.dragManager.isActive) {
            widget.onDateTap(widget.date);
          } else {
            // Tap during drag = end drag
            widget.onDragEnd();
          }
        },
        // Drag: Start with long press (short delay, avoids scroll conflict)
        onLongPressStart: (_) {
          widget.dragManager.startDrag(widget.date);
        },
        // Drag: Track movement during long press
        onLongPressMoveUpdate: (details) {
          if (!widget.dragManager.isActive) return;

          // Broadcast pointer position - all cells will check if it's over them
          widget.dragManager.updatePointerPosition(details.globalPosition);
        },
        // Drag: End (release finger after long press)
        onLongPressEnd: (_) {
          widget.onDragEnd();
        },
        // Drag: Cancel if user moves too much before long press triggers
        onLongPressCancel: () {
          widget.dragManager.cancelDrag();
        },
        child: ClipRect(
          clipBehavior: Clip.none, // Allow overflow for multi-day event titles
          child: Container(
            decoration: BoxDecoration(
              color: _getBackgroundColor(isWeekend, isPast, isToday, isSelected),
              border: isSelected
                  ? Border(
                      top: BorderSide(color: Colors.blue[600]!, width: 2),
                      bottom: BorderSide(color: Colors.blue[600]!, width: 2),
                      left: isSelectionStart
                          ? BorderSide(color: Colors.blue[600]!, width: 2)
                          : BorderSide(color: Colors.transparent, width: 0),
                      right: isSelectionEnd
                          ? BorderSide(color: Colors.blue[600]!, width: 2)
                          : BorderSide(color: Colors.transparent, width: 0),
                    )
                  : (hasMultiDayEvents
                      ? null // No border when multi-day events present to avoid gaps
                      : Border.all(
                          color: isToday ? Colors.blue[600]! : Colors.grey[300]!,
                          width: isToday ? 3 : 0.5,
                        )),
              boxShadow: isSelected || isToday
                  ? [
                      BoxShadow(
                        color: Colors.blue.withOpacity(isSelected ? 0.5 : 0.3),
                        blurRadius: isSelected ? 12 : 8,
                        spreadRadius: isSelected ? 2 : 1,
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              clipBehavior: Clip.none, // Allow children to overflow
            children: [
              // Multi-day event borders (drawn behind everything) - visual only, not tappable
              ...events.where((e) => e.isMultiDay()).map((event) {
                // Only show border, no background on non-start cells to avoid dimming the title
                final isStartCell = _isStartDate(event);
                return Positioned.fill(
                  child: IgnorePointer(
                    child: _buildMultiDayEventBorder(event, showBackground: isStartCell),
                  ),
                );
              }),

              // Day number - centered with today highlight
              IgnorePointer(
                child: Center(
                child: isToday
                    ? Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue[400]!, Colors.blue[600]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Text(
                          '${widget.date.day}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : Text(
                        '${widget.date.day}',
                        style: TextStyle(
                          fontSize: 14,
                          color: widget.isOtherMonth
                              ? Colors.grey[400]
                              : (isPast ? Colors.grey : Colors.black87),
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                ),
              ),

              // Single day events (stacked on top of each other)
              if (events.where((e) => !e.isMultiDay()).isNotEmpty)
                Positioned(
                  bottom: 2,
                  left: 2,
                  right: 2,
                  child: _buildSingleDayEvents(events.where((e) => !e.isMultiDay()).toList()),
                ),

              // Multi-day event title (only on start date) - positioned at top, ABOVE everything
              ...events.where((e) => e.isMultiDay()).map((event) {
                if (_isStartDate(event)) {
                  // Calculate how many days this event spans
                  final startDate = DateTime(event.dateStart.year, event.dateStart.month + 1, event.dateStart.date);
                  final endDate = DateTime(event.dateEnd.year, event.dateEnd.month + 1, event.dateEnd.date);
                  final daysDuration = endDate.difference(startDate).inDays + 1;

                  // Allow title to extend up to 1.5 cells, but cap at event duration
                  final maxCells = daysDuration < 1.5 ? daysDuration.toDouble() : 1.5;
                  final titleMaxWidth = (widget.cellWidth * maxCells) - 8;

                  return Positioned(
                    top: 0,
                    left: 0,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (_) {}, // Capture tap to prevent parent from handling
                      onTap: () {
                        if (widget.onEventTap != null) {
                          widget.onEventTap!(event);
                        }
                      },
                      child: Container(
                        // Add transparent padding to increase tap area
                        padding: const EdgeInsets.all(2),
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: titleMaxWidth,
                            minHeight: 18, // Ensure minimum tap target
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: _parseColor(event.categoryColor).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            '${event.emoji} ${event.title}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),

              // Past day strike-through effect
              if (isPast)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(painter: StrikeThroughPainter()),
                  ),
                ),
            ],
            ),
          ),
        ),
    );
  }

  Widget _buildMultiDayEventBorder(EventModel event, {bool showBackground = true}) {
    final eventColor = _parseColor(event.categoryColor);
    final dateString = _dateToString(widget.date);
    final startString = event.dateStart.toISOString();
    final endString = event.dateEnd.toISOString();

    // Determine which borders to show
    final isStart = dateString == startString;
    final isEnd = dateString == endString;

    return Container(
      decoration: BoxDecoration(
        // Only show background on start cell to avoid dimming the extended title text
        color: showBackground ? eventColor.withOpacity(0.03) : Colors.transparent,
        border: Border(
          top: BorderSide(color: eventColor, width: 3),
          bottom: BorderSide(color: eventColor, width: 3),
          left: isStart
              ? BorderSide(color: eventColor, width: 3)
              : BorderSide(color: Colors.transparent, width: 0),
          right: isEnd
              ? BorderSide(color: eventColor, width: 3)
              : BorderSide(color: Colors.transparent, width: 0),
        ),
      ),
    );
  }

  Widget _buildSingleDayEvents(List<EventModel> events) {
    // Show all single day events stacked on top of each other
    final displayEvents = events.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: displayEvents.map((event) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) {}, // Capture tap to prevent parent from handling
          onTap: () {
            if (widget.onEventTap != null) {
              widget.onEventTap!(event);
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 1),
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
            decoration: BoxDecoration(
              color: _parseColor(event.categoryColor).withOpacity(0.2),
              border: Border.all(
                color: _parseColor(event.categoryColor),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              '${event.emoji} ${event.title}',
              style: TextStyle(
                fontSize: 9,
                color: _parseColor(event.categoryColor),
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }).toList(),
    );
  }

  bool _isStartDate(EventModel event) {
    final dateString = _dateToString(widget.date);
    return dateString == event.dateStart.toISOString();
  }

  String _dateToString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Color _getBackgroundColor(bool isWeekend, bool isPast, bool isToday, bool isSelected) {
    if (isSelected) return Colors.blue[200]!.withOpacity(0.8);
    if (isToday) return Colors.blue[50]!.withOpacity(0.5);
    if (_isHovered) return Colors.blue[100]!.withOpacity(0.3);
    if (isWeekend) return Colors.blue[50]!.withOpacity(0.2);
    return Colors.white.withOpacity(0.8);
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Color _parseColor(String colorString) {
    return ColorMapper.parseColor(colorString);
  }
}

class StrikeThroughPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1;

    // Draw X pattern for past days
    canvas.drawLine(const Offset(0, 0), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
