import 'package:flutter/foundation.dart';

class SecurityActivityEvent {
  const SecurityActivityEvent({
    required this.title,
    required this.description,
    required this.occurredAt,
  });

  final String title;
  final String description;
  final DateTime occurredAt;
}

class SecurityActivityLog extends ChangeNotifier {
  final List<SecurityActivityEvent> _events = <SecurityActivityEvent>[];

  List<SecurityActivityEvent> get events =>
      List.unmodifiable(_events.reversed.toList(growable: false));

  void record({required String title, required String description}) {
    _events.add(
      SecurityActivityEvent(
        title: title,
        description: description,
        occurredAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void clear() {
    if (_events.isEmpty) return;
    _events.clear();
    notifyListeners();
  }
}

final securityActivityLog = SecurityActivityLog();
