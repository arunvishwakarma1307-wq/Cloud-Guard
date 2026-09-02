import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityActivityEvent {
  const SecurityActivityEvent({
    required this.title,
    required this.description,
    required this.occurredAt,
  });

  final String title;
  final String description;
  final DateTime occurredAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'title': title,
    'description': description,
    'occurredAt': occurredAt.toIso8601String(),
  };

  factory SecurityActivityEvent.fromJson(Map<String, dynamic> json) {
    return SecurityActivityEvent(
      title: json['title'] as String? ?? 'Unknown activity',
      description: json['description'] as String? ?? '',
      occurredAt:
          DateTime.tryParse(json['occurredAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class SecurityActivityLog extends ChangeNotifier {
  static const String _storageKey = 'cloud_guard_security_activity_events';

  final List<SecurityActivityEvent> _events = <SecurityActivityEvent>[];
  bool _isLoading = true;

  SecurityActivityLog() {
    ready = _load();
  }

  late final Future<void> ready;

  List<SecurityActivityEvent> get events =>
      List.unmodifiable(_events.reversed.toList(growable: false));

  bool get isLoading => _isLoading;

  Future<void> _load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final storedEvents =
          preferences.getStringList(_storageKey) ?? const <String>[];

      _events
        ..clear()
        ..addAll(
          storedEvents.map(
            (value) => SecurityActivityEvent.fromJson(
              jsonDecode(value) as Map<String, dynamic>,
            ),
          ),
        );
    } catch (_) {
      // Keep the app usable if local activity data cannot be read.
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void record({required String title, required String description}) {
    _events.add(
      SecurityActivityEvent(
        title: title,
        description: description,
        occurredAt: DateTime.now(),
      ),
    );
    notifyListeners();
    _persist();
  }

  void clear() {
    if (_events.isEmpty) return;
    _events.clear();
    notifyListeners();
    _persist();
  }

  Future<void> _persist() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setStringList(
        _storageKey,
        _events.map((event) => jsonEncode(event.toJson())).toList(),
      );
    } catch (_) {
      // Local persistence is best-effort and must not interrupt app actions.
    }
  }
}

final securityActivityLog = SecurityActivityLog();
