import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import '../native/lw_sysapi_base.dart';

/// One dropped file or a group of alternative representations of one item.
class SystemDropItem {
  final String? name;
  final Uri? uri;
  final List<ClipboardContent> contents;

  const SystemDropItem({this.name, this.uri, this.contents = const []});

  factory SystemDropItem.fromMap(Map<Object?, Object?> map) {
    final path = map['path'];
    final uri = map['uri'];
    return SystemDropItem(
      name: map['name'] as String?,
      uri: uri is String
          ? Uri.tryParse(uri)
          : path is String
          ? Uri.file(
              path,
              windows: RegExp(r'^(?:[a-zA-Z]:|\\\\)').hasMatch(path),
            )
          : null,
      contents: [
        for (final value in (map['contents'] as List? ?? const []))
          if (value is Map &&
              value['type'] is String &&
              value['data'] is Uint8List)
            (type: value['type'] as String, data: value['data'] as Uint8List),
      ],
    );
  }

  /// URI lists are shared by desktop drag sources and browser link drags.
  static List<Uri> parseUriList(String text) => [
    for (final line in const LineSplitter().convert(
      text.replaceAll('\u0000', ''),
    ))
      if (line.trim().isNotEmpty && !line.trimLeft().startsWith('#'))
        if (Uri.tryParse(line.trim()) case final Uri uri when uri.hasScheme)
          uri,
  ];
}

enum SystemDropPhase { hover, exit, drop }

/// Positions are logical pixels relative to the Flutter view.
class SystemDropEvent {
  final SystemDropPhase phase;
  final Offset position;
  final List<SystemDropItem> items;

  const SystemDropEvent({
    required this.phase,
    required this.position,
    this.items = const [],
  });

  factory SystemDropEvent.fromMap(Map<Object?, Object?> map) => SystemDropEvent(
    phase: SystemDropPhase.values.byName(map['phase'] as String),
    position: Offset(
      (map['x'] as num).toDouble(),
      (map['y'] as num).toDouble(),
    ),
    items: [
      for (final item in (map['items'] as List? ?? const []))
        if (item is Map) SystemDropItem.fromMap(item),
    ],
  );
}

class SystemDropDetails {
  final Offset localPosition;
  final Offset globalPosition;
  final List<SystemDropItem> items;

  const SystemDropDetails({
    required this.localPosition,
    required this.globalPosition,
    required this.items,
  });
}
