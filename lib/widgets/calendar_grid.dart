import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event_model.dart';
import '../providers/settings_provider.dart';
import '../utils/drag_selection_manager.dart';
import 'calendar_day_cell.dart';

class CalendarGrid extends StatefulWidget {
  final int year;
  final int month;
  final DragSelectionManager dragManager;
  final VoidCallback onDragEnd;
  final Function(DateTime) onDateTap;
  final Function(EventModel)? onEventTap;

  const CalendarGrid({
    super.key,
    required this.year,
    required this.month,
    required this.dragManager,
    required this.onDragEnd,
    required this.onDateTap,
    this.onEventTap,
  });

  @override
  State<CalendarGrid> createState() => _CalendarGridState();
}

class _CalendarGridState extends State<CalendarGrid> {
  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final daysInMonth = DateTime(widget.year, widget.month + 1, 0).day;
    final firstDayOfMonth = DateTime(widget.year, widget.month, 1);
    final weekdayOfFirst = firstDayOfMonth.weekday;

    // Calculate offset for first day based on week start preference
    // weekday: Monday = 1, Tuesday = 2, ..., Sunday = 7
    final int firstDayOffset;
    if (settingsProvider.weekStartsOnMonday) {
      // Week starts Monday: Monday = 0, Tuesday = 1, ..., Sunday = 6
      firstDayOffset = weekdayOfFirst - 1;
    } else {
      // Week starts Sunday: Sunday = 0, Monday = 1, ..., Saturday = 6
      firstDayOffset = weekdayOfFirst == 7 ? 0 : weekdayOfFirst;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month name with spacing
        LayoutBuilder(
          builder: (context, constraints) {
            final cellWidth = constraints.maxWidth / 7;
            final halfCellSpacing = cellWidth / 2;
            return Padding(
              padding: EdgeInsets.only(left: 8.0, bottom: halfCellSpacing, top: 8.0),
              child: Text(
                _getMonthName(widget.month),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          },
        ),
        // Calendar grid using Wrap for compact layout
        LayoutBuilder(
          builder: (context, constraints) {
            final cellWidth = constraints.maxWidth / 7;

            // Rebuild cells with cell width information
            final cellsWithWidth = <Widget>[];

            // Add empty cells for offset
            for (int i = 0; i < firstDayOffset; i++) {
              cellsWithWidth.add(const SizedBox.shrink());
            }

            // Add actual day cells with cell width
            for (int day = 1; day <= daysInMonth; day++) {
              final date = DateTime(widget.year, widget.month, day);
              cellsWithWidth.add(
                CalendarDayCell(
                  date: date,
                  dragManager: widget.dragManager,
                  onDragEnd: widget.onDragEnd,
                  onDateTap: widget.onDateTap,
                  onEventTap: widget.onEventTap,
                  cellWidth: cellWidth,
                ),
              );
            }

            return Wrap(
              spacing: 2,  // Small horizontal gap between days
              runSpacing: 2,  // Small vertical gap between weeks
              children: cellsWithWidth.map((cell) {
                return SizedBox(
                  width: cellWidth - 2,  // Adjust width to account for spacing
                  height: cellWidth - 2,  // Adjust height to account for spacing
                  child: cell,
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }
}
