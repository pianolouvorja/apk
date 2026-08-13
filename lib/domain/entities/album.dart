library;

import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';

/// Álbum (coletânea) do catálogo LouvorJA.
///
/// Fonte: API.md — albums dentro de Category / AlbumRecord.
@immutable
class Album {
  final int id;
  final String? name;
  final String? subtitle;
  final String? coverUrl;
  final int? trackCount;
  final String? colorHex;

  const Album({
    required this.id,
    this.name,
    this.subtitle,
    this.coverUrl,
    this.trackCount,
    this.colorHex,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: _parseInt(json['id_album']),
      name: json['name'] as String?,
      subtitle: json['subtitle'] as String?,
      coverUrl: json['url_image'] as String?,
      trackCount: json['track_count'] as int?,
      colorHex: json['color'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id_album': id,
    if (name != null) 'name': name,
    if (subtitle != null) 'subtitle': subtitle,
    if (coverUrl != null) 'url_image': coverUrl,
    if (trackCount != null) 'track_count': trackCount,
    if (colorHex != null) 'color': colorHex,
  };

  /// Parses [colorHex] (#RRGGBB) to a [Color], or null if invalid.
  Color? get color {
    final hex = colorHex;
    // coverage:ignore-line
    if (hex == null || hex.length < 7) return null;
    try {
      // coverage:ignore-line
      return Color(int.parse('FF${hex.substring(1)}', radix: 16));
    } catch (_) {
      return null;
    }
  }

  static int _parseInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Album && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Album(id: $id, name: $name)';
}
