import 'dart:async';
import 'dart:developer' as developer;

enum LogLevel { debug, info, warning, error }

/// Represents a single sanitized log event in Shellit.
class LogEntry {
  final String id;
  final DateTime timestamp;
  final LogLevel level;
  final String tag;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  LogEntry({
    String? id,
    DateTime? timestamp,
    required this.level,
    required this.tag,
    required this.message,
    this.error,
    this.stackTrace,
  })  : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    final timeStr = timestamp.toIso8601String().substring(11, 19);
    final levelStr = level.name.toUpperCase().padRight(5);
    final errStr = error != null ? ' | Error: $error' : '';
    return '[$timeStr] [$levelStr] [$tag] $message$errStr';
  }
}

/// Secure Application Logger for Shellit.
/// Automatically filters and masks private keys, passwords, and secrets.
class AppLogger {
  static LogLevel minLevel = LogLevel.debug;
  static bool enableConsoleOutput = true;

  static final StreamController<LogEntry> _entryController =
      StreamController<LogEntry>.broadcast();

  /// Stream of sanitized log entries for live UI and disk sinks.
  static Stream<LogEntry> get entryStream => _entryController.stream;

  static final RegExp _privateKeyPattern = RegExp(
    r'-----BEGIN [A-Z ]+PRIVATE KEY-----[\s\S]*?-----END [A-Z ]+PRIVATE KEY-----',
  );

  static final RegExp _passwordParamPattern = RegExp(
    r'\b(password|passphrase|secret|token|privateKey)\b\s*[:=]\s*(?:"[^"]*"|'
    "'"
    r"[^']*'"
    r'|[^\s,;]+)',
    caseSensitive: false,
  );

  /// Sanitizes messages to prevent credentials leaking into logs.
  static String sanitize(String message) {
    var clean =
        message.replaceAll(_privateKeyPattern, '***[REDACTED_PRIVATE_KEY]***');
    clean = clean.replaceAllMapped(_passwordParamPattern, (match) {
      final key = match.group(1)!;
      return '$key=***[REDACTED]***';
    });
    return clean;
  }

  static void d(String message, {String tag = 'Shellit'}) {
    _log(LogLevel.debug, message, tag: tag);
  }

  static void i(String message, {String tag = 'Shellit'}) {
    _log(LogLevel.info, message, tag: tag);
  }

  static void w(String message,
      {String tag = 'Shellit', Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.warning, message,
        tag: tag, error: error, stackTrace: stackTrace);
  }

  static void e(String message,
      {String tag = 'Shellit', Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message,
        tag: tag, error: error, stackTrace: stackTrace);
  }

  static void _log(
    LogLevel level,
    String message, {
    required String tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level.index < minLevel.index) return;

    final sanitizedMessage = sanitize(message);

    final entry = LogEntry(
      level: level,
      tag: tag,
      message: sanitizedMessage,
      error: error,
      stackTrace: stackTrace,
    );

    if (_entryController.hasListener) {
      _entryController.add(entry);
    }

    if (enableConsoleOutput) {
      developer.log(
        sanitizedMessage,
        name: tag,
        level: _toDeveloperLogLevel(level),
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static int _toDeveloperLogLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
    }
  }
}
