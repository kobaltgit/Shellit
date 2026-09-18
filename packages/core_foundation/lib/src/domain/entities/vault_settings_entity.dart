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
          registrationToken == other.registrationToken;

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
      );
}
