import '../common/failures.dart';
import '../common/result.dart';
import '../domain/entities/local_shell_entity.dart';
import 'network_interfaces.dart';

/// Contract for local pseudo-terminal management and shell discovery.
abstract class ILocalTerminalService {
  /// Detects installed shells on the current operating system.
  Future<List<LocalShellProfile>> detectAvailableShells();

  /// Launches an interactive PTY session for the given shell profile.
  Future<Result<ITerminalSession, NetworkFailure>> startSession({
    required LocalShellProfile profile,
    required TerminalDimensions initialDimensions,
  });
}
