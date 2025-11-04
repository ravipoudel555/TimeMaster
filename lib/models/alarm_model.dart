import 'package:flutter/material.dart';

/// Model class for alarm
class AlarmModel {
  final String id;
  final String name;
  final TimeOfDay time;
  final Set<int> repeatDays; // 0 = Sunday, 1 = Monday, ..., 6 = Saturday
  bool isActive;
  final String? soundPath;
  final bool vibrate;
  final DateTime createdAt;

  AlarmModel({
    required this.id,
    required this.name,
    required this.time,
    this.repeatDays = const {},
    this.isActive = true,
    this.soundPath,
    this.vibrate = true,
    required this.createdAt,
  });

  /// Create alarm from JSON
  factory AlarmModel.fromJson(Map<String, dynamic> json) {
    return AlarmModel(
      id: json['id'] as String,
      name: json['name'] as String,
      time: TimeOfDay(
        hour: json['time']['hour'] as int,
        minute: json['time']['minute'] as int,
      ),
      repeatDays: (json['repeatDays'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toSet() ??
          {},
      isActive: json['isActive'] as bool? ?? true,
      soundPath: json['soundPath'] as String?,
      vibrate: json['vibrate'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Convert alarm to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'time': {
        'hour': time.hour,
        'minute': time.minute,
      },
      'repeatDays': repeatDays.toList(),
      'isActive': isActive,
      'soundPath': soundPath,
      'vibrate': vibrate,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create a copy with updated values
  AlarmModel copyWith({
    String? id,
    String? name,
    TimeOfDay? time,
    Set<int>? repeatDays,
    bool? isActive,
    String? soundPath,
    bool? vibrate,
    DateTime? createdAt,
  }) {
    return AlarmModel(
      id: id ?? this.id,
      name: name ?? this.name,
      time: time ?? this.time,
      repeatDays: repeatDays ?? this.repeatDays,
      isActive: isActive ?? this.isActive,
      soundPath: soundPath ?? this.soundPath,
      vibrate: vibrate ?? this.vibrate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Get formatted time string
  String get formattedTime {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  /// Get repeat days string
  String get repeatDaysString {
    if (repeatDays.isEmpty) {
      return 'Once';
    }
    if (repeatDays.length == 7) {
      return 'Every day';
    }
    const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final sortedDays = repeatDays.toList()..sort();
    return sortedDays.map((day) => dayNames[day]).join(', ');
  }

  /// Check if alarm should trigger today
  bool shouldTriggerToday() {
    if (!isActive) return false;
    if (repeatDays.isEmpty) {
      // Check if it's the same day
      final now = DateTime.now();
      final alarmDate = DateTime(
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );
      return alarmDate.isBefore(now) || alarmDate.isAtSameMomentAs(now);
    }
    // DateTime.weekday is 1-7 (Monday=1, Sunday=7)
    // Convert to 0-6 format (Sunday=0, Monday=1, ..., Saturday=6)
    final weekday = DateTime.now().weekday;
    final today = weekday == 7 ? 0 : weekday;
    return repeatDays.contains(today);
  }

  /// Get next trigger time
  DateTime? getNextTriggerTime() {
    if (!isActive) return null;

    final now = DateTime.now();
    final today = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (repeatDays.isEmpty) {
      // One-time alarm
      if (today.isBefore(now)) {
        // Already passed today, set for tomorrow
        return today.add(const Duration(days: 1));
      }
      return today;
    }

    // Repeating alarm
    // DateTime.weekday is 1-7 (Monday=1, Sunday=7)
    // Convert to 0-6 format (Sunday=0, Monday=1, ..., Saturday=6)
    final weekday = now.weekday;
    final currentWeekday = weekday == 7 ? 0 : weekday;

    // Find next day in repeatDays
    for (int i = 0; i < 7; i++) {
      final checkDay = (currentWeekday + i) % 7;
      if (repeatDays.contains(checkDay)) {
        final targetDate = DateTime(
          now.year,
          now.month,
          now.day,
          time.hour,
          time.minute,
        ).add(Duration(days: i));
        if (targetDate.isAfter(now) || (i == 0 && targetDate.isAtSameMomentAs(now))) {
          return targetDate;
        }
      }
    }

    // If no day found this week, get first day next week
    final firstDay = repeatDays.toList()..sort();
    int daysToAdd = (firstDay.first - currentWeekday + 7) % 7;
    if (daysToAdd == 0) daysToAdd = 7;

    return today.add(Duration(days: daysToAdd));
  }
}

