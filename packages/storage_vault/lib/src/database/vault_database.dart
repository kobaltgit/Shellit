import 'dart:convert';
import 'package:core_foundation/core_foundation.dart';
import 'package:drift/drift.dart';

part 'vault_database.g.dart';

@DataClassName('HostRecord')
class HostsTable extends Table {
  TextColumn get id => text()();
  TextColumn get label => text()();
  TextColumn get hostname => text()();
  IntColumn get port => integer().withDefault(const Constant(22))();
  TextColumn get username => text()();
  TextColumn get authType => text()();
  TextColumn get credentialRefId => text().nullable()();
  TextColumn get folderId => text().nullable()();
  TextColumn get tags => text()(); // JSON-encoded List<String>
  TextColumn get environment => text()();
  TextColumn get osType => text()();
  IntColumn get keepAliveIntervalSeconds =>
      integer().withDefault(const Constant(30))();
  BoolColumn get dangerousCommandProtection =>
      boolean().withDefault(const Constant(false))();
  IntColumn get lastPingLatencyMs => integer().nullable()();
  DateTimeColumn get lastConnectedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('KeyRecord')
class KeysTable extends Table {
  TextColumn get id => text()();
  TextColumn get label => text()();
  TextColumn get keyType => text()();
  BlobColumn get encryptedPrivateKey => blob()();
  TextColumn get publicKey => text()();
  BlobColumn get encryptedPassphrase => blob().nullable()();
  TextColumn get fingerprint => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('FolderRecord')
class FoldersTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get parentId => text().nullable()();
  TextColumn get colorHex => text().nullable()();
  TextColumn get iconName => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SnippetRecord')
class SnippetsTable extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get command => text()();
  TextColumn get description => text().nullable()();
  TextColumn get tags => text()(); // JSON-encoded List<String>
  TextColumn get folderId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('VaultSettingsRecord')
class VaultSettingsTable extends Table {
  IntColumn get id => integer()();
  IntColumn get idleLockTimeoutMinutes =>
      integer().withDefault(const Constant(15))();
  BoolColumn get isBiometricsEnabled =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isPinEnabled => boolean().withDefault(const Constant(false))();
  TextColumn get themeId => text().withDefault(const Constant('deep_slate'))();
  TextColumn get terminalFontFamily =>
      text().withDefault(const Constant('JetBrains Mono'))();
  RealColumn get terminalFontSize => real().withDefault(const Constant(14.0))();
  BoolColumn get enableLiveLatencyPing =>
      boolean().withDefault(const Constant(true))();
  IntColumn get pingIntervalSeconds =>
      integer().withDefault(const Constant(45))();
  TextColumn get syncServerUrl => text().nullable()();
  BoolColumn get isSyncEnabled =>
      boolean().withDefault(const Constant(false))();
  TextColumn get syncVaultId => text().nullable()();
  BoolColumn get allowInsecureCertificates =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SyncTombstoneRecord')
class SyncTombstonesTable extends Table {
  TextColumn get entityId => text()();
  TextColumn get entityType => text()(); // 'host', 'key', 'folder', 'snippet'
  DateTimeColumn get deletedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {entityId};
}

@DataClassName('VaultMetaRecord')
class VaultMetadataTable extends Table {
  TextColumn get metaKey => text()();
  TextColumn get metaValue => text()();

