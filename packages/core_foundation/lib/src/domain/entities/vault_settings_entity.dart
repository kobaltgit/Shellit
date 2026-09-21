import 'package:meta/meta.dart';

/// User settings for vault security, themes, and terminal defaults.
@immutable
class VaultSettingsEntity {
  final int idleLockTimeoutMinutes;
  final bool isBiometricsEnabled;
  final bool isPinEnabled;
  final String themeId;
  final String terminalFontFamily;
  final double terminalFontSize;
  final bool enableLiveLatencyPing;
  final int pingIntervalSeconds;

  // Sync settings
  final String? syncServerUrl;
  final bool isSyncEnabled;
  final String? syncVaultId;
  final bool allowInsecureCertificates;
  final DateTime? lastSyncedAt;
  final String? syncPassphrase;
  final String? registrationToken;

  // AI & Gemini settings
  final String? geminiApiKey;
  final String geminiModelId;
  final bool isAiSnippetEnabled;

  // Workspace restoration settings
  final bool restoreWorkspaceSessions;
  final bool autoReconnectOnRestore;

  const VaultSettingsEntity({
    this.idleLockTimeoutMinutes = 15,
    this.isBiometricsEnabled = false,
    this.isPinEnabled = false,
    this.themeId = 'deep_slate',
    this.terminalFontFamily = 'JetBrains Mono',
    this.terminalFontSize = 14.0,
    this.enableLiveLatencyPing = true,
    this.pingIntervalSeconds = 45,
    this.syncServerUrl,
    this.isSyncEnabled = false,
    this.syncVaultId,
    this.allowInsecureCertificates = false,
    this.lastSyncedAt,
    this.syncPassphrase,
    this.registrationToken,
    this.geminiApiKey,
    this.geminiModelId = 'gemini-2.5-flash',
    this.isAiSnippetEnabled = false,
    this.restoreWorkspaceSessions = true,
    this.autoReconnectOnRestore = false,
  });

  VaultSettingsEntity copyWith({
    int? idleLockTimeoutMinutes,
    bool? isBiometricsEnabled,
    bool? isPinEnabled,
    String? themeId,
    String? terminalFontFamily,
    double? terminalFontSize,
    bool? enableLiveLatencyPing,
    int? pingIntervalSeconds,
    String? syncServerUrl,
    bool? isSyncEnabled,
    String? syncVaultId,
    bool? allowInsecureCertificates,
    DateTime? lastSyncedAt,
    String? syncPassphrase,
    String? registrationToken,
    String? geminiApiKey,
    String? geminiModelId,
    bool? isAiSnippetEnabled,
    bool? restoreWorkspaceSessions,
    bool? autoReconnectOnRestore,
  }) {
    return VaultSettingsEntity(
      idleLockTimeoutMinutes:
          idleLockTimeoutMinutes ?? this.idleLockTimeoutMinutes,
      isBiometricsEnabled: isBiometricsEnabled ?? this.isBiometricsEnabled,
      isPinEnabled: isPinEnabled ?? this.isPinEnabled,
      themeId: themeId ?? this.themeId,
      terminalFontFamily: terminalFontFamily ?? this.terminalFontFamily,
      terminalFontSize: terminalFontSize ?? this.terminalFontSize,
      enableLiveLatencyPing:
          enableLiveLatencyPing ?? this.enableLiveLatencyPing,
      pingIntervalSeconds: pingIntervalSeconds ?? this.pingIntervalSeconds,
      syncServerUrl: syncServerUrl ?? this.syncServerUrl,
      isSyncEnabled: isSyncEnabled ?? this.isSyncEnabled,
      syncVaultId: syncVaultId ?? this.syncVaultId,
      allowInsecureCertificates:
          allowInsecureCertificates ?? this.allowInsecureCertificates,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      syncPassphrase: syncPassphrase ?? this.syncPassphrase,
      registrationToken: registrationToken ?? this.registrationToken,
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
      geminiModelId: geminiModelId ?? this.geminiModelId,
      isAiSnippetEnabled: isAiSnippetEnabled ?? this.isAiSnippetEnabled,
      restoreWorkspaceSessions:
          restoreWorkspaceSessions ?? this.restoreWorkspaceSessions,
      autoReconnectOnRestore:
          autoReconnectOnRestore ?? this.autoReconnectOnRestore,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VaultSettingsEntity &&
          runtimeType == other.runtimeType &&
          idleLockTimeoutMinutes == other.idleLockTimeoutMinutes &&
          isBiometricsEnabled == other.isBiometricsEnabled &&
          isPinEnabled == other.isPinEnabled &&
          themeId == other.themeId &&
          syncServerUrl == other.syncServerUrl &&
          isSyncEnabled == other.isSyncEnabled &&
          syncVaultId == other.syncVaultId &&
          allowInsecureCertificates == other.allowInsecureCertificates &&
          lastSyncedAt == other.lastSyncedAt &&
          syncPassphrase == other.syncPassphrase &&
          registrationToken == other.registrationToken &&
          geminiApiKey == other.geminiApiKey &&
          geminiModelId == other.geminiModelId &&
          isAiSnippetEnabled == other.isAiSnippetEnabled &&
          restoreWorkspaceSessions == other.restoreWorkspaceSessions &&
          autoReconnectOnRestore == other.autoReconnectOnRestore;

  @override
  int get hashCode => Object.hash(
        idleLockTimeoutMinutes,
        isBiometricsEnabled,
        isPinEnabled,
        themeId,
        syncServerUrl,
        isSyncEnabled,
        syncVaultId,
        allowInsecureCertificates,
        lastSyncedAt,
        syncPassphrase,
        registrationToken,
        geminiApiKey,
        geminiModelId,
        isAiSnippetEnabled,
        restoreWorkspaceSessions,
        autoReconnectOnRestore,
      );
}
