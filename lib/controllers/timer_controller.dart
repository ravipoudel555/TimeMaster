import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/timer_model.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/background_service.dart';

/// Controller for managing countdown timers
class TimerController extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final NotificationService _notificationService = NotificationService();
  final BackgroundService _backgroundService = BackgroundService();

  List<TimerModel> _timers = [];
  Timer? _updateTimer;
  final Map<String, DateTime> _startTimes = {};

  List<TimerModel> get timers => List.unmodifiable(_timers);

  /// Load timers from storage
  Future<void> loadTimers() async {
    _timers = await _storage.loadTimers();
    _restoreRunningTimers();
    notifyListeners();
  }

  /// Restore running timers state
  void _restoreRunningTimers() {
    for (var timer in _timers) {
      if (timer.status == TimerStatus.running) {
        // Calculate remaining time based on elapsed time
        final now = DateTime.now();
        DateTime? effectiveStartTime;

        if (timer.pausedAt != null && timer.pausedDuration != null) {
          final pausedDuration = now.difference(timer.pausedAt!);
          final totalPaused = timer.pausedDuration! + pausedDuration;
          effectiveStartTime = timer.createdAt.add(totalPaused);
        } else {
          effectiveStartTime = timer.createdAt;
        }

        final elapsed = now.difference(effectiveStartTime);
        final remaining = timer.duration - elapsed;

        if (remaining.inSeconds <= 0) {
          timer.status = TimerStatus.finished;
          timer.remainingTime = Duration.zero;
        } else {
          timer.remainingTime = remaining;
          _startTimes[timer.id] = effectiveStartTime;
        }
      }
    }
    _startUpdateTimer();
  }

  /// Start update timer for UI updates
  void _startUpdateTimer() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      bool updated = false;
      for (var timerModel in _timers) {
        if (timerModel.status == TimerStatus.running) {
          final now = DateTime.now();
          final startTime = _startTimes[timerModel.id] ?? timerModel.createdAt;
          final elapsed = now.difference(startTime);
          final remaining = timerModel.duration - elapsed;

          if (remaining.inSeconds <= 0) {
            timerModel.status = TimerStatus.finished;
            timerModel.remainingTime = Duration.zero;
            _notificationService.showTimerFinishedNotification(
              id: timerModel.id.hashCode,
              title: 'Timer Finished',
              body: '${timerModel.name} has finished!',
            );
            _startTimes.remove(timerModel.id);
            updated = true;
          } else {
            timerModel.remainingTime = remaining;
            updated = true;
          }
        }
      }
      if (updated) {
        notifyListeners();
        _saveTimers();
      }
    });
  }

  /// Create a new timer
  Future<void> createTimer({
    required String name,
    required Duration duration,
  }) async {
    final timer = TimerModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      duration: duration,
      remainingTime: duration,
      status: TimerStatus.stopped,
      createdAt: DateTime.now(),
    );

    _timers.add(timer);
    notifyListeners();
    await _saveTimers();
  }

  /// Start a timer
  Future<void> startTimer(String id) async {
    final timerIndex = _timers.indexWhere((t) => t.id == id);
    if (timerIndex == -1) return;

    final timer = _timers[timerIndex];
    final now = DateTime.now();

    DateTime startTime;
    if (timer.status == TimerStatus.paused && timer.pausedAt != null && timer.pausedDuration != null) {
      // Resume from pause - calculate effective start time
      final pausedDuration = now.difference(timer.pausedAt!);
      final totalPaused = timer.pausedDuration! + pausedDuration;
      startTime = timer.createdAt.add(totalPaused);
    } else {
      // Start fresh
      startTime = now;
    }

    _timers[timerIndex] = timer.copyWith(
      status: TimerStatus.running,
      pausedAt: null,
      pausedDuration: null,
    );

    _startTimes[id] = startTime;
    _startUpdateTimer();
    notifyListeners();
    await _saveTimers();
    
    // Schedule notification for when timer finishes
    final notificationService = NotificationService();
    final finishTime = DateTime.now().add(timer.remainingTime);
    await notificationService.scheduleAlarmNotification(
      id: timer.id.hashCode,
      title: 'Timer Finished',
      body: '${timer.name} has finished!',
      scheduledDate: finishTime,
    );
    
    await _backgroundService.startBackgroundTask();
  }

  /// Pause a timer
  Future<void> pauseTimer(String id) async {
    final timerIndex = _timers.indexWhere((t) => t.id == id);
    if (timerIndex == -1) return;

    final timer = _timers[timerIndex];
    if (timer.status != TimerStatus.running) return;

    final now = DateTime.now();
    final startTime = _startTimes[id] ?? timer.createdAt;
    final elapsed = now.difference(startTime);
    final previousPaused = timer.pausedDuration ?? Duration.zero;

    _timers[timerIndex] = timer.copyWith(
      status: TimerStatus.paused,
      pausedAt: now,
      pausedDuration: previousPaused + elapsed,
    );

    // Cancel scheduled notification
    await _notificationService.cancelNotification(id.hashCode);

    _startTimes.remove(id);
    notifyListeners();
    await _saveTimers();
  }

  /// Reset a timer
  Future<void> resetTimer(String id) async {
    final timerIndex = _timers.indexWhere((t) => t.id == id);
    if (timerIndex == -1) return;

    final timer = _timers[timerIndex];
    _timers[timerIndex] = timer.copyWith(
      status: TimerStatus.stopped,
      remainingTime: timer.duration,
      pausedAt: null,
      pausedDuration: null,
    );

    _startTimes.remove(id);
    notifyListeners();
    await _saveTimers();
  }

  /// Cancel/Delete a timer
  Future<void> cancelTimer(String id) async {
    _timers.removeWhere((t) => t.id == id);
    _startTimes.remove(id);
    await _notificationService.cancelNotification(id.hashCode);
    notifyListeners();
    await _saveTimers();
  }

  /// Save timers to storage
  Future<void> _saveTimers() async {
    await _storage.saveTimers(_timers);
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }
}

