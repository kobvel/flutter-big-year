import 'package:flutter/foundation.dart';
import '../models/event_model.dart';
import '../services/firebase_service.dart';

class EventsProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  List<EventModel> _events = [];
  List<String>? _selectedCalendarIds; // null means show all (initial state)
  bool _isLoading = false;

  List<EventModel> get events => _events;
  List<String> get selectedCalendarIds => _selectedCalendarIds ?? [];
  bool get isLoading => _isLoading;

  // Get filtered events based on selected calendars
  List<EventModel> get filteredEvents {
    // null or empty means different things:
    // null = not initialized, show all
    // empty list = explicitly hide all
    if (_selectedCalendarIds == null) return _events;
    if (_selectedCalendarIds!.isEmpty) return [];

    return _events
        .where((event) => _selectedCalendarIds!.contains(event.calendarId))
        .toList();
  }

  // Get events for a specific date
  List<EventModel> getEventsForDate(DateTime date) {
    final dateString = _dateToString(date);
    return filteredEvents.where((event) {
      final eventDates = event.getDateRange();
      return eventDates.any((d) => _dateToString(d) == dateString);
    }).toList();
  }

  String _dateToString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void listenToEvents() {
    _isLoading = true;
    notifyListeners();

    _firebaseService.getEventsStream().listen((events) {
      _events = events;
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<String> createEvent(EventModel event) async {
    final eventId = await _firebaseService.createEvent(event);
    return eventId;
  }

  Future<void> updateEvent(String eventId, EventModel event) async {
    await _firebaseService.updateEvent(eventId, event);
  }

  Future<void> deleteEvent(String eventId) async {
    await _firebaseService.deleteEvent(eventId);
  }

  void toggleCalendarSelection(String calendarId) {
    if (_selectedCalendarIds?.contains(calendarId) ?? false) {
      _selectedCalendarIds?.remove(calendarId);
    } else {
      _selectedCalendarIds?.add(calendarId);
    }
    notifyListeners();
  }

  void setSelectedCalendars(List<String> calendarIds) {
    _selectedCalendarIds = calendarIds;
    notifyListeners();
  }

  void initializeCalendarSelection(List<String> allCalendarIds) {
    if (_selectedCalendarIds == null) {
      _selectedCalendarIds = allCalendarIds;
      notifyListeners();
    }
  }

  // Clean up deleted calendar IDs from selection
  void cleanupDeletedCalendars(List<String> validCalendarIds) {
    if (_selectedCalendarIds == null) return;

    final validSet = validCalendarIds.toSet();
    final before = _selectedCalendarIds!.length;
    _selectedCalendarIds = _selectedCalendarIds!.where((id) => validSet.contains(id)).toList();
    final after = _selectedCalendarIds!.length;

    // Only notify if something changed
    if (before != after) {
      notifyListeners();
    }
  }

  bool get isInitialized => _selectedCalendarIds != null;

  // Ensure a calendar is selected (for auto-selecting after event creation)
  void ensureCalendarSelected(String calendarId) {
    if (_selectedCalendarIds == null) {
      _selectedCalendarIds = [calendarId];
      notifyListeners();
    } else if (!_selectedCalendarIds!.contains(calendarId)) {
      _selectedCalendarIds!.add(calendarId);
      notifyListeners();
    }
  }
}
