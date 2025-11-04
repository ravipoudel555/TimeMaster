import 'dart:async';
import 'notification_service.dart';
import 'storage_service.dart';
import '../models/timer_model.dart';

/// Service for background task management
/// Uses scheduled notifications for timers and alarms
class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  static Timer? _updateTimer;

  /// Initialize background service
  Future<void> initialize() async {
    // No initialization needed - using scheduled notifications
  }

  /// Start background task
  /// For timers, we schedule notifications when they start
  /// The foreground timer handles updates when app is open
  Future<void> startBackgroundTask() async {
    // Start foreground timer for immediate updates when app is open
    _startUpdateTimer();
    
    // Schedule notifications for all running timers
    await _scheduleTimerNotifications();
  }

  /// Schedule notifications for running timers
  Future<void> _scheduleTimerNotifications() async {
    final storage = StorageService();
    final notificationService = NotificationService();
    final timers = await storage.loadTimers();
    
    for (var timer in timers) {
      if (timer.status == TimerStatus.running && timer.remainingTime.inSeconds > 0) {
        final finishTime = DateTime.now().add(timer.remainingTime);
        await notificationService.scheduleAlarmNotification(
          id: timer.id.hashCode,
          title: 'Timer Finished',
          body: '${timer.name} has finished!',
          scheduledDate: finishTime,
        );
      }
    }
  }

  /// Start update timer for immediate updates
  void _startUpdateTimer() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTimers();
      _checkAlarms();
    });
  }

  /// Stop background task
  Future<void> stopBackgroundTask() async {
    _updateTimer?.cancel();
  }

  /// Update timers in background
  Future<void> _updateTimers() async {
    final storage = StorageService();
    final timers = await storage.loadTimers();
    final notificationService = NotificationService();
    bool updated = false;

    final updatedTimers = <TimerModel>[];
    for (var timer in timers) {
      if (timer.status == TimerStatus.running) {
        final now = DateTime.now();
        DateTime startTime;
        
        // Calculate start time based on paused duration
        if (timer.pausedAt != null && timer.pausedDuration != null) {
          final pausedDuration = now.difference(timer.pausedAt!);
          final totalPaused = timer.pausedDuration! + pausedDuration;
          startTime = timer.createdAt.add(totalPaused);
        } else {
          startTime = timer.createdAt;
        }
        
        final elapsed = now.difference(startTime);
        final newRemaining = timer.duration - elapsed;
        
        if (newRemaining.inSeconds <= 0) {
          updatedTimers.add(timer.copyWith(
            remainingTime: Duration.zero,
            status: TimerStatus.finished,
          ));
          await notificationService.showTimerFinishedNotification(
            id: timer.id.hashCode,
            title: 'Timer Finished',
            body: '${timer.name} has finished!',
          );
          updated = true;
        } else {
          updatedTimers.add(timer.copyWith(remainingTime: newRemaining));
          updated = true;
        }
      } else {
        updatedTimers.add(timer);
      }
    }

    if (updated) {
      await storage.saveTimers(updatedTimers);
    }
  }

  /// Check alarms in background
  Future<void> _checkAlarms() async {
    final storage = StorageService();
    final alarms = await storage.loadAlarms();
    final now = DateTime.now();

    for (var alarm in alarms) {
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
          // Trigger alarm notification
          final notificationService = NotificationService();
          await notificationService.showTimerFinishedNotification(
            id: alarm.id.hashCode,
            title: 'Alarm',
            body: alarm.name,
          );
        }
      }
    }
  }
}


