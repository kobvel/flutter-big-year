import 'package:flutter/foundation.dart';
import '../models/calendar_model.dart';
import '../services/firebase_service.dart';

class CalendarsProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  List<CalendarModel> _calendars = [];
  bool _isLoading = false;

  List<CalendarModel> get calendars => _calendars;
  bool get isLoading => _isLoading;

  void listenToCalendars() {
    _isLoading = true;
    notifyListeners();

    _firebaseService.getCalendarsStream().listen((calendars) {
      // Sort calendars by order
      _calendars = calendars..sort((a, b) => a.order.compareTo(b.order));
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<String> createCalendar(CalendarModel calendar) async {
    return await _firebaseService.createCalendar(calendar);
  }

  Future<void> updateCalendar(String calendarId, CalendarModel calendar) async {
    await _firebaseService.updateCalendar(calendarId, calendar);
  }

  Future<void> deleteCalendar(String calendarId) async {
    await _firebaseService.deleteCalendar(calendarId);
  }

  Future<void> reorderCalendars(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    // Reorder locally first for immediate feedback
    final calendar = _calendars.removeAt(oldIndex);
    _calendars.insert(newIndex, calendar);

    // Update order values for all calendars
    for (int i = 0; i < _calendars.length; i++) {
      final updatedCalendar = _calendars[i].copyWith(order: i);
      _calendars[i] = updatedCalendar;
      // Update in Firestore
      if (updatedCalendar.id != null) {
        await _firebaseService.updateCalendar(updatedCalendar.id!, updatedCalendar);
      }
    }

    notifyListeners();
  }

  CalendarModel? getCalendarById(String id) {
    try {
      return _calendars.firstWhere((calendar) => calendar.id == id);
    } catch (e) {
      return null;
    }
  }
}
