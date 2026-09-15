import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AutoLockDuration {
  immediately,
  oneMinute,
  fiveMinutes,
  fifteenMinutes,
  thirtyMinutes,
  never,
}

extension AutoLockDurationExtension on AutoLockDuration {
  Duration? get duration {
    switch (this) {
      case AutoLockDuration.immediately:
        return Duration.zero;
      case AutoLockDuration.oneMinute:
        return const Duration(minutes: 1);
      case AutoLockDuration.fiveMinutes:
        return const Duration(minutes: 5);
      case AutoLockDuration.fifteenMinutes:
        return const Duration(minutes: 15);
      case AutoLockDuration.thirtyMinutes:
        return const Duration(minutes: 30);
      case AutoLockDuration.never:
        return null;
    }
  }

  String get label {
    switch (this) {
      case AutoLockDuration.immediately:
        return 'Immediately';
      case AutoLockDuration.oneMinute:
        return '1 minute';
      case AutoLockDuration.fiveMinutes:
        return '5 minutes';
      case AutoLockDuration.fifteenMinutes:
        return '15 minutes';
      case AutoLockDuration.thirtyMinutes:
        return '30 minutes';
      case AutoLockDuration.never:
        return 'Never';
    }
  }
}

class AppLockVerifyResult {
  const AppLockVerifyResult({
    required this.isValid,
    required this.isLockedOut,
    this.remainingLockout = Duration.zero,
  });

  final bool isValid;
  final bool isLockedOut;
  final Duration remainingLockout;
}

class AppLockController extends ChangeNotifier {
  static const String _enabledKey = 'cloud_guard_app_lock_enabled';
  static const String _pinKey = 'cloud_guard_app_lock_pin';
  static const String _failedAttemptsKey =
      'cloud_guard_app_lock_failed_attempts';
  static const String _lockedUntilKey =
      'cloud_guard_app_lock_locked_until';
  static const String _autoLockDurationKey =
      'cloud_guard_app_lock_auto_lock_duration';

  static const int _maximumFailedAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 10);

  bool _enabled = false;
  String? _pin;
  int _failedAttempts = 0;
  DateTime? _lockedUntil;

  AutoLockDuration _autoLockDuration = AutoLockDuration.fiveMinutes;

  AppLockController() {
    ready = _load();
  }

  late final Future<void> ready;

  bool get enabled => _enabled && _pin != null && _pin!.isNotEmpty;

  int get failedAttempts => _failedAttempts;

  int get maximumFailedAttempts => _maximumFailedAttempts;

  DateTime? get lockedUntil => _lockedUntil;

  AutoLockDuration get autoLockDuration => _autoLockDuration;

  Duration? get autoLockAfter => _autoLockDuration.duration;

  bool get isLockedOut {
    final until = _lockedUntil;

    if (until == null) return false;

    if (DateTime.now().isBefore(until)) {
      return true;
    }

    _lockedUntil = null;
    _failedAttempts = 0;
    _persist();

    return false;
  }

  Duration get remainingLockout {
    final until = _lockedUntil;

    if (until == null) {
      return Duration.zero;
    }

    final remaining = until.difference(DateTime.now());

    return remaining.isNegative ? Duration.zero : remaining;
  }

  Future<void> _load() async {
    try {
      final preferences = await SharedPreferences.getInstance();

      await preferences.reload();

      _enabled = preferences.getBool(_enabledKey) ?? false;

      _pin = preferences.getString(_pinKey);

      _failedAttempts =
          preferences.getInt(_failedAttemptsKey) ?? 0;

      final lockedUntilMilliseconds =
          preferences.getInt(_lockedUntilKey);

      if (lockedUntilMilliseconds != null) {
        _lockedUntil = DateTime.fromMillisecondsSinceEpoch(
          lockedUntilMilliseconds,
        );
      }

      final savedAutoLockDuration =
          preferences.getString(_autoLockDurationKey);

      if (savedAutoLockDuration != null) {
        _autoLockDuration = AutoLockDuration.values.firstWhere(
          (duration) => duration.name == savedAutoLockDuration,
          orElse: () => AutoLockDuration.fiveMinutes,
        );
      }

      if (!isLockedOut) {
        _failedAttempts = 0;
      }
    } catch (_) {
      _enabled = false;
      _pin = null;
      _failedAttempts = 0;
      _lockedUntil = null;
      _autoLockDuration = AutoLockDuration.fiveMinutes;
    }
  }

  Future<void> reload() async {
    await _load();

    notifyListeners();
  }

  Future<void> enableWithPin(String pin) async {
    _validatePin(pin);

    _pin = pin;
    _enabled = true;
    _failedAttempts = 0;
    _lockedUntil = null;

    await _persist();

    notifyListeners();
  }

  Future<void> changePin(String pin) async {
    _validatePin(pin);

    if (!enabled) {
      await enableWithPin(pin);
      return;
    }

    _pin = pin;
    _failedAttempts = 0;
    _lockedUntil = null;

    await _persist();

    notifyListeners();
  }

  Future<void> disable() async {
    _enabled = false;
    _pin = null;
    _failedAttempts = 0;
    _lockedUntil = null;

    await _persist();

    notifyListeners();
  }

  Future<void> setAutoLockDuration(
    AutoLockDuration duration,
  ) async {
    _autoLockDuration = duration;

    await _persist();

    notifyListeners();
  }

  AppLockVerifyResult verifyPin(String pin) {
    if (isLockedOut) {
      return AppLockVerifyResult(
        isValid: false,
        isLockedOut: true,
        remainingLockout: remainingLockout,
      );
    }

    if (pin == _pin) {
      _failedAttempts = 0;

      _persist();

      notifyListeners();

      return const AppLockVerifyResult(
        isValid: true,
        isLockedOut: false,
      );
    }

    _failedAttempts += 1;

    if (_failedAttempts >= _maximumFailedAttempts) {
      _lockedUntil =
          DateTime.now().add(_lockoutDuration);

      _failedAttempts = 0;
    }

    _persist();

    notifyListeners();

    return AppLockVerifyResult(
      isValid: false,
      isLockedOut: isLockedOut,
      remainingLockout: remainingLockout,
    );
  }

  void _validatePin(String pin) {
    if (!RegExp(r'^\d{4,6}$').hasMatch(pin)) {
      throw const FormatException(
        'PIN must contain 4 to 6 digits.',
      );
    }
  }

  Future<void> _persist() async {
    try {
      final preferences =
          await SharedPreferences.getInstance();

      await preferences.setBool(
        _enabledKey,
        _enabled,
      );

      if (_pin == null) {
        await preferences.remove(_pinKey);
      } else {
        await preferences.setString(
          _pinKey,
          _pin!,
        );
      }

      await preferences.setInt(
        _failedAttemptsKey,
        _failedAttempts,
      );

      if (_lockedUntil == null) {
        await preferences.remove(_lockedUntilKey);
      } else {
        await preferences.setInt(
          _lockedUntilKey,
          _lockedUntil!.millisecondsSinceEpoch,
        );
      }

      await preferences.setString(
        _autoLockDurationKey,
        _autoLockDuration.name,
      );
    } catch (_) {
      // App lock state remains usable for the current session
      // if persistence fails.
    }
  }
}

final appLockController = AppLockController();