  @override
  Set<Column> get primaryKey => {metaKey};
}

@DriftDatabase(tables: [
  HostsTable,
  KeysTable,
  FoldersTable,
  SnippetsTable,
  VaultSettingsTable,
  VaultMetadataTable,
  SyncTombstonesTable,
])
class VaultDatabase extends _$VaultDatabase {
  VaultDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          // Insert default settings
          await into(vaultSettingsTable).insert(
            const VaultSettingsTableCompanion(
              id: Value(1),
              idleLockTimeoutMinutes: Value(15),
              isBiometricsEnabled: Value(false),
              isPinEnabled: Value(false),
              themeId: Value('deep_slate'),
              terminalFontFamily: Value('JetBrains Mono'),
              terminalFontSize: Value(14.0),
              enableLiveLatencyPing: Value(true),
              pingIntervalSeconds: Value(45),
              isSyncEnabled: Value(false),
              allowInsecureCertificates: Value(false),
            ),
            mode: InsertMode.insertOrIgnore,
          );
        },
      );
}

/// Mapper extension to convert [HostRecord] to/from [HostEntity].
extension HostRecordMapper on HostRecord {
  HostEntity toEntity() {
    List<String> parsedTags;
    try {
      parsedTags = List<String>.from(jsonDecode(tags) as List);
    } catch (_) {
      parsedTags = const [];
    }

    final auth = HostAuthType.values.firstWhere(
      (e) => e.name == authType,
      orElse: () => HostAuthType.password,
    );
    final env = HostEnvironment.values.firstWhere(
      (e) => e.name == environment,
      orElse: () => HostEnvironment.defaultEnv,
    );
    final os = OsType.values.firstWhere(
      (e) => e.name == osType,
      orElse: () => OsType.genericServer,
    );

    return HostEntity(
      id: id,
      label: label,
      hostname: hostname,
      port: port,
      username: username,
      authType: auth,
      credentialRefId: credentialRefId,
      folderId: folderId,
      tags: parsedTags,
      environment: env,
      osType: os,
      keepAliveIntervalSeconds: keepAliveIntervalSeconds,
      dangerousCommandProtection: dangerousCommandProtection,
      lastPingLatencyMs: lastPingLatencyMs,
      lastConnectedAt: lastConnectedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Mapper extension to convert [KeyRecord] to/from [KeyEntity].
extension KeyRecordMapper on KeyRecord {
  KeyEntity toEntity() {
    final type = KeyType.values.firstWhere(
      (e) => e.name == keyType,
      orElse: () => KeyType.ed25519,
    );

    return KeyEntity(
      id: id,
      label: label,
      keyType: type,
      encryptedPrivateKey: encryptedPrivateKey,
      publicKey: publicKey,
      encryptedPassphrase: encryptedPassphrase,
      fingerprint: fingerprint,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Mapper extension to convert [FolderRecord] to/from [FolderEntity].
extension FolderRecordMapper on FolderRecord {
  FolderEntity toEntity() {
    return FolderEntity(
      id: id,
      name: name,
      parentId: parentId,
      colorHex: colorHex,
      iconName: iconName,
      sortOrder: sortOrder,
    );
  }
}

/// Mapper extension to convert [SnippetRecord] to/from [SnippetEntity].
extension SnippetRecordMapper on SnippetRecord {
  SnippetEntity toEntity() {
    List<String> parsedTags;
    try {
      parsedTags = List<String>.from(jsonDecode(tags) as List);
    } catch (_) {
      parsedTags = const [];
    }

    return SnippetEntity(
      id: id,
      title: title,
      command: command,
      description: description,
      tags: parsedTags,
      folderId: folderId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Mapper extension to convert [VaultSettingsRecord] to/from [VaultSettingsEntity].
extension VaultSettingsRecordMapper on VaultSettingsRecord {
  VaultSettingsEntity toEntity() {
    return VaultSettingsEntity(
      idleLockTimeoutMinutes: idleLockTimeoutMinutes,
      isBiometricsEnabled: isBiometricsEnabled,
      isPinEnabled: isPinEnabled,
      themeId: themeId,
      terminalFontFamily: terminalFontFamily,
      terminalFontSize: terminalFontSize,
      enableLiveLatencyPing: enableLiveLatencyPing,
      pingIntervalSeconds: pingIntervalSeconds,
      syncServerUrl: syncServerUrl,
      isSyncEnabled: isSyncEnabled,
      syncVaultId: syncVaultId,
      allowInsecureCertificates: allowInsecureCertificates,
      lastSyncedAt: lastSyncedAt,
    );
  }
}
