import 'package:flutter/foundation.dart';
import 'package:xterm/xterm.dart';
import 'shell_command_block.dart';

export 'shell_command_block.dart';

/// Controller managing semantic terminal shell integration and command block tracking
/// based on the OSC 133 (FinalTerm / Shell Integration) standard protocol.
class ShellIntegrationController extends ChangeNotifier {
  final List<ShellCommandBlock> _blocks = [];
  ShellCommandBlock? _currentBlock;
  int _blockIdCounter = 0;
  String? _currentCwd;

  List<ShellCommandBlock> get blocks => List.unmodifiable(_blocks);
  ShellCommandBlock? get currentBlock => _currentBlock;
  String? get currentCwd => _currentCwd;

  /// Handles incoming OSC sequences parsed by the [Terminal] instance.
  void handleOSC(String code, List<String> args, Terminal terminal) {
    if (code == '133') {
      if (args.isEmpty) return;
      final type = args[0].toUpperCase();
      switch (type) {
        case 'A':
          _handlePromptStart(terminal);
          break;
        case 'B':
          _handleCommandStart(terminal);
          break;
        case 'C':
          _handleOutputStart(terminal);
          break;
        case 'D':
          int exitCode = 0;
          if (args.length > 1) {
            exitCode = int.tryParse(args[1]) ?? 0;
          }
          _handleCommandFinished(terminal, exitCode);
          break;
        case 'P':
          if (args.length > 1 && args[1].startsWith('cl=')) {
            final cmd = args[1].substring(3);
            if (_currentBlock != null) {
              _currentBlock!.command = cmd;
              notifyListeners();
            }
          }
          break;
      }
    } else if (code == '7') {
      // OSC 7: Current Working Directory reporting: file://hostname/path
      if (args.isNotEmpty) {
        final uriStr = args[0];
        try {
          final uri = Uri.parse(uriStr);
          _currentCwd = uri.path;
          notifyListeners();
        } catch (_) {
          _currentCwd = uriStr;
          notifyListeners();
        }
      }
    }
  }

  void _handlePromptStart(Terminal terminal) {
    final curY = terminal.buffer.absoluteCursorY;
    // Guard against duplicate prompt start on the same line if no command was run
    if (_currentBlock != null &&
        _currentBlock!.promptLine == curY &&
        _currentBlock!.exitCode == null) {
      return;
    }
    // If the previous block wasn't formally closed with D, close it now
    if (_currentBlock != null && _currentBlock!.endLine == null) {
      _currentBlock!.endLine = curY;
    }

    BufferLine? lineRef;
    if (curY >= 0 && curY < terminal.buffer.lines.length) {
      lineRef = terminal.buffer.lines[curY];
    }

    _currentBlock = ShellCommandBlock(
      id: ++_blockIdCounter,
      promptLine: curY,
      promptBufferLine: lineRef,
    );
    _blocks.add(_currentBlock!);
    notifyListeners();
  }

  void _handleCommandStart(Terminal terminal) {
    if (_currentBlock == null) {
      _handlePromptStart(terminal);
    }
    _currentBlock!.commandLine = terminal.buffer.absoluteCursorY;
    _currentBlock!.startTime ??= DateTime.now();
    notifyListeners();
  }

  void _handleOutputStart(Terminal terminal) {
    if (_currentBlock == null) {
      _handlePromptStart(terminal);
    }
    _currentBlock!.outputStartLine = terminal.buffer.absoluteCursorY;
    _currentBlock!.startTime ??= DateTime.now();
    notifyListeners();
  }

  /// Records command start timestamp when the user submits a command line (e.g. presses Enter).
  void notifyCommandStarted() {
    if (_currentBlock != null && _currentBlock!.startTime == null) {
      _currentBlock!.startTime = DateTime.now();
      notifyListeners();
    }
  }

  void _handleCommandFinished(Terminal terminal, int exitCode) {
    if (_currentBlock != null) {
      _currentBlock!.exitCode = exitCode;
      _currentBlock!.endTime = DateTime.now();
      _currentBlock!.endLine = terminal.buffer.absoluteCursorY;
      notifyListeners();
    }
  }

  /// Extracts clean standard output of a command block from the terminal buffer.
  String getBlockOutput(Terminal terminal, ShellCommandBlock block) {
    if (block.isEvicted) {
      return '';
    }
    final start = block.outputStartLine ?? block.promptLine;
    final end = block.endLine ?? terminal.buffer.lines.length;
    final sb = StringBuffer();
    for (int y = start; y < end && y < terminal.buffer.lines.length; y++) {
      final lineText = terminal.buffer.lines[y].getText();
      sb.writeln(lineText);
    }
    return sb.toString().trimRight();
  }

  /// Finds the prompt line of the previous command block relative to [currentLine].
  int? getPreviousCommandPromptLine(int currentLine) {
    for (int i = _blocks.length - 1; i >= 0; i--) {
      if (_blocks[i].isEvicted) continue;
      if (_blocks[i].promptLine < currentLine) {
        return _blocks[i].promptLine;
      }
    }
    return null;
  }

  /// Finds the prompt line of the next command block relative to [currentLine].
  int? getNextCommandPromptLine(int currentLine) {
    for (int i = 0; i < _blocks.length; i++) {
      if (_blocks[i].isEvicted) continue;
      if (_blocks[i].promptLine > currentLine) {
        return _blocks[i].promptLine;
      }
    }
    return null;
  }

  /// Adds a block directly (primarily used for unit testing).
  @visibleForTesting
  void addBlock(ShellCommandBlock block) {
    _blocks.add(block);
    notifyListeners();
  }

  /// Resets the blocks (e.g. when terminal buffer is cleared).
  void clear() {
    _blocks.clear();
    _currentBlock = null;
    notifyListeners();
  }

  /// Triggers update notification for listeners (e.g. on terminal buffer change or scroll).
  void notifyUpdated() {
    notifyListeners();
  }
}
