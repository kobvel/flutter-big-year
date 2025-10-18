import 'package:cloud_firestore/cloud_firestore.dart';

class DateProps {
  final int date;
  final int month;
  final int year;

  DateProps({
    required this.date,
    required this.month,
    required this.year,
  });

  factory DateProps.fromMap(Map<String, dynamic> map) {
    return DateProps(
      date: map['date'] ?? 0,
      month: map['month'] ?? 0,
      year: map['year'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'month': month,
      'year': year,
    };
  }

  DateTime toDateTime() {
    return DateTime(year, month + 1, date);
  }

  static DateProps fromDateTime(DateTime dateTime) {
    return DateProps(
      date: dateTime.day,
      month: dateTime.month - 1, // Convert to 0-based month
      year: dateTime.year,
    );
  }

  String toISOString() {
    final monthStr = (month + 1).toString().padLeft(2, '0');
    final dateStr = date.toString().padLeft(2, '0');
    return '$year-$monthStr-$dateStr';
  }
}

class TodoItem {
  final String? id;
  final String text;
  final bool completed;
  final String? assigneeId;
  final DateTime? dueDate;

  TodoItem({
    this.id,
    required this.text,
    required this.completed,
    this.assigneeId,
    this.dueDate,
  });

  factory TodoItem.fromMap(Map<String, dynamic> map, String? id) {
    return TodoItem(
      id: id,
      text: map['text'] ?? '',
      completed: map['completed'] ?? false,
      assigneeId: map['assigneeId'],
      dueDate: map['dueDate'] != null
          ? (map['dueDate'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'completed': completed,
      if (assigneeId != null) 'assigneeId': assigneeId,
      if (dueDate != null) 'dueDate': Timestamp.fromDate(dueDate!),
    };
  }
}

class EventModel {
  final String? id;
  final String userId;
  final String title;
  final String calendarId;
  final String emoji;
  final bool shared;
  final String categoryColor;
  final List<String> sharedWithUserIds;
  final List<String> sharedWithEmails;
  final DateProps dateStart;
  final DateProps dateEnd;
  final String? updatedAt;
  final List<TodoItem> todos;

  EventModel({
    this.id,
    required this.userId,
    required this.title,
    required this.calendarId,
    required this.emoji,
    required this.shared,
    required this.categoryColor,
    required this.sharedWithUserIds,
    required this.sharedWithEmails,
    required this.dateStart,
    required this.dateEnd,
    this.updatedAt,
    this.todos = const [],
  });

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel.fromMap(data, doc.id);
  }

  factory EventModel.fromMap(Map<String, dynamic> map, String? id) {
    return EventModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      calendarId: map['calendarId'] ?? 'general',
      emoji: map['emoji'] ?? '📅',
      shared: map['shared'] ?? false,
      categoryColor: map['categoryColor'] ?? '#3B82F6',
      sharedWithUserIds: List<String>.from(map['sharedWithUserIds'] ?? []),
      sharedWithEmails: List<String>.from(map['sharedWithEmails'] ?? []),
      dateStart: DateProps.fromMap(map['dateStart'] ?? {}),
      dateEnd: DateProps.fromMap(map['dateEnd'] ?? {}),
      updatedAt: map['updatedAt'],
      todos: (map['todos'] as List<dynamic>?)
              ?.map((todo) => TodoItem.fromMap(todo, null))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'calendarId': calendarId,
      'emoji': emoji,
      'shared': shared,
      'categoryColor': categoryColor,
      'sharedWithUserIds': sharedWithUserIds,
      'sharedWithEmails': sharedWithEmails,
      'dateStart': dateStart.toMap(),
      'dateEnd': dateEnd.toMap(),
      if (updatedAt != null) 'updatedAt': updatedAt,
      'todos': todos.map((todo) => todo.toMap()).toList(),
    };
  }

  bool isMultiDay() {
    return dateStart.toISOString() != dateEnd.toISOString();
  }

  List<DateTime> getDateRange() {
    final start = dateStart.toDateTime();
    final end = dateEnd.toDateTime();
    final dates = <DateTime>[];

    DateTime current = start;
    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      dates.add(current);
      current = current.add(const Duration(days: 1));
    }

    return dates;
  }

  EventModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? calendarId,
    String? emoji,
    bool? shared,
    String? categoryColor,
    List<String>? sharedWithUserIds,
    List<String>? sharedWithEmails,
    DateProps? dateStart,
    DateProps? dateEnd,
    String? updatedAt,
    List<TodoItem>? todos,
  }) {
    return EventModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      calendarId: calendarId ?? this.calendarId,
      emoji: emoji ?? this.emoji,
      shared: shared ?? this.shared,
      categoryColor: categoryColor ?? this.categoryColor,
      sharedWithUserIds: sharedWithUserIds ?? this.sharedWithUserIds,
      sharedWithEmails: sharedWithEmails ?? this.sharedWithEmails,
      dateStart: dateStart ?? this.dateStart,
      dateEnd: dateEnd ?? this.dateEnd,
      updatedAt: updatedAt ?? this.updatedAt,
      todos: todos ?? this.todos,
    );
  }
}
