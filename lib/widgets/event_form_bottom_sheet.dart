import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../models/calendar_model.dart';
import '../providers/events_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/calendars_provider.dart';
import '../utils/color_mapper.dart';

class EventFormBottomSheet extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final EventModel? event;

  const EventFormBottomSheet({
    super.key,
    required this.startDate,
    required this.endDate,
    this.event,
  });

  @override
  State<EventFormBottomSheet> createState() => _EventFormBottomSheetState();
}

class _EventFormBottomSheetState extends State<EventFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late DateTime _selectedStartDate;
  late DateTime _selectedEndDate;
  String _selectedEmoji = '📅';
  String _selectedColor = '#3B82F6';
  String? _selectedCalendarId;

  final List<String> _emojiOptions = [
    '📅',
    '🎉',
    '💼',
    '🏃',
    '🎯',
    '📚',
    '🎨',
    '🍽️',
    '✈️',
    '🏠'
  ];

  final List<String> _colorOptions = [
    '#3B82F6', // Blue
    '#EF4444', // Red
    '#10B981', // Green
    '#F59E0B', // Yellow
    '#8B5CF6', // Purple
    '#EC4899', // Pink
    '#14B8A6', // Teal
    '#F97316', // Orange
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event?.title ?? '');
    _selectedStartDate = widget.startDate;
    _selectedEndDate = widget.endDate;
    if (widget.event != null) {
      _selectedEmoji = widget.event!.emoji;
      _selectedColor = widget.event!.categoryColor;
      _selectedCalendarId = widget.event!.calendarId;
    } else {
      // For new events, select a calendar intelligently after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final calendarsProvider = Provider.of<CalendarsProvider>(context, listen: false);
        final eventsProvider = Provider.of<EventsProvider>(context, listen: false);

        if (calendarsProvider.calendars.isEmpty || !mounted) return;

        // Get currently selected calendar IDs from the filter
        final selectedCalendarIds = eventsProvider.selectedCalendarIds;

        // If there are selected calendars, pick the first one
        // Otherwise, fall back to the first calendar in the list
        String? defaultCalendarId;
        if (selectedCalendarIds.isNotEmpty) {
          // Find the first selected calendar that still exists
          defaultCalendarId = selectedCalendarIds.firstWhere(
            (id) => calendarsProvider.calendars.any((cal) => cal.id == id),
            orElse: () => calendarsProvider.calendars.first.id!,
          );
        } else {
          defaultCalendarId = calendarsProvider.calendars.first.id;
        }

        setState(() {
          _selectedCalendarId = defaultCalendarId;
        });
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  String _getEventDuration() {
    final difference = _selectedEndDate.difference(_selectedStartDate).inDays + 1;
    if (difference == 1) {
      return '1 day';
    } else {
      return '$difference days';
    }
  }

  String _getTimeUntilEvent() {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfEventDay = DateTime(
      _selectedStartDate.year,
      _selectedStartDate.month,
      _selectedStartDate.day,
    );
    final difference = startOfEventDay.difference(startOfToday).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference == -1) {
      return 'Yesterday';
    } else if (difference > 0) {
      return 'In $difference days';
    } else {
      return '${-difference} days ago';
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('d MMM yy').format(date);
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final eventsProvider = Provider.of<EventsProvider>(context, listen: false);
    final calendarsProvider = Provider.of<CalendarsProvider>(context, listen: false);

    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to create events')),
      );
      return;
    }

    // Ensure a calendar is selected
    final calendarId = _selectedCalendarId ?? calendarsProvider.calendars.firstOrNull?.id;

    if (calendarId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create a calendar first')),
      );
      return;
    }

    final event = EventModel(
      id: widget.event?.id,
      userId: authProvider.user!.uid,
      title: _titleController.text.trim(),
      calendarId: calendarId,
      emoji: _selectedEmoji,
      shared: false,
      categoryColor: _selectedColor,
      sharedWithUserIds: [],
      sharedWithEmails: [],
      dateStart: DateProps.fromDateTime(_selectedStartDate),
      dateEnd: DateProps.fromDateTime(_selectedEndDate),
    );

    try {
      if (widget.event == null) {
        // Create new event
        await eventsProvider.createEvent(event);

        // Auto-select the calendar if it's not already selected
        eventsProvider.ensureCalendarSelected(calendarId);

        if (mounted) {
          // Return the start date so we can scroll to it
          Navigator.of(context).pop(_selectedStartDate);
        }
      } else {
        // Update existing event
        await eventsProvider.updateEvent(widget.event!.id!, event);
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving event: $e')),
        );
      }
    }
  }

  Future<void> _selectDate(bool isStartDate) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _selectedStartDate : _selectedEndDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      setState(() {
        if (isStartDate) {
          _selectedStartDate = date;
          if (_selectedEndDate.isBefore(_selectedStartDate)) {
            _selectedEndDate = _selectedStartDate;
          }
        } else {
          _selectedEndDate = date;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.event != null;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.blue[50]!.withOpacity(0.3),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        snap: false,
        expand: false,
        builder: (context, scrollController) {
          final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

          return Form(
            key: _formKey,
            child: ListView(
              controller: scrollController,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: bottomPadding > 0 ? bottomPadding + 24 : 24,
              ),
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header
                Text(
                  isEditing ? 'Edit Event' : 'New Event',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Title input with emoji selector
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Emoji button
                    InkWell(
                      onTap: _showEmojiPicker,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            _selectedEmoji,
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title field
                    Expanded(
                      child: TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Date range with duration
                Row(
                  children: [
                    Expanded(
                      child: _buildDateButton(
                        'Start Date',
                        _selectedStartDate,
                        () => _selectDate(true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDateButton(
                        'End Date',
                        _selectedEndDate,
                        () => _selectDate(false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Duration and time info
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time, color: Colors.blue[700], size: 18),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _getEventDuration(),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[900],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purple[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.purple[200]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.event, color: Colors.purple[700], size: 18),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _getTimeUntilEvent(),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.purple[900],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Calendar selector
                Consumer<CalendarsProvider>(
                  builder: (context, calendarsProvider, child) {
                    final calendars = calendarsProvider.calendars;

                    if (calendars.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Calendar',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: ButtonTheme(
                              alignedDropdown: true,
                              child: DropdownButton<String>(
                                value: _selectedCalendarId ?? calendars.first.id,
                                isExpanded: true,
                                borderRadius: BorderRadius.circular(12),
                                items: calendars.map((calendar) {
                                  return DropdownMenuItem<String>(
                                    value: calendar.id,
                                    child: Row(
                                      children: [
                                        Text(
                                          calendar.emoji,
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            calendar.name,
                                            style: const TextStyle(fontSize: 15),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (calendar.color != null) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            width: 16,
                                            height: 16,
                                            decoration: BoxDecoration(
                                              color: ColorMapper.parseColor(calendar.color!),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _selectedCalendarId = newValue;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                ),

                // Color selector
                const Text(
                  'Color',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _colorOptions.map((color) {
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = color),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _parseColor(color),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _selectedColor == color
                                ? Colors.black
                                : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: _selectedColor == color
                              ? [
                                  BoxShadow(
                                    color: _parseColor(color).withOpacity(0.4),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),

                // Save button
                ElevatedButton(
                  onPressed: _saveEvent,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.blue[600],
                  ),
                  child: Text(
                    isEditing ? 'Update Event' : 'Create Event',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),

                // Delete button (only in edit mode)
                if (isEditing) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _deleteEvent,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Delete Event',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateButton(String label, DateTime date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(date),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final allEmojis = [
          // Activities
          '📅', '🎉', '🎊', '🎈', '🎁', '🎯', '🎪', '🎭', '🎨', '🎬',
          // Work & Study
          '💼', '📊', '📈', '📝', '📚', '📖', '✏️', '📌', '📍', '🔖',
          // Sports & Fitness
          '🏃', '🚴', '🏋️', '⚽', '🏀', '🎾', '🏊', '🧘', '🤸', '⛹️',
          // Food & Drink
          '🍽️', '🍕', '🍔', '🍜', '🍱', '🍰', '☕', '🍷', '🥗', '🍿',
          // Travel
          '✈️', '🚗', '🚆', '🚢', '🗺️', '🏖️', '🏔️', '🏕️', '🗼', '🎒',
          // Home & Life
          '🏠', '🛋️', '🛏️', '🚿', '🧹', '🧺', '🔧', '🔨', '🪴', '🕯️',
          // Health & Medical
          '💊', '🩺', '💉', '🏥', '😷', '🧘', '💆', '💇', '🧖', '🦷',
          // Tech
          '💻', '📱', '⌚', '🖥️', '⌨️', '🖱️', '💾', '📷', '🎥', '📡',
          // Nature
          '🌳', '🌲', '🌴', '🌱', '🌿', '🌸', '🌺', '🌻', '🌹', '🌷',
          // Animals
          '🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼', '🐨', '🐯',
          // Weather
          '☀️', '🌤️', '⛅', '🌥️', '☁️', '🌦️', '🌧️', '⛈️', '🌩️', '❄️',
          // Misc
          '⭐', '✨', '💫', '🔥', '💧', '⚡', '🌈', '☂️', '🎓', '👑',
        ];

        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Select Emoji',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 300,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                    childAspectRatio: 1,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: allEmojis.length,
                  itemBuilder: (context, index) {
                    final emoji = allEmojis[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedEmoji = emoji);
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: _selectedEmoji == emoji
                              ? Colors.blue[100]
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _selectedEmoji == emoji
                                ? Colors.blue
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceAll('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }

  Future<void> _deleteEvent() async {
    if (widget.event?.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final eventsProvider = Provider.of<EventsProvider>(context, listen: false);
      await eventsProvider.deleteEvent(widget.event!.id!);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}
