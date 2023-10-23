import 'dart:convert';

import 'package:audio_service/audio_service.dart';

import '../shared/constants.dart';
import '../shared/helpers.dart';

class Script {
  String id;
  String title;
  int? totalLines;
  Map<String, dynamic> extras;

  Script({
    required this.id,
    required this.title,
    this.totalLines,
    required this.extras,
  });

  factory Script.fromSqlite(Map<String, Object?> query) {
    if (query.containsKey('id')) {
      return Script(
        id: query['id'] as String,
        title: query['title'] as String,
        totalLines: query['totalLines'] as int?,
        extras: jsonDecode(query['extras'] as String? ?? '{}'),
      );
    }
    throw Exception('invalid query result');
  }

  factory Script.fromMediaItem(MediaItem item) {
    return Script(
      id: item.id,
      title: item.title,
      totalLines: item.duration?.inSeconds,
      extras: item.extras ?? {},
    );
  }

  MediaItem toMediaItem() {
    return MediaItem(
      id: id,
      title: title,
      album: title,
      displayTitle: '$appName is reading',
      displaySubtitle: title,
      artUri: Uri.parse(artUri ?? ''),
      duration: Duration(seconds: totalLines ?? 0),
      extras: extras,
    );
  }

  Map<String, Object?> toSqlite() {
    return {
      'id': id,
      'title': title,
      'totalLines': totalLines,
      'extras': jsonEncode(extras),
    };
  }

  @override
  String toString() {
    return toSqlite().toString();
  }
}
