import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/calendar_model.dart';
import '../providers/calendars_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/events_provider.dart';
import '../utils/color_mapper.dart';

class CalendarFormBottomSheet extends StatefulWidget {
  final CalendarModel? calendar; // null = create new, non-null = edit

  const CalendarFormBottomSheet({
    super.key,
    this.calendar,
  });

  @override
  State<CalendarFormBottomSheet> createState() => _CalendarFormBottomSheetState();
}

class _CalendarFormBottomSheetState extends State<CalendarFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late String _selectedEmoji;
  late String _selectedColor;

  final List<String> _emojiOptions = [
    '📅', '💼', '🏃', '🎯', '📚', '🎨', '🍽️', '✈️', '🏠', '💪',
    '🎉', '💰', '🎬', '🎮', '🎵', '📱', '🌟', '❤️', '🌈', '⚡',
  ];

  // Horizon App color palette
  final Map<String, String> _colorOptions = {
    'Cerulean': '#6f97b8',
    'Grape': '#806d8c',
    'Turquoise': '#83b7b8',
    'Green': '#90a583',
    'Wildfire': '#d4a373',
    'Rose': '#c8a5b3',
    'Brick': '#a39088',
    'Chrome': '#d5d5d5',
    'Orange': '#deb168',
    'Coral': '#bc8a8d',
    'Slate': '#8994a1',
    'Stone': '#a8a196',
  };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.calendar?.name ?? '');
    _selectedEmoji = widget.calendar?.emoji ?? '📅';
    _selectedColor = widget.calendar?.color ?? '#6f97b8';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveCalendar() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final calendarsProvider = Provider.of<CalendarsProvider>(context, listen: false);
    final eventsProvider = Provider.of<EventsProvider>(context, listen: false);

    if (authProvider.user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to manage calendars')),
        );
      }
      return;
    }

    final calendar = CalendarModel(
      id: widget.calendar?.id,
      ownerId: authProvider.user!.uid,
      name: _nameController.text.trim(),
      emoji: _selectedEmoji,
      color: _selectedColor,
      createdAt: widget.calendar?.createdAt ?? DateTime.now(),
    );

    try {
      String? newCalendarId;
      if (widget.calendar == null) {
        // Creating new calendar
        newCalendarId = await calendarsProvider.createCalendar(calendar);

        // Auto-select the newly created calendar
        if (mounted) {
          eventsProvider.toggleCalendarSelection(newCalendarId);

          // Show success message with calendar emoji
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Text(_selectedEmoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Calendar "${_nameController.text.trim()}" created!'),
                  ),
                ],
              ),
              backgroundColor: Colors.green[600],
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Updating existing calendar
        await calendarsProvider.updateCalendar(widget.calendar!.id!, calendar);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Calendar updated'),
              backgroundColor: Colors.blue[600],
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }

      if (mounted) {
        // Return the new calendar ID so parent can scroll to it
        Navigator.of(context).pop(newCalendarId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving calendar: $e')),
        );
      }
    }
  }

  Future<void> _deleteCalendar() async {
    if (widget.calendar?.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Calendar'),
        content: Text(
          'Are you sure you want to delete "${widget.calendar!.name}"?\n\nThis will not delete events, but they will become unassigned.',
        ),
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
      final calendarsProvider = Provider.of<CalendarsProvider>(context, listen: false);
      await calendarsProvider.deleteCalendar(widget.calendar!.id!);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.calendar != null;

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
        initialChildSize: 0.75,
        minChildSize: 0.4,
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
                    isEditing ? 'Edit Calendar' : 'New Calendar',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Emoji and Name
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
                      // Name field
                      Expanded(
                        child: TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Calendar Name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a name';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Color selector
                  const Text(
                    'Color',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _colorOptions.entries.map((entry) {
                      final colorName = entry.key;
                      final colorHex = entry.value;
                      final isSelected = _selectedColor == colorHex;

                      return GestureDetector(
                        onTap: () => setState(() => _selectedColor = colorHex),
                        child: Column(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: ColorMapper.parseColor(colorHex),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? Colors.black : Colors.grey[300]!,
                                  width: isSelected ? 3 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: ColorMapper.parseColor(colorHex).withOpacity(0.4),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: isSelected
                                  ? Icon(Icons.check, color: Colors.white, size: 20)
                                  : null,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              colorName,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),

                  // Save button
                  ElevatedButton(
                    onPressed: _saveCalendar,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.blue[600],
                    ),
                    child: Text(
                      isEditing ? 'Update Calendar' : 'Create Calendar',
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
                      onPressed: _deleteCalendar,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Delete Calendar',
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

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
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
                height: 200,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    childAspectRatio: 1,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _emojiOptions.length,
                  itemBuilder: (context, index) {
                    final emoji = _emojiOptions[index];
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
                            style: const TextStyle(fontSize: 32),
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
}
