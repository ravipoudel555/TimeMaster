/// Model class for countdown timer
class TimerModel {
  final String id;
  final String name;
  final Duration duration;
  Duration remainingTime;
  TimerStatus status;
  final DateTime createdAt;
  DateTime? pausedAt;
  Duration? pausedDuration;

  TimerModel({
    required this.id,
    required this.name,
    required this.duration,
    required this.remainingTime,
    this.status = TimerStatus.stopped,
    required this.createdAt,
    this.pausedAt,
    this.pausedDuration,
  });

  /// Create a new timer from JSON
  factory TimerModel.fromJson(Map<String, dynamic> json) {
    return TimerModel(
      id: json['id'] as String,
      name: json['name'] as String,
      duration: Duration(seconds: json['duration'] as int),
      remainingTime: Duration(seconds: json['remainingTime'] as int),
      status: TimerStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => TimerStatus.stopped,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      pausedAt: json['pausedAt'] != null
          ? DateTime.parse(json['pausedAt'] as String)
          : null,
      pausedDuration: json['pausedDuration'] != null
          ? Duration(seconds: json['pausedDuration'] as int)
          : null,
    );
  }

  /// Convert timer to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'duration': duration.inSeconds,
      'remainingTime': remainingTime.inSeconds,
      'status': status.toString(),
      'createdAt': createdAt.toIso8601String(),
      'pausedAt': pausedAt?.toIso8601String(),
      'pausedDuration': pausedDuration?.inSeconds,
    };
  }

  /// Create a copy with updated values
  TimerModel copyWith({
    String? id,
    String? name,
    Duration? duration,
    Duration? remainingTime,
    TimerStatus? status,
    DateTime? createdAt,
    DateTime? pausedAt,
    Duration? pausedDuration,
  }) {
    return TimerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      duration: duration ?? this.duration,
      remainingTime: remainingTime ?? this.remainingTime,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      pausedAt: pausedAt ?? this.pausedAt,
      pausedDuration: pausedDuration ?? this.pausedDuration,
    );
  }

  /// Check if timer is finished
  bool get isFinished => remainingTime.inSeconds <= 0;

  /// Get formatted time string
  String get formattedTime {
    final hours = remainingTime.inHours;
    final minutes = remainingTime.inMinutes.remainder(60);
    final seconds = remainingTime.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Timer status enumeration
enum TimerStatus {
  stopped,
  running,
  paused,
  finished,
}

