import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Structured application logger.
///
/// In debug mode, logs to `dart:developer`. In release mode, this is a
/// no-op placeholder — swap in a crash-reporting SDK (e.g., Sentry)
/// during Phase 6.
abstract final class AppLogger {
  static void debug(String message, {String? tag, Object? error}) {
    if (kDebugMode) {
      developer.log(message, name: tag ?? 'NEUROPLAY', error: error);
    }
  }

  static void info(String message, {String? tag}) {
    if (kDebugMode) {
      developer.log('[INFO] $message', name: tag ?? 'NEUROPLAY');
    }
  }

  static void warning(String message, {String? tag, Object? error}) {
    if (kDebugMode) {
      developer.log('[WARN] $message', name: tag ?? 'NEUROPLAY', error: error);
    }
  }

  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      developer.log(
        '[ERROR] $message',
        name: tag ?? 'NEUROPLAY',
        error: error,
        stackTrace: stackTrace,
      );
    }
    // TODO(phase-6): Send to crash reporting service in release mode.
  }
}
