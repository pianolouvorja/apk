library;

import 'package:flutter/foundation.dart';

@immutable
class CountdownPreset {
  final String id;
  final String label;
  final Duration duration;

  const CountdownPreset({
    required this.id,
    required this.label,
    required this.duration,
  });

  factory CountdownPreset.fromJson(Map<String, dynamic> json) {
    return CountdownPreset(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      duration: Duration(seconds: (json['seconds'] as num?)?.toInt() ?? 0),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'seconds': duration.inSeconds,
  };
}
