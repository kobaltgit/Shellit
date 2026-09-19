import 'dart:io';
import 'package:core_foundation/core_foundation.dart';

/// Service responsible for scanning and detecting installed local shells on the host OS.
class LocalShellDetector {
  const LocalShellDetector();

  /// Scans the system for installed shells and returns available profiles.
  /// [preferredDefaultId] allows preserving user's previously saved default shell.
  Future<List<LocalShellProfile>> detectAvailableShells({
    String? preferredDefaultId,
  }) async {
    final List<LocalShellProfile> profiles = [];

    if (Platform.isWindows) {
      _detectWindowsShells(profiles);
    } else if (Platform.isMacOS || Platform.isLinux) {
      _detectUnixShells(profiles);
    }

    if (profiles.isEmpty) {
      // Fallback shell
      profiles.add(
        const LocalShellProfile(
          id: 'system_default',
          name: 'System Shell',
          shellType: ShellType.custom,
          executablePath: 'cmd.exe',
          isDefault: true,
        ),
      );
      return profiles;
    }

    // Apply default selection
    // 1. If preferredDefaultId matches an existing profile, mark it default
    // 2. Otherwise: PowerShell 7 > Windows PowerShell > first profile
    var defaultIndex = -1;
    if (preferredDefaultId != null) {
      defaultIndex = profiles.indexWhere((p) => p.id == preferredDefaultId);
    }

    if (defaultIndex == -1) {
      // Automatic priority: pwsh > powershell > cmd > first
      defaultIndex = profiles.indexWhere((p) => p.shellType == ShellType.pwsh);
      if (defaultIndex == -1) {
        defaultIndex =
            profiles.indexWhere((p) => p.shellType == ShellType.powershell);
      }
      if (defaultIndex == -1) {
        defaultIndex = profiles.indexWhere((p) => p.shellType == ShellType.cmd);
      }
      if (defaultIndex == -1) {
        defaultIndex = 0;
      }
    }

    return List.generate(profiles.length, (i) {
      final p = profiles[i];
      return p.copyWith(isDefault: i == defaultIndex);
    });
  }

  void _detectWindowsShells(List<LocalShellProfile> list) {
    final sysRoot = Platform.environment['SystemRoot'] ?? r'C:\Windows';
    final progFiles =
        Platform.environment['ProgramFiles'] ?? r'C:\Program Files';
    final progFilesX86 =
        Platform.environment['ProgramFiles(x86)'] ?? r'C:\Program Files (x86)';
    final localAppData = Platform.environment['LocalAppData'] ?? '';

    // 1. PowerShell 7 (pwsh.exe)
    final pwshCandidates = [
      '$progFiles\\PowerShell\\7\\pwsh.exe',
      '$progFiles\\PowerShell\\7-preview\\pwsh.exe',
      if (localAppData.isNotEmpty)
        '$localAppData\\Microsoft\\WindowsApps\\pwsh.exe',
    ];
    String? foundPwsh;
    for (final path in pwshCandidates) {
      if (File(path).existsSync()) {
        foundPwsh = path;
        break;
      }
    }
    if (foundPwsh != null) {
      list.add(
        LocalShellProfile(
          id: 'pwsh',
          name: 'PowerShell 7',
          shellType: ShellType.pwsh,
          executablePath: foundPwsh,
        ),
      );
    }

    // 2. Windows PowerShell 5.1
    final winPowerShell =
        '$sysRoot\\System32\\WindowsPowerShell\\v1.0\\powershell.exe';
    if (File(winPowerShell).existsSync()) {
      list.add(
        LocalShellProfile(
          id: 'powershell',
          name: 'Windows PowerShell',
          shellType: ShellType.powershell,
          executablePath: winPowerShell,
        ),
      );
    }

    // 3. Command Prompt (cmd.exe)
    final cmdPath = '$sysRoot\\System32\\cmd.exe';
    if (File(cmdPath).existsSync()) {
      list.add(
        LocalShellProfile(
          id: 'cmd',
          name: 'Command Prompt',
          shellType: ShellType.cmd,
          executablePath: cmdPath,
        ),
      );
    }

    // 4. WSL (Windows Subsystem for Linux)
    final wslPath = '$sysRoot\\System32\\wsl.exe';
    if (File(wslPath).existsSync()) {
      list.add(
        LocalShellProfile(
          id: 'wsl',
          name: 'WSL',
          shellType: ShellType.wsl,
          executablePath: wslPath,
        ),
      );
    }

    // 5. Git Bash
    final gitBashCandidates = [
      '$progFiles\\Git\\bin\\bash.exe',
      '$progFilesX86\\Git\\bin\\bash.exe',
      if (localAppData.isNotEmpty)
        '$localAppData\\Programs\\Git\\bin\\bash.exe',
    ];
    String? foundGitBash;
    for (final path in gitBashCandidates) {
      if (File(path).existsSync()) {
        foundGitBash = path;
        break;
      }
    }
    if (foundGitBash != null) {
      list.add(
        LocalShellProfile(
          id: 'git_bash',
          name: 'Git Bash',
          shellType: ShellType.gitBash,
          executablePath: foundGitBash,
          arguments: const ['--login', '-i'],
        ),
      );
    }
  }

  void _detectUnixShells(List<LocalShellProfile> list) {
    final envShell = Platform.environment['SHELL'];
    if (envShell != null && File(envShell).existsSync()) {
      final name = envShell.split('/').last;
      list.add(
        LocalShellProfile(
          id: 'user_shell',
          name: name.toUpperCase(),
          shellType: name == 'zsh'
              ? ShellType.zsh
              : (name == 'bash' ? ShellType.bash : ShellType.custom),
          executablePath: envShell,
        ),
      );
    }

    final standardShells = ['/bin/zsh', '/bin/bash', '/bin/sh'];
    for (final sh in standardShells) {
      if (list.any((p) => p.executablePath == sh)) continue;
      if (File(sh).existsSync()) {
        final name = sh.split('/').last;
        list.add(
          LocalShellProfile(
            id: name,
            name: name.toUpperCase(),
            shellType: name == 'zsh'
                ? ShellType.zsh
                : (name == 'bash' ? ShellType.bash : ShellType.custom),
            executablePath: sh,
          ),
        );
      }
    }
  }
}
