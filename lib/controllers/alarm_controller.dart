import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/alarm_model.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

/// Controller for managing alarms
class AlarmController extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final NotificationService _notificationService = NotificationService();

  List<AlarmModel> _alarms = [];
  Timer? _checkTimer;

  List<AlarmModel> get alarms => List.unmodifiable(_alarms);

  /// Load alarms from storage
  Future<void> loadAlarms() async {
    _alarms = await _storage.loadAlarms();
    _scheduleAllAlarms();
    _startAlarmChecker();
    notifyListeners();
  }

  /// Start alarm checker timer
  void _startAlarmChecker() {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkAlarms();
    });
  }

  /// Check if any alarms should trigger
  Future<void> _checkAlarms() async {
    final now = DateTime.now();

    for (var alarm in _alarms) {
      if (alarm.isActive && alarm.shouldTriggerToday()) {
        final alarmTime = DateTime(
          now.year,
          now.month,
          now.day,
          alarm.time.hour,
          alarm.time.minute,
        );

        // Check if alarm should trigger (within 1 minute window)
        if (now.difference(alarmTime).inSeconds.abs() < 60) {
          // Trigger alarm
          await _notificationService.showTimerFinishedNotification(
            id: alarm.id.hashCode,
            title: 'Alarm',
            body: alarm.name,
          );
        }
      }
    }
  }

  /// Schedule all alarms
  Future<void> _scheduleAllAlarms() async {
    for (var alarm in _alarms) {
      if (alarm.isActive) {
        final nextTrigger = alarm.getNextTriggerTime();
        if (nextTrigger != null) {
          await _notificationService.scheduleAlarmNotification(
            id: alarm.id.hashCode,
            title: 'Alarm',
            body: alarm.name,
            scheduledDate: nextTrigger,
          );
        }
      }
    }
  }

  /// Create a new alarm
  Future<void> createAlarm({
    required String name,
    required TimeOfDay time,
    Set<int> repeatDays = const {},
    bool vibrate = true,
    String? soundPath,
  }) async {
    final alarm = AlarmModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      time: time,
      repeatDays: repeatDays,
      isActive: true,
      vibrate: vibrate,
      soundPath: soundPath,
      createdAt: DateTime.now(),
    );

    _alarms.add(alarm);
    if (alarm.isActive) {
      final nextTrigger = alarm.getNextTriggerTime();
      if (nextTrigger != null) {
        await _notificationService.scheduleAlarmNotification(
          id: alarm.id.hashCode,
          title: 'Alarm',
          body: alarm.name,
          scheduledDate: nextTrigger,
        );
      }
    }
    notifyListeners();
    await _saveAlarms();
  }

  /// Update an alarm
  Future<void> updateAlarm({
    required String id,
    String? name,
    TimeOfDay? time,
    Set<int>? repeatDays,
    bool? isActive,
    bool? vibrate,
    String? soundPath,
  }) async {
    final alarmIndex = _alarms.indexWhere((a) => a.id == id);
    if (alarmIndex == -1) return;

    final alarm = _alarms[alarmIndex];
    
    // Cancel existing notification
    await _notificationService.cancelNotification(id.hashCode);

    _alarms[alarmIndex] = alarm.copyWith(
      name: name,
      time: time,
      repeatDays: repeatDays,
      isActive: isActive,
      vibrate: vibrate,
      soundPath: soundPath,
    );

    // Schedule new notification if active
    if (_alarms[alarmIndex].isActive) {
      final nextTrigger = _alarms[alarmIndex].getNextTriggerTime();
      if (nextTrigger != null) {
        await _notificationService.scheduleAlarmNotification(
          id: id.hashCode,
          title: 'Alarm',
          body: _alarms[alarmIndex].name,
          scheduledDate: nextTrigger,
        );
      }
    }

    notifyListeners();
    await _saveAlarms();
  }

  /// Toggle alarm active state
  Future<void> toggleAlarm(String id) async {
    final alarmIndex = _alarms.indexWhere((a) => a.id == id);
    if (alarmIndex == -1) return;

    final alarm = _alarms[alarmIndex];
    final newActiveState = !alarm.isActive;

    if (!newActiveState) {
      // Cancel notification when deactivating
      await _notificationService.cancelNotification(id.hashCode);
    }

    _alarms[alarmIndex] = alarm.copyWith(isActive: newActiveState);

    if (newActiveState) {
      // Schedule notification when activating
      final nextTrigger = _alarms[alarmIndex].getNextTriggerTime();
      if (nextTrigger != null) {
        await _notificationService.scheduleAlarmNotification(
          id: id.hashCode,
          title: 'Alarm',
          body: _alarms[alarmIndex].name,
          scheduledDate: nextTrigger,
        );
      }
    }

    notifyListeners();
    await _saveAlarms();
  }

  /// Delete an alarm
  Future<void> deleteAlarm(String id) async {
    _alarms.removeWhere((a) => a.id == id);
    await _notificationService.cancelNotification(id.hashCode);
    notifyListeners();
    await _saveAlarms();
  }

  /// Save alarms to storage
  Future<void> _saveAlarms() async {
    await _storage.saveAlarms(_alarms);
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }
}

