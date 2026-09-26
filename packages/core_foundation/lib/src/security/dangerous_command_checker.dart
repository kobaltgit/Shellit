/// Helper to detect destructive and dangerous commands before execution on servers.
class DangerousCommandChecker {
  DangerousCommandChecker._();

  static final List<RegExp> _dangerousPatterns = [
    // 1. rm with recursive and force in any order or via any path (/bin/rm, /usr/bin/rm, sudo rm)
    RegExp(
      r'(?:^|[\s;&|])(?:[^\s]*\/)?rm\s+.*(?:-[a-zA-Z]*r[a-zA-Z]*f[a-zA-Z]*|-[a-zA-Z]*f[a-zA-Z]*r[a-zA-Z]*)',
      caseSensitive: false,
    ),
    RegExp(
      r'(?:^|[\s;&|])(?:[^\s]*\/)?rm\s+.*(?:-[a-zA-Z]*r[a-zA-Z]*\s+-[a-zA-Z]*f[a-zA-Z]*|-[a-zA-Z]*f[a-zA-Z]*\s+-[a-zA-Z]*r[a-zA-Z]*)',
      caseSensitive: false,
    ),
    RegExp(
      r'(?:^|[\s;&|])(?:[^\s]*\/)?rm\s+.*--(?:recursive\s+--force|force\s+--recursive)',
      caseSensitive: false,
    ),
    RegExp(
      r'(?:^|[\s;&|])(?:[^\s]*\/)?rm\s+.*(?:--recursive\s+-[a-zA-Z]*f[a-zA-Z]*|-[a-zA-Z]*f[a-zA-Z]*\s+--recursive)',
      caseSensitive: false,
    ),
    RegExp(
      r'(?:^|[\s;&|])(?:[^\s]*\/)?rm\s+.*(?:--force\s+-[a-zA-Z]*r[a-zA-Z]*|-[a-zA-Z]*r[a-zA-Z]*\s+--force)',
      caseSensitive: false,
    ),
    RegExp(
      r'(?:^|[\s;&|])(?:[^\s]*\/)?rm\s+.*--recursive',
      caseSensitive: false,
    ),

    // 2. System reboots, shutdowns, halts, poweroff
    RegExp(
      r'(?:^|[\s;&|])(?:[^\s]*\/)?(?:reboot|shutdown|poweroff|halt)\b',
      caseSensitive: false,
    ),
    RegExp(
      r'(?:^|[\s;&|])(?:[^\s]*\/)?systemctl\s+(?:poweroff|reboot|halt|emergency|rescue)\b',
      caseSensitive: false,
    ),
    RegExp(
      r'(?:^|[\s;&|])(?:[^\s]*\/)?init\s+[06]\b',
      caseSensitive: false,
    ),

    // 3. Disk & FS destruction
    RegExp(
      r'(?:^|[\s;&|])(?:[^\s]*\/)?(?:mkfs(?:\.[a-z0-9]+)?|wipefs|parted|gdisk|fdisk)\b',
      caseSensitive: false,
    ),
    RegExp(
      r'(?:^|[\s;&|])(?:[^\s]*\/)?dd\s+.*of=\/dev\/',
      caseSensitive: false,
    ),
    RegExp(
      r'>\s*\/dev\/(?:sd[a-z]|nvme\d+n\d+|vd[a-z]|hd[a-z]|loop\d+)',
      caseSensitive: false,
    ),

    // 4. Destructive truncate, perms, fork bombs
    RegExp(
      r'(?:^|[\s;&|])(?:[^\s]*\/)?truncate\s+-s\s*0\b',
      caseSensitive: false,
    ),
    RegExp(
      r'(?:^|[\s;&|])(?:[^\s]*\/)?chmod\s+.*-[a-zA-Z]*R[a-zA-Z]*\s+(?:777|000)\b',
      caseSensitive: false,
    ),
    RegExp(
      r'(?:^|[\s;&|])(?:[^\s]*\/)?kill\s+-9\s+1\b',
      caseSensitive: false,
    ),
    RegExp(
      r':\(\)\s*\{\s*:\s*\|\s*:\s*&\s*\}\s*;\s*:',
      caseSensitive: false,
    ),

    // 5. Database drops & truncates
    RegExp(
      r'\b(?:drop\s+(?:database|table|schema)|truncate\s+table)\b',
      caseSensitive: false,
    ),
  ];

  /// Regex pattern to strip common shell prompts (bash, zsh, sh, root, tcsh)
  /// e.g. "user@hostname:~$ command", "root@server:/etc# command", "user@host > command"
  static final RegExp _shellPromptPattern = RegExp(
    r'^(?:\[.*?\]\s*)?(?:[\w\.\-]+@[\w\.\-]+:[^$#>\n\r]*[$#>]|[\w\.\-]+:[^$#>\n\r]*[$#>]|[$#>])\s*',
    caseSensitive: false,
  );

  /// Returns true if the command matches any dangerous pattern.
  static bool isDangerous(String command) {
    final trimmed = command.trim();
    if (trimmed.isEmpty) return false;
    return _dangerousPatterns.any((pattern) => pattern.hasMatch(trimmed));
  }

  /// Returns description of the matched dangerous pattern or null.
  static String? detectPatternDescription(String command) {
    final trimmed = command.trim();
    if (trimmed.isEmpty) return null;
    for (final pattern in _dangerousPatterns) {
      if (pattern.hasMatch(trimmed)) {
        return 'Potentially destructive command detected: "$trimmed"';
      }
    }
    return null;
  }

  /// Extracts the clean command by stripping common shell prompts from an active line.
  static String cleanPromptAndExtractCommand(String rawLine) {
    final stripped = rawLine.replaceFirst(_shellPromptPattern, '').trim();
    return stripped;
  }
}
