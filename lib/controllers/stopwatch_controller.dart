import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/stopwatch_model.dart';
import '../services/storage_service.dart';
import 'package:uuid/uuid.dart';

/// Controller for managing stopwatches
class StopwatchController extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final Uuid _uuid = const Uuid();

  List<StopwatchModel> _stopwatches = [];
  final Map<String, Timer> _updateTimers = {};
  final Map<String, DateTime> _startTimes = {};
  final Map<String, Duration> _pausedDurations = {};

  List<StopwatchModel> get stopwatches => List.unmodifiable(_stopwatches);

  /// Load stopwatches from storage
  Future<void> loadStopwatches() async {
    _stopwatches = await _storage.loadStopwatches();
    _restoreRunningStopwatches();
    notifyListeners();
  }

  /// Restore running stopwatches state
  void _restoreRunningStopwatches() {
    for (var stopwatch in _stopwatches) {
      if (stopwatch.status == StopwatchStatus.running) {
        DateTime effectiveStartTime;

        if (stopwatch.pausedDuration != null) {
          effectiveStartTime = stopwatch.startTime?.subtract(stopwatch.pausedDuration!) ?? stopwatch.createdAt;
        } else {
          effectiveStartTime = stopwatch.startTime ?? stopwatch.createdAt;
        }

        _startTimes[stopwatch.id] = effectiveStartTime;
        _pausedDurations[stopwatch.id] = stopwatch.pausedDuration ?? Duration.zero;
        _startUpdateTimer(stopwatch.id);
      } else if (stopwatch.status == StopwatchStatus.paused) {
        _pausedDurations[stopwatch.id] = stopwatch.pausedDuration ?? Duration.zero;
      }
    }
  }

  /// Start update timer for a stopwatch
  void _startUpdateTimer(String id) {
    _updateTimers[id]?.cancel();
    _updateTimers[id] = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      final stopwatchIndex = _stopwatches.indexWhere((s) => s.id == id);
      if (stopwatchIndex == -1) {
        timer.cancel();
        return;
      }

      final stopwatch = _stopwatches[stopwatchIndex];
      if (stopwatch.status == StopwatchStatus.running) {
        final now = DateTime.now();
        final startTime = _startTimes[id] ?? stopwatch.createdAt;
        final elapsed = now.difference(startTime);
        final pausedDuration = _pausedDurations[id] ?? Duration.zero;
        final totalElapsed = elapsed - pausedDuration;

        _stopwatches[stopwatchIndex] = stopwatch.copyWith(
          elapsedTime: totalElapsed,
        );
        notifyListeners();
        _saveStopwatches();
      } else {
        timer.cancel();
        _updateTimers.remove(id);
      }
    });
  }

  /// Create a new stopwatch
  Future<void> createStopwatch({String? name}) async {
    final stopwatch = StopwatchModel(
      id: _uuid.v4(),
      name: name ?? 'Stopwatch ${_stopwatches.length + 1}',
      elapsedTime: Duration.zero,
      status: StopwatchStatus.stopped,
      createdAt: DateTime.now(),
    );

    _stopwatches.add(stopwatch);
    notifyListeners();
    await _saveStopwatches();
  }

  /// Start a stopwatch
  Future<void> startStopwatch(String id) async {
    final stopwatchIndex = _stopwatches.indexWhere((s) => s.id == id);
    if (stopwatchIndex == -1) return;

    final stopwatch = _stopwatches[stopwatchIndex];
    final now = DateTime.now();

    DateTime startTime;
    Duration pausedDuration = _pausedDurations[id] ?? Duration.zero;

    if (stopwatch.status == StopwatchStatus.paused) {
      // Resume from pause
      final previousPaused = stopwatch.pausedDuration ?? Duration.zero;
      pausedDuration = previousPaused;
      startTime = now.subtract(previousPaused);
    } else {
      // Start fresh
      startTime = now;
      pausedDuration = Duration.zero;
    }

    _stopwatches[stopwatchIndex] = stopwatch.copyWith(
      status: StopwatchStatus.running,
      startTime: startTime,
      pausedDuration: pausedDuration,
    );

    _startTimes[id] = startTime;
    _pausedDurations[id] = pausedDuration;
    _startUpdateTimer(id);
    notifyListeners();
    await _saveStopwatches();
  }

  /// Pause a stopwatch
  Future<void> pauseStopwatch(String id) async {
    final stopwatchIndex = _stopwatches.indexWhere((s) => s.id == id);
    if (stopwatchIndex == -1) return;

    final stopwatch = _stopwatches[stopwatchIndex];
    if (stopwatch.status != StopwatchStatus.running) return;

    final now = DateTime.now();
    final startTime = _startTimes[id] ?? stopwatch.createdAt;
    final elapsed = now.difference(startTime);
    final previousPaused = _pausedDurations[id] ?? Duration.zero;
    final totalPaused = previousPaused + elapsed;

    _stopwatches[stopwatchIndex] = stopwatch.copyWith(
      status: StopwatchStatus.paused,
      pausedDuration: totalPaused,
    );

    _pausedDurations[id] = totalPaused;
    _updateTimers[id]?.cancel();
    _updateTimers.remove(id);
    notifyListeners();
    await _saveStopwatches();
  }

  /// Reset a stopwatch
  Future<void> resetStopwatch(String id) async {
    final stopwatchIndex = _stopwatches.indexWhere((s) => s.id == id);
    if (stopwatchIndex == -1) return;

    final stopwatch = _stopwatches[stopwatchIndex];
    _stopwatches[stopwatchIndex] = stopwatch.copyWith(
      status: StopwatchStatus.stopped,
      elapsedTime: Duration.zero,
      laps: [],
      startTime: null,
      pausedDuration: null,
    );

    _startTimes.remove(id);
    _pausedDurations.remove(id);
    _updateTimers[id]?.cancel();
    _updateTimers.remove(id);
    notifyListeners();
    await _saveStopwatches();
  }

  /// Add a lap to a stopwatch
  Future<void> addLap(String id) async {
    final stopwatchIndex = _stopwatches.indexWhere((s) => s.id == id);
    if (stopwatchIndex == -1) return;

    final stopwatch = _stopwatches[stopwatchIndex];
    if (stopwatch.status != StopwatchStatus.running) return;

    final totalTime = stopwatch.elapsedTime;
    final previousLapTime = stopwatch.laps.isNotEmpty
        ? stopwatch.laps.last.totalTime
        : Duration.zero;
    final lapTime = totalTime - previousLapTime;

    final lap = LapModel(
      id: _uuid.v4(),
      lapTime: lapTime,
      totalTime: totalTime,
      createdAt: DateTime.now(),
    );

    final updatedLaps = [...stopwatch.laps, lap];
    _stopwatches[stopwatchIndex] = stopwatch.copyWith(laps: updatedLaps);
    notifyListeners();
    await _saveStopwatches();
  }

  /// Delete a stopwatch
  Future<void> deleteStopwatch(String id) async {
    _stopwatches.removeWhere((s) => s.id == id);
    _startTimes.remove(id);
    _pausedDurations.remove(id);
    _updateTimers[id]?.cancel();
    _updateTimers.remove(id);
    notifyListeners();
    await _saveStopwatches();
  }

  /// Save stopwatches to storage
  Future<void> _saveStopwatches() async {
    await _storage.saveStopwatches(_stopwatches);
  }

  @override
  void dispose() {
    for (var timer in _updateTimers.values) {
      timer.cancel();
    }
    _updateTimers.clear();
    super.dispose();
  }
}

