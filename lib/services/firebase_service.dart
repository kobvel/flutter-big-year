import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event_model.dart';
import '../models/calendar_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Events
  Stream<List<EventModel>> getEventsStream() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('events')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList());
  }

  Future<void> createEvent(EventModel event) async {
    await _firestore.collection('events').add(event.toMap());
  }

  Future<void> updateEvent(String eventId, EventModel event) async {
    await _firestore.collection('events').doc(eventId).update(event.toMap());
  }

  Future<void> deleteEvent(String eventId) async {
    await _firestore.collection('events').doc(eventId).delete();
  }

  // Calendars
  Stream<List<CalendarModel>> getCalendarsStream() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('calendars')
        .where('ownerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CalendarModel.fromFirestore(doc))
            .toList());
  }

  Future<void> createCalendar(CalendarModel calendar) async {
    await _firestore.collection('calendars').add(calendar.toMap());
  }

  Future<void> updateCalendar(String calendarId, CalendarModel calendar) async {
    await _firestore
        .collection('calendars')
        .doc(calendarId)
        .update(calendar.toMap());
  }

  Future<void> deleteCalendar(String calendarId) async {
    await _firestore.collection('calendars').doc(calendarId).delete();
  }
}
