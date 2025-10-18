import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/events_provider.dart';
import '../models/event_model.dart';
import '../widgets/calendar_grid.dart';
import '../widgets/event_form_bottom_sheet.dart';
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
      // Listen to events after build is complete
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<EventsProvider>(context, listen: false).listenToEvents();
      });
      _initialized = true;
    }
  }

  void _initializeMonths() {
    final now = DateTime.now();
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      // Mobile: Show only current month and next month
      for (int i = 0; i < 2; i++) {
        final date = DateTime(now.year, now.month + i, 1);
        _visibleMonths.add(MonthData(year: date.year, month: date.month));
      }
    } else {
      // Desktop: Show current month and next month
      for (int i = 0; i < 2; i++) {
        final date = DateTime(now.year, now.month + i, 1);
        _visibleMonths.add(MonthData(year: date.year, month: date.month));
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentMonth();
    });
  }

  void _scrollToCurrentMonth() {
    final now = DateTime.now();

    // Check if current month is in visible months
    int currentMonthIndex = _visibleMonths.indexWhere(
      (m) => m.year == now.year && m.month == now.month,
    );

    // If not found, reload months around current month
    if (currentMonthIndex == -1) {
      setState(() {
        _visibleMonths.clear();
        // Load current month and next month
        for (int i = 0; i < 2; i++) {
          final date = DateTime(now.year, now.month + i, 1);
          _visibleMonths.add(MonthData(year: date.year, month: date.month));
        }
      });
      currentMonthIndex = 0; // Current month is now at index 0
    }

    // Scroll to current month
    if (currentMonthIndex != -1) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            currentMonthIndex * 400.0, // Approximate month height
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  void _onScroll() {
    if (_isLoadingMore) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final minScroll = _scrollController.position.minScrollExtent;

    // Load next month when near bottom
    if (currentScroll >= maxScroll - 100) {
      _loadNextMonths();
    }

    // Load previous month when near top (pull to load)
    if (currentScroll <= minScroll + 100) {
      _loadPreviousMonths();
    }
  }

  void _loadNextMonths() {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    final lastMonth = _visibleMonths.last;
    // Add 1 month at a time
    final nextDate = DateTime(lastMonth.year, lastMonth.month + 1, 1);
    _visibleMonths.add(MonthData(year: nextDate.year, month: nextDate.month));

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
    // Add 1 month at a time
    final prevDate = DateTime(firstMonth.year, firstMonth.month - 1, 1);
    _visibleMonths.insert(
        0, MonthData(year: prevDate.year, month: prevDate.month));

    setState(() {
      _isLoadingMore = false;
    });

    // Restore scroll position after adding previous month
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        // Estimate the height of one month (approximate)
        final estimatedMonthHeight = 400.0;
        _scrollController.jumpTo(currentScrollOffset + estimatedMonthHeight);
      }
    });
  }

  void _openEventForm(DateTime startDate, DateTime endDate, {EventModel? event}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EventFormBottomSheet(
        startDate: startDate,
        endDate: endDate,
        event: event,
      ),
    );
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
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
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
          // Weekday labels at top - subtle and accounting for iOS safe area
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 4,
              left: 8,
              right: 8,
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
      floatingActionButton: _buildTodayButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildWeekdayHeader() {
    const weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.4),
              Colors.white.withOpacity(0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withOpacity(0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
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
              color: Colors.blue[700]!.withOpacity(0.8),
            ),
            const SizedBox(width: 10),
            // Date text
            Text(
              dateText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.blue[800]!.withOpacity(0.85),
                letterSpacing: 0.3,
              ),
            ),
          ],
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
