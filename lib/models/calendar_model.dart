import 'package:cloud_firestore/cloud_firestore.dart';

class CalendarModel {
  final String? id;
  final String ownerId;
  final String name;
  final String emoji;
  final String? color;
  final DateTime? createdAt;

  CalendarModel({
    this.id,
    required this.ownerId,
    required this.name,
    required this.emoji,
    this.color,
    this.createdAt,
  });

  factory CalendarModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CalendarModel.fromMap(data, doc.id);
  }

  factory CalendarModel.fromMap(Map<String, dynamic> map, String? id) {
    return CalendarModel(
      id: id,
      ownerId: map['ownerId'] ?? '',
      name: map['name'] ?? '',
      emoji: map['emoji'] ?? '📅',
      color: map['color'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'name': name,
      'emoji': emoji,
      if (color != null) 'color': color,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  CalendarModel copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? emoji,
    String? color,
    DateTime? createdAt,
  }) {
    return CalendarModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
