/// Represents a structured command execution block detected via OSC 133 sequences.
class ShellCommandBlock {
  final int id;
  final int promptLine;
  int? commandLine;
  int? outputStartLine;
  int? endLine;
  String? command;
  int? exitCode;
  DateTime? startTime;
  DateTime? endTime;

  ShellCommandBlock({
    required this.id,
    required this.promptLine,
    this.commandLine,
    this.outputStartLine,
    this.endLine,
    this.command,
    this.exitCode,
    this.startTime,
    this.endTime,
  });

  /// True if command completed with success status (code 0).
  bool get isSuccess => exitCode == 0;

  /// True if command completed with non-zero exit code (error).
  bool get isFailure => exitCode != null && exitCode != 0;

  /// True if command is currently executing and hasn't reported exit code yet.
  bool get isRunning => startTime != null && exitCode == null;

  /// True if prompt is idle waiting for user command to start.
  bool get isPendingPrompt => startTime == null && exitCode == null;

  /// Duration of command execution from start to finish.
  Duration? get duration => (endTime != null && startTime != null)
      ? endTime!.difference(startTime!)
      : null;

  /// Human-readable duration (e.g. "120ms", "2.4s", "1m 30s").
  String formatDuration() {
    final d = duration;
    if (d == null) return '';
    if (d.inSeconds < 1) return '${d.inMilliseconds}ms';
    if (d.inMinutes < 1) {
      return '${(d.inMilliseconds / 1000).toStringAsFixed(1)}s';
    }
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m}m ${s}s';
  }
}
