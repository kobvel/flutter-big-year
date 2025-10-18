import 'package:flutter/foundation.dart';
import '../models/event_model.dart';
import '../services/firebase_service.dart';

class EventsProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  List<EventModel> _events = [];
  List<String> _selectedCalendarIds = [];
  bool _isLoading = false;

  List<EventModel> get events => _events;
  List<String> get selectedCalendarIds => _selectedCalendarIds;
  bool get isLoading => _isLoading;

  // Get filtered events based on selected calendars
  List<EventModel> get filteredEvents {
    if (_selectedCalendarIds.isEmpty) return _events;
    return _events
        .where((event) => _selectedCalendarIds.contains(event.calendarId))
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

  Future<void> createEvent(EventModel event) async {
    await _firebaseService.createEvent(event);
  }

  Future<void> updateEvent(String eventId, EventModel event) async {
    await _firebaseService.updateEvent(eventId, event);
  }

  Future<void> deleteEvent(String eventId) async {
    await _firebaseService.deleteEvent(eventId);
  }

  void toggleCalendarSelection(String calendarId) {
    if (_selectedCalendarIds.contains(calendarId)) {
      _selectedCalendarIds.remove(calendarId);
    } else {
      _selectedCalendarIds.add(calendarId);
    }
    notifyListeners();
  }

  void setSelectedCalendars(List<String> calendarIds) {
    _selectedCalendarIds = calendarIds;
    notifyListeners();
  }
}
