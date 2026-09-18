/// Standard permission identifiers available to Shellit plugins.
abstract class PluginPermissions {
  /// Allows the plugin to run shell commands in the current or specified terminal session.
  static const String terminalExecute = 'terminal:execute';

  /// Allows the plugin to read the list of configured hosts from the vault.
  static const String vaultReadHosts = 'vault:read_hosts';

  /// Allows the plugin to trigger desktop notifications.
  static const String notificationsShow = 'notifications:show';

  /// Allows the plugin to access isolated key-value local storage.
  static const String storageLocal = 'storage:local';

  /// Allows the plugin to read clipboard contents.
  static const String clipboardRead = 'clipboard:read';

  /// Allows the plugin to write to the system clipboard.
  static const String clipboardWrite = 'clipboard:write';

  /// Set of all predefined standard permissions.
  static const Set<String> standardPermissions = {
    terminalExecute,
    vaultReadHosts,
    notificationsShow,
    storageLocal,
    clipboardRead,
    clipboardWrite,
  };

  /// Validates format of a permission string (e.g. `domain:action` or `action`).
  static bool isValidFormat(String permission) {
    if (permission.trim().isEmpty) return false;
    final regex = RegExp(r'^[a-z0-9_-]+(:[a-z0-9_-]+)*$');
    return regex.hasMatch(permission.toLowerCase());
  }
}
