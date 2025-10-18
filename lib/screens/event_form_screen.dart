import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event_model.dart';
import '../providers/events_provider.dart';
import '../providers/auth_provider.dart';

class EventFormScreen extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final EventModel? event;

  const EventFormScreen({
    super.key,
    required this.startDate,
    required this.endDate,
    this.event,
  });

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late DateTime _selectedStartDate;
  late DateTime _selectedEndDate;
  String _selectedEmoji = '📅';
  String _selectedColor = '#3B82F6';
  String _selectedCalendarId = 'general';

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
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final eventsProvider = Provider.of<EventsProvider>(context, listen: false);

    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to create events')),
      );
      return;
    }

    final event = EventModel(
      id: widget.event?.id,
      userId: authProvider.user!.uid,
      title: _titleController.text.trim(),
      calendarId: _selectedCalendarId,
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
        await eventsProvider.createEvent(event);
      } else {
        await eventsProvider.updateEvent(widget.event!.id!, event);
      }
      if (mounted) {
        Navigator.of(context).pop();
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

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Event' : 'New Event'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteEvent,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Emoji selector
            Row(
              children: [
                const Text('Emoji:', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 16),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    children: _emojiOptions.map((emoji) {
                      return GestureDetector(
                        onTap: () => setState(() => _selectedEmoji = emoji),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _selectedEmoji == emoji
                                  ? Colors.blue
                                  : Colors.grey[300]!,
                              width: _selectedEmoji == emoji ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(emoji, style: const TextStyle(fontSize: 24)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Title input
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Date range
            Row(
              children: [
                Expanded(
                  child: _buildDateButton(
                    'Start Date',
                    _selectedStartDate,
                    () => _selectDate(true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDateButton(
                    'End Date',
                    _selectedEndDate,
                    () => _selectDate(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Color selector
            const Text('Color:', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _colorOptions.map((color) {
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _parseColor(color),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _selectedColor == color
                            ? Colors.black
                            : Colors.transparent,
                        width: 3,
                      ),
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
              ),
              child: Text(
                isEditing ? 'Update Event' : 'Create Event',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateButton(String label, DateTime date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
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
              '${date.day}/${date.month}/${date.year}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
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
