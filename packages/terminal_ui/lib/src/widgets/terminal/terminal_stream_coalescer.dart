import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/scheduler.dart';
import 'package:xterm/xterm.dart';

/// Coalesces high-throughput terminal input byte streams and schedules batch writes
/// synchronized with VSync screen refresh ticks (60/120 Hz).
///
/// Prevents UI isolate choke, excessive ANSI state machine parsing, and redundant
/// [Terminal.notifyListeners] and repaint cycles when hundreds of socket chunks
/// arrive within a single frame interval.
class TerminalStreamCoalescer {
  final Terminal terminal;

  /// Maximum batch limit in bytes before forcing an immediate batch flush
  /// to protect against out-of-memory (OOM) during massive data dumps (e.g. cat 100mb.bin).
  final int maxBatchBytes;

  /// Fallback frame interval when [SchedulerBinding] is unavailable (e.g. pure unit tests, headless).
  final Duration frameDuration;

  /// Optional injected [SchedulerBinding] (useful for tests or custom scheduling).
  final SchedulerBinding? schedulerBinding;

  /// Optional telemetry hook called after each flushed batch.
  final void Function(int byteCount, String decodedText)? onBatchFlushed;

  final BytesBuilder _buffer = BytesBuilder(copy: false);
  StreamSubscription<List<int>>? _subscription;
  int? _frameCallbackId;
  Timer? _fallbackTimer;
  bool _isScheduled = false;
  bool _isDisposed = false;

  TerminalStreamCoalescer({
    required this.terminal,
    this.maxBatchBytes = 512 * 1024,
    this.frameDuration = const Duration(milliseconds: 16),
    this.schedulerBinding,
    this.onBatchFlushed,
  });

  /// Whether the coalescer has pending unwritten bytes in its buffer.
  bool get hasBufferedBytes => _buffer.isNotEmpty;

  /// Current number of buffered bytes pending write.
  int get bufferedBytesCount => _buffer.length;

  /// Whether a frame flush is currently scheduled.
  bool get isScheduled => _isScheduled;

  /// Whether this coalescer has been disposed.
  bool get isDisposed => _isDisposed;

  /// Adds a chunk of bytes to the buffer and schedules a VSync flush.
  ///
  /// If the accumulated buffer exceeds [maxBatchBytes], it is flushed immediately
  /// to provide backpressure and prevent OOM.
  void addChunk(List<int> bytes) {
    if (_isDisposed || bytes.isEmpty) return;

    _buffer.add(bytes);

    if (_buffer.length >= maxBatchBytes) {
      // Exceeded threshold: immediate backpressure flush
      _cancelScheduled();
      _flushNow(isFinal: false);
    } else {
      _scheduleFlush();
    }
  }

  /// Attaches this coalescer to an incoming [Stream] of byte chunks.
  StreamSubscription<List<int>> attach(
    Stream<List<int>> stream, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    _subscription?.cancel();
    final sub = stream.listen(
      addChunk,
      onError: (Object err, [StackTrace? stack]) {
        flush();
        if (onError != null) {
          if (onError is void Function(Object, StackTrace)) {
            onError(err, stack ?? StackTrace.empty);
          } else if (onError is void Function(Object)) {
            onError(err);
          }
        }
      },
      onDone: () {
        flush(isFinal: true);
        onDone?.call();
      },
      cancelOnError: cancelOnError,
    );
    _subscription = sub;
    return sub;
  }

  /// Forces an immediate synchronous flush of all accumulated bytes into [terminal].
  void flush({bool isFinal = false}) {
    _cancelScheduled();
    _flushNow(isFinal: isFinal);
  }

