/// Model class for stopwatch
class StopwatchModel {
  final String id;
  final String name;
  Duration elapsedTime;
  StopwatchStatus status;
  final List<LapModel> laps;
  final DateTime createdAt;
  DateTime? startTime;
  Duration? pausedDuration;

  StopwatchModel({
    required this.id,
    required this.name,
    this.elapsedTime = Duration.zero,
    this.status = StopwatchStatus.stopped,
    List<LapModel>? laps,
    required this.createdAt,
    this.startTime,
    this.pausedDuration,
  }) : laps = laps ?? [];

  /// Create stopwatch from JSON
  factory StopwatchModel.fromJson(Map<String, dynamic> json) {
    return StopwatchModel(
      id: json['id'] as String,
      name: json['name'] as String,
      elapsedTime: Duration(milliseconds: json['elapsedTime'] as int),
      status: StopwatchStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => StopwatchStatus.stopped,
      ),
      laps: (json['laps'] as List<dynamic>?)
              ?.map((e) => LapModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'] as String)
          : null,
      pausedDuration: json['pausedDuration'] != null
          ? Duration(milliseconds: json['pausedDuration'] as int)
          : null,
    );
  }

  /// Convert stopwatch to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'elapsedTime': elapsedTime.inMilliseconds,
      'status': status.toString(),
      'laps': laps.map((lap) => lap.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'startTime': startTime?.toIso8601String(),
      'pausedDuration': pausedDuration?.inMilliseconds,
    };
  }

  /// Create a copy with updated values
  StopwatchModel copyWith({
    String? id,
    String? name,
    Duration? elapsedTime,
    StopwatchStatus? status,
    List<LapModel>? laps,
    DateTime? createdAt,
    DateTime? startTime,
    Duration? pausedDuration,
  }) {
    return StopwatchModel(
      id: id ?? this.id,
      name: name ?? this.name,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      status: status ?? this.status,
      laps: laps ?? this.laps,
      createdAt: createdAt ?? this.createdAt,
      startTime: startTime ?? this.startTime,
      pausedDuration: pausedDuration ?? this.pausedDuration,
    );
  }

  /// Get formatted time string
  String get formattedTime {
    final hours = elapsedTime.inHours;
    final minutes = elapsedTime.inMinutes.remainder(60);
    final seconds = elapsedTime.inSeconds.remainder(60);
    final milliseconds = elapsedTime.inMilliseconds.remainder(1000) ~/ 10;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${milliseconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${milliseconds.toString().padLeft(2, '0')}';
  }
}

/// Stopwatch status enumeration
enum StopwatchStatus {
  stopped,
  running,
  paused,
}

/// Model class for lap time
class LapModel {
  final String id;
  final Duration lapTime;
  final Duration totalTime;
  final DateTime createdAt;

  LapModel({
    required this.id,
    required this.lapTime,
    required this.totalTime,
    required this.createdAt,
  });

  /// Create lap from JSON
  factory LapModel.fromJson(Map<String, dynamic> json) {
    return LapModel(
      id: json['id'] as String,
      lapTime: Duration(milliseconds: json['lapTime'] as int),
      totalTime: Duration(milliseconds: json['totalTime'] as int),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Convert lap to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lapTime': lapTime.inMilliseconds,
      'totalTime': totalTime.inMilliseconds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Get formatted lap time string
  String get formattedLapTime {
    final minutes = lapTime.inMinutes.remainder(60);
    final seconds = lapTime.inSeconds.remainder(60);
    final milliseconds = lapTime.inMilliseconds.remainder(1000) ~/ 10;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${milliseconds.toString().padLeft(2, '0')}';
  }

  /// Get formatted total time string
  String get formattedTotalTime {
    final hours = totalTime.inHours;
    final minutes = totalTime.inMinutes.remainder(60);
    final seconds = totalTime.inSeconds.remainder(60);
    final milliseconds = totalTime.inMilliseconds.remainder(1000) ~/ 10;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${milliseconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${milliseconds.toString().padLeft(2, '0')}';
  }
}

