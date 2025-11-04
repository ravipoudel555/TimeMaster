import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/timer_model.dart';
import '../models/alarm_model.dart';
import '../models/stopwatch_model.dart';

/// Service for persistent storage
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String _timersKey = 'timers';
  static const String _alarmsKey = 'alarms';
  static const String _stopwatchesKey = 'stopwatches';
  static const String _themeKey = 'theme_mode';

  /// Load all timers from storage
  Future<List<TimerModel>> loadTimers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timersJson = prefs.getString(_timersKey);
      if (timersJson == null) return [];

      final List<dynamic> timersList = json.decode(timersJson);
      return timersList
          .map((json) => TimerModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Save all timers to storage
  Future<void> saveTimers(List<TimerModel> timers) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timersJson = json.encode(
        timers.map((timer) => timer.toJson()).toList(),
      );
      await prefs.setString(_timersKey, timersJson);
    } catch (e) {
      // Handle error
    }
  }

  /// Load all alarms from storage
  Future<List<AlarmModel>> loadAlarms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alarmsJson = prefs.getString(_alarmsKey);
      if (alarmsJson == null) return [];

      final List<dynamic> alarmsList = json.decode(alarmsJson);
      return alarmsList
          .map((json) => AlarmModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Save all alarms to storage
  Future<void> saveAlarms(List<AlarmModel> alarms) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alarmsJson = json.encode(
        alarms.map((alarm) => alarm.toJson()).toList(),
      );
      await prefs.setString(_alarmsKey, alarmsJson);
    } catch (e) {
      // Handle error
    }
  }

  /// Load all stopwatches from storage
  Future<List<StopwatchModel>> loadStopwatches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stopwatchesJson = prefs.getString(_stopwatchesKey);
      if (stopwatchesJson == null) return [];

      final List<dynamic> stopwatchesList = json.decode(stopwatchesJson);
      return stopwatchesList
          .map(
              (json) => StopwatchModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Save all stopwatches to storage
  Future<void> saveStopwatches(List<StopwatchModel> stopwatches) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stopwatchesJson = json.encode(
        stopwatches.map((stopwatch) => stopwatch.toJson()).toList(),
      );
      await prefs.setString(_stopwatchesKey, stopwatchesJson);
    } catch (e) {
      // Handle error
    }
  }

  /// Load theme mode
  Future<String?> loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_themeKey);
    } catch (e) {
      return null;
    }
  }

  /// Save theme mode
  Future<void> saveThemeMode(String themeMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, themeMode);
    } catch (e) {
      // Handle error
    }
  }
}