  /// Disposes this coalescer, cancelling timers and releasing stream subscriptions.
  /// Flushes any remaining bytes before closing.
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _subscription?.cancel();
    _subscription = null;
    flush(isFinal: true);
  }

  void _cancelScheduled() {
    if (_frameCallbackId != null) {
      try {
        final binding = _resolveBinding();
        binding?.cancelFrameCallbackWithId(_frameCallbackId!);
      } catch (_) {}
      _frameCallbackId = null;
    }
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
    _isScheduled = false;
  }

  void _scheduleFlush() {
    if (_isScheduled || _isDisposed || _buffer.isEmpty) return;
    _isScheduled = true;

    final binding = _resolveBinding();
    if (binding != null) {
      try {
        _frameCallbackId = binding.scheduleFrameCallback((_) {
          _frameCallbackId = null;
          _fallbackTimer?.cancel();
          _fallbackTimer = null;
          _isScheduled = false;
          _flushNow(isFinal: false);
        });
        binding.scheduleFrame();
      } catch (_) {
        _frameCallbackId = null;
      }
    }

    // Safety watchdog timer: if VSync does not tick within frameDuration
    // (e.g. app in background, minimized, unit tests, or headless environment),
    // the buffer is guaranteed to flush without stalling.
    _fallbackTimer = Timer(frameDuration, () {
      _fallbackTimer = null;
      if (_frameCallbackId != null) {
        try {
          _resolveBinding()?.cancelFrameCallbackWithId(_frameCallbackId!);
        } catch (_) {}
        _frameCallbackId = null;
      }
      _isScheduled = false;
      _flushNow(isFinal: false);
    });
  }

  SchedulerBinding? _resolveBinding() {
    if (schedulerBinding != null) return schedulerBinding;
    try {
      return SchedulerBinding.instance;
    } catch (_) {
      return null;
    }
  }

  void _flushNow({required bool isFinal}) {
    if (_buffer.isEmpty) return;

    final bytes = _buffer.takeBytes();
    if (bytes.isEmpty) return;

    if (!isFinal) {
      final incompleteCount = _getIncompleteUtf8TrailingByteCount(bytes);
      if (incompleteCount > 0 && incompleteCount < bytes.length) {
        final splitIndex = bytes.length - incompleteCount;
        final readyBytes = Uint8List.sublistView(bytes, 0, splitIndex);
        final trailing = Uint8List.sublistView(bytes, splitIndex);
        _buffer.add(trailing);
        _writeBytes(readyBytes);
        return;
      } else if (incompleteCount == bytes.length) {
        // The entire buffer is an incomplete multi-byte sequence, keep it until next chunk
        _buffer.add(bytes);
        return;
      }
    }

    _writeBytes(bytes);
  }

  void _writeBytes(Uint8List bytes) {
    if (bytes.isEmpty) return;
    final text = utf8.decode(bytes, allowMalformed: true);
    terminal.write(text);
    onBatchFlushed?.call(bytes.length, text);
  }

  /// Calculates the count of trailing bytes in [bytes] that form an incomplete
  /// UTF-8 multi-byte sequence.
  static int _getIncompleteUtf8TrailingByteCount(Uint8List bytes) {
    final length = bytes.length;
    if (length == 0) return 0;

    for (var i = 1; i <= 4 && i <= length; i++) {
      final byte = bytes[length - i];
      if ((byte & 0xE0) == 0xC0) {
        // 2-byte sequence (110xxxxx): requires 2 bytes total
        return i < 2 ? i : 0;
      } else if ((byte & 0xF0) == 0xE0) {
        // 3-byte sequence (1110xxxx): requires 3 bytes total
        return i < 3 ? i : 0;
      } else if ((byte & 0xF8) == 0xF0) {
        // 4-byte sequence (11110xxx): requires 4 bytes total
        return i < 4 ? i : 0;
      } else if ((byte & 0xC0) == 0x80) {
        // Continuation byte (10xxxxxx), continue scanning left for leading byte
        continue;
      } else {
        // ASCII (0xxxxxxx) or invalid leading byte: sequence is either complete or malformed
        return 0;
      }
    }
    return 0;
  }
}
