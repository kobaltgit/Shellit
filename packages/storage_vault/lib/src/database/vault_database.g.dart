// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vault_database.dart';

// ignore_for_file: type=lint
class $HostsTableTable extends HostsTable
    with TableInfo<$HostsTableTable, HostRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HostsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
      'label', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _hostnameMeta =
      const VerificationMeta('hostname');
  @override
  late final GeneratedColumn<String> hostname = GeneratedColumn<String>(
      'hostname', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _portMeta = const VerificationMeta('port');
  @override
  late final GeneratedColumn<int> port = GeneratedColumn<int>(
      'port', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(22));
  static const VerificationMeta _usernameMeta =
      const VerificationMeta('username');
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
      'username', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _authTypeMeta =
      const VerificationMeta('authType');
  @override
  late final GeneratedColumn<String> authType = GeneratedColumn<String>(
      'auth_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _credentialRefIdMeta =
      const VerificationMeta('credentialRefId');
  @override
  late final GeneratedColumn<String> credentialRefId = GeneratedColumn<String>(
      'credential_ref_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _folderIdMeta =
      const VerificationMeta('folderId');
  @override
  late final GeneratedColumn<String> folderId = GeneratedColumn<String>(
      'folder_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
      'tags', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _environmentMeta =
      const VerificationMeta('environment');
  @override
  late final GeneratedColumn<String> environment = GeneratedColumn<String>(
      'environment', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _osTypeMeta = const VerificationMeta('osType');
  @override
  late final GeneratedColumn<String> osType = GeneratedColumn<String>(
      'os_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _keepAliveIntervalSecondsMeta =
      const VerificationMeta('keepAliveIntervalSeconds');
  @override
  late final GeneratedColumn<int> keepAliveIntervalSeconds =
      GeneratedColumn<int>('keep_alive_interval_seconds', aliasedName, false,
          type: DriftSqlType.int,
          requiredDuringInsert: false,
          defaultValue: const Constant(30));
  static const VerificationMeta _dangerousCommandProtectionMeta =
      const VerificationMeta('dangerousCommandProtection');
  @override
  late final GeneratedColumn<bool> dangerousCommandProtection =
      GeneratedColumn<bool>('dangerous_command_protection', aliasedName, false,
          type: DriftSqlType.bool,
          requiredDuringInsert: false,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'CHECK ("dangerous_command_protection" IN (0, 1))'),
          defaultValue: const Constant(false));
  static const VerificationMeta _lastPingLatencyMsMeta =
      const VerificationMeta('lastPingLatencyMs');
  @override
  late final GeneratedColumn<int> lastPingLatencyMs = GeneratedColumn<int>(
      'last_ping_latency_ms', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _lastConnectedAtMeta =
      const VerificationMeta('lastConnectedAt');
  @override
  late final GeneratedColumn<DateTime> lastConnectedAt =
      GeneratedColumn<DateTime>('last_connected_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        label,
        hostname,
        port,
        username,
        authType,
        credentialRefId,
        folderId,
        tags,
        environment,
        osType,
        keepAliveIntervalSeconds,
        dangerousCommandProtection,
        lastPingLatencyMs,
        lastConnectedAt,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hosts_table';
  @override
  VerificationContext validateIntegrity(Insertable<HostRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
          _labelMeta, label.isAcceptableOrUnknown(data['label']!, _labelMeta));
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('hostname')) {
      context.handle(_hostnameMeta,
          hostname.isAcceptableOrUnknown(data['hostname']!, _hostnameMeta));
    } else if (isInserting) {
      context.missing(_hostnameMeta);
    }
    if (data.containsKey('port')) {
      context.handle(
          _portMeta, port.isAcceptableOrUnknown(data['port']!, _portMeta));
    }
    if (data.containsKey('username')) {
      context.handle(_usernameMeta,
          username.isAcceptableOrUnknown(data['username']!, _usernameMeta));
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('auth_type')) {
      context.handle(_authTypeMeta,
          authType.isAcceptableOrUnknown(data['auth_type']!, _authTypeMeta));
    } else if (isInserting) {
      context.missing(_authTypeMeta);
    }
    if (data.containsKey('credential_ref_id')) {
      context.handle(
          _credentialRefIdMeta,
          credentialRefId.isAcceptableOrUnknown(
              data['credential_ref_id']!, _credentialRefIdMeta));
    }
    if (data.containsKey('folder_id')) {
      context.handle(_folderIdMeta,
          folderId.isAcceptableOrUnknown(data['folder_id']!, _folderIdMeta));
    }
    if (data.containsKey('tags')) {
      context.handle(
          _tagsMeta, tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta));
    } else if (isInserting) {
      context.missing(_tagsMeta);
    }
    if (data.containsKey('environment')) {
      context.handle(
          _environmentMeta,
          environment.isAcceptableOrUnknown(
              data['environment']!, _environmentMeta));
    } else if (isInserting) {
      context.missing(_environmentMeta);
    }
    if (data.containsKey('os_type')) {
      context.handle(_osTypeMeta,
          osType.isAcceptableOrUnknown(data['os_type']!, _osTypeMeta));
    } else if (isInserting) {
      context.missing(_osTypeMeta);
    }
    if (data.containsKey('keep_alive_interval_seconds')) {
      context.handle(
          _keepAliveIntervalSecondsMeta,
          keepAliveIntervalSeconds.isAcceptableOrUnknown(
              data['keep_alive_interval_seconds']!,
              _keepAliveIntervalSecondsMeta));
    }
    if (data.containsKey('dangerous_command_protection')) {
      context.handle(
          _dangerousCommandProtectionMeta,
          dangerousCommandProtection.isAcceptableOrUnknown(
              data['dangerous_command_protection']!,
              _dangerousCommandProtectionMeta));
    }
    if (data.containsKey('last_ping_latency_ms')) {
      context.handle(
          _lastPingLatencyMsMeta,
          lastPingLatencyMs.isAcceptableOrUnknown(
              data['last_ping_latency_ms']!, _lastPingLatencyMsMeta));
    }
    if (data.containsKey('last_connected_at')) {
      context.handle(
          _lastConnectedAtMeta,
          lastConnectedAt.isAcceptableOrUnknown(
              data['last_connected_at']!, _lastConnectedAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HostRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HostRecord(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      label: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}label'])!,
      hostname: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}hostname'])!,
      port: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}port'])!,
      username: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}username'])!,
      authType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}auth_type'])!,
      credentialRefId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}credential_ref_id']),
      folderId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}folder_id']),
      tags: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tags'])!,
      environment: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}environment'])!,
      osType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}os_type'])!,
      keepAliveIntervalSeconds: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}keep_alive_interval_seconds'])!,
      dangerousCommandProtection: attachedDatabase.typeMapping.read(
          DriftSqlType.bool,
          data['${effectivePrefix}dangerous_command_protection'])!,
      lastPingLatencyMs: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}last_ping_latency_ms']),
      lastConnectedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_connected_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $HostsTableTable createAlias(String alias) {
    return $HostsTableTable(attachedDatabase, alias);
  }
}

class HostRecord extends DataClass implements Insertable<HostRecord> {
  final String id;
  final String label;
  final String hostname;
  final int port;
  final String username;
  final String authType;
  final String? credentialRefId;
  final String? folderId;
  final String tags;
  final String environment;
  final String osType;
  final int keepAliveIntervalSeconds;
  final bool dangerousCommandProtection;
  final int? lastPingLatencyMs;
  final DateTime? lastConnectedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const HostRecord(
      {required this.id,
      required this.label,
      required this.hostname,
      required this.port,
      required this.username,
      required this.authType,
      this.credentialRefId,
      this.folderId,
      required this.tags,
      required this.environment,
      required this.osType,
      required this.keepAliveIntervalSeconds,
      required this.dangerousCommandProtection,
      this.lastPingLatencyMs,
      this.lastConnectedAt,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['label'] = Variable<String>(label);
    map['hostname'] = Variable<String>(hostname);
    map['port'] = Variable<int>(port);
    map['username'] = Variable<String>(username);
    map['auth_type'] = Variable<String>(authType);
    if (!nullToAbsent || credentialRefId != null) {
      map['credential_ref_id'] = Variable<String>(credentialRefId);
    }
    if (!nullToAbsent || folderId != null) {
      map['folder_id'] = Variable<String>(folderId);
    }
    map['tags'] = Variable<String>(tags);
    map['environment'] = Variable<String>(environment);
    map['os_type'] = Variable<String>(osType);
    map['keep_alive_interval_seconds'] =
        Variable<int>(keepAliveIntervalSeconds);
    map['dangerous_command_protection'] =
        Variable<bool>(dangerousCommandProtection);
    if (!nullToAbsent || lastPingLatencyMs != null) {
      map['last_ping_latency_ms'] = Variable<int>(lastPingLatencyMs);
    }
    if (!nullToAbsent || lastConnectedAt != null) {
      map['last_connected_at'] = Variable<DateTime>(lastConnectedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  HostsTableCompanion toCompanion(bool nullToAbsent) {
    return HostsTableCompanion(
      id: Value(id),
      label: Value(label),
      hostname: Value(hostname),
      port: Value(port),
      username: Value(username),
      authType: Value(authType),
      credentialRefId: credentialRefId == null && nullToAbsent
          ? const Value.absent()
          : Value(credentialRefId),
      folderId: folderId == null && nullToAbsent
          ? const Value.absent()
          : Value(folderId),
      tags: Value(tags),
      environment: Value(environment),
      osType: Value(osType),
      keepAliveIntervalSeconds: Value(keepAliveIntervalSeconds),
      dangerousCommandProtection: Value(dangerousCommandProtection),
      lastPingLatencyMs: lastPingLatencyMs == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPingLatencyMs),
      lastConnectedAt: lastConnectedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastConnectedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory HostRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HostRecord(
      id: serializer.fromJson<String>(json['id']),
      label: serializer.fromJson<String>(json['label']),
      hostname: serializer.fromJson<String>(json['hostname']),
      port: serializer.fromJson<int>(json['port']),
      username: serializer.fromJson<String>(json['username']),
      authType: serializer.fromJson<String>(json['authType']),
      credentialRefId: serializer.fromJson<String?>(json['credentialRefId']),
      folderId: serializer.fromJson<String?>(json['folderId']),
      tags: serializer.fromJson<String>(json['tags']),
      environment: serializer.fromJson<String>(json['environment']),
      osType: serializer.fromJson<String>(json['osType']),
      keepAliveIntervalSeconds:
          serializer.fromJson<int>(json['keepAliveIntervalSeconds']),
      dangerousCommandProtection:
          serializer.fromJson<bool>(json['dangerousCommandProtection']),
      lastPingLatencyMs: serializer.fromJson<int?>(json['lastPingLatencyMs']),
      lastConnectedAt: serializer.fromJson<DateTime?>(json['lastConnectedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'label': serializer.toJson<String>(label),
      'hostname': serializer.toJson<String>(hostname),
      'port': serializer.toJson<int>(port),
      'username': serializer.toJson<String>(username),
      'authType': serializer.toJson<String>(authType),
      'credentialRefId': serializer.toJson<String?>(credentialRefId),
      'folderId': serializer.toJson<String?>(folderId),
      'tags': serializer.toJson<String>(tags),
      'environment': serializer.toJson<String>(environment),
      'osType': serializer.toJson<String>(osType),
      'keepAliveIntervalSeconds':
          serializer.toJson<int>(keepAliveIntervalSeconds),
      'dangerousCommandProtection':
          serializer.toJson<bool>(dangerousCommandProtection),
      'lastPingLatencyMs': serializer.toJson<int?>(lastPingLatencyMs),
      'lastConnectedAt': serializer.toJson<DateTime?>(lastConnectedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  HostRecord copyWith(
          {String? id,
          String? label,
          String? hostname,
          int? port,
          String? username,
          String? authType,
          Value<String?> credentialRefId = const Value.absent(),
          Value<String?> folderId = const Value.absent(),
          String? tags,
          String? environment,
          String? osType,
          int? keepAliveIntervalSeconds,
          bool? dangerousCommandProtection,
          Value<int?> lastPingLatencyMs = const Value.absent(),
          Value<DateTime?> lastConnectedAt = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      HostRecord(
        id: id ?? this.id,
        label: label ?? this.label,
        hostname: hostname ?? this.hostname,
        port: port ?? this.port,
        username: username ?? this.username,
        authType: authType ?? this.authType,
        credentialRefId: credentialRefId.present
            ? credentialRefId.value
            : this.credentialRefId,
        folderId: folderId.present ? folderId.value : this.folderId,
        tags: tags ?? this.tags,
        environment: environment ?? this.environment,
        osType: osType ?? this.osType,
        keepAliveIntervalSeconds:
            keepAliveIntervalSeconds ?? this.keepAliveIntervalSeconds,
        dangerousCommandProtection:
            dangerousCommandProtection ?? this.dangerousCommandProtection,
        lastPingLatencyMs: lastPingLatencyMs.present
            ? lastPingLatencyMs.value
            : this.lastPingLatencyMs,
        lastConnectedAt: lastConnectedAt.present
            ? lastConnectedAt.value
            : this.lastConnectedAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  HostRecord copyWithCompanion(HostsTableCompanion data) {
    return HostRecord(
      id: data.id.present ? data.id.value : this.id,
      label: data.label.present ? data.label.value : this.label,
      hostname: data.hostname.present ? data.hostname.value : this.hostname,
      port: data.port.present ? data.port.value : this.port,
      username: data.username.present ? data.username.value : this.username,
      authType: data.authType.present ? data.authType.value : this.authType,
      credentialRefId: data.credentialRefId.present
          ? data.credentialRefId.value
          : this.credentialRefId,
      folderId: data.folderId.present ? data.folderId.value : this.folderId,
      tags: data.tags.present ? data.tags.value : this.tags,
      environment:
          data.environment.present ? data.environment.value : this.environment,
      osType: data.osType.present ? data.osType.value : this.osType,
      keepAliveIntervalSeconds: data.keepAliveIntervalSeconds.present
          ? data.keepAliveIntervalSeconds.value
          : this.keepAliveIntervalSeconds,
      dangerousCommandProtection: data.dangerousCommandProtection.present
          ? data.dangerousCommandProtection.value
          : this.dangerousCommandProtection,
      lastPingLatencyMs: data.lastPingLatencyMs.present
          ? data.lastPingLatencyMs.value
          : this.lastPingLatencyMs,
      lastConnectedAt: data.lastConnectedAt.present
          ? data.lastConnectedAt.value
          : this.lastConnectedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HostRecord(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('hostname: $hostname, ')
          ..write('port: $port, ')
          ..write('username: $username, ')
          ..write('authType: $authType, ')
          ..write('credentialRefId: $credentialRefId, ')
          ..write('folderId: $folderId, ')
          ..write('tags: $tags, ')
          ..write('environment: $environment, ')
          ..write('osType: $osType, ')
          ..write('keepAliveIntervalSeconds: $keepAliveIntervalSeconds, ')
          ..write('dangerousCommandProtection: $dangerousCommandProtection, ')
          ..write('lastPingLatencyMs: $lastPingLatencyMs, ')
          ..write('lastConnectedAt: $lastConnectedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      label,
      hostname,
      port,
      username,
      authType,
      credentialRefId,
      folderId,
      tags,
      environment,
      osType,
      keepAliveIntervalSeconds,
      dangerousCommandProtection,
      lastPingLatencyMs,
      lastConnectedAt,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HostRecord &&
          other.id == this.id &&
          other.label == this.label &&
          other.hostname == this.hostname &&
          other.port == this.port &&
          other.username == this.username &&
          other.authType == this.authType &&
          other.credentialRefId == this.credentialRefId &&
          other.folderId == this.folderId &&
          other.tags == this.tags &&
          other.environment == this.environment &&
          other.osType == this.osType &&
          other.keepAliveIntervalSeconds == this.keepAliveIntervalSeconds &&
          other.dangerousCommandProtection == this.dangerousCommandProtection &&
          other.lastPingLatencyMs == this.lastPingLatencyMs &&
          other.lastConnectedAt == this.lastConnectedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class HostsTableCompanion extends UpdateCompanion<HostRecord> {
  final Value<String> id;
  final Value<String> label;
  final Value<String> hostname;
  final Value<int> port;
  final Value<String> username;
  final Value<String> authType;
  final Value<String?> credentialRefId;
  final Value<String?> folderId;
  final Value<String> tags;
  final Value<String> environment;
  final Value<String> osType;
  final Value<int> keepAliveIntervalSeconds;
  final Value<bool> dangerousCommandProtection;
  final Value<int?> lastPingLatencyMs;
  final Value<DateTime?> lastConnectedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const HostsTableCompanion({
    this.id = const Value.absent(),
    this.label = const Value.absent(),
    this.hostname = const Value.absent(),
    this.port = const Value.absent(),
    this.username = const Value.absent(),
    this.authType = const Value.absent(),
    this.credentialRefId = const Value.absent(),
    this.folderId = const Value.absent(),
    this.tags = const Value.absent(),
    this.environment = const Value.absent(),
    this.osType = const Value.absent(),
    this.keepAliveIntervalSeconds = const Value.absent(),
    this.dangerousCommandProtection = const Value.absent(),
    this.lastPingLatencyMs = const Value.absent(),
    this.lastConnectedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HostsTableCompanion.insert({
    required String id,
    required String label,
    required String hostname,
    this.port = const Value.absent(),
    required String username,
    required String authType,
    this.credentialRefId = const Value.absent(),
    this.folderId = const Value.absent(),
    required String tags,
    required String environment,
    required String osType,
    this.keepAliveIntervalSeconds = const Value.absent(),
    this.dangerousCommandProtection = const Value.absent(),
    this.lastPingLatencyMs = const Value.absent(),
    this.lastConnectedAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        label = Value(label),
        hostname = Value(hostname),
        username = Value(username),
        authType = Value(authType),
        tags = Value(tags),
        environment = Value(environment),
        osType = Value(osType),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<HostRecord> custom({
    Expression<String>? id,
    Expression<String>? label,
    Expression<String>? hostname,
    Expression<int>? port,
    Expression<String>? username,
    Expression<String>? authType,
    Expression<String>? credentialRefId,
    Expression<String>? folderId,
    Expression<String>? tags,
    Expression<String>? environment,
    Expression<String>? osType,
    Expression<int>? keepAliveIntervalSeconds,
    Expression<bool>? dangerousCommandProtection,
    Expression<int>? lastPingLatencyMs,
    Expression<DateTime>? lastConnectedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (label != null) 'label': label,
      if (hostname != null) 'hostname': hostname,
      if (port != null) 'port': port,
      if (username != null) 'username': username,
      if (authType != null) 'auth_type': authType,
      if (credentialRefId != null) 'credential_ref_id': credentialRefId,
      if (folderId != null) 'folder_id': folderId,
      if (tags != null) 'tags': tags,
      if (environment != null) 'environment': environment,
      if (osType != null) 'os_type': osType,
      if (keepAliveIntervalSeconds != null)
        'keep_alive_interval_seconds': keepAliveIntervalSeconds,
      if (dangerousCommandProtection != null)
        'dangerous_command_protection': dangerousCommandProtection,
      if (lastPingLatencyMs != null) 'last_ping_latency_ms': lastPingLatencyMs,
      if (lastConnectedAt != null) 'last_connected_at': lastConnectedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HostsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? label,
      Value<String>? hostname,
      Value<int>? port,
      Value<String>? username,
      Value<String>? authType,
      Value<String?>? credentialRefId,
      Value<String?>? folderId,
      Value<String>? tags,
      Value<String>? environment,
      Value<String>? osType,
      Value<int>? keepAliveIntervalSeconds,
      Value<bool>? dangerousCommandProtection,
      Value<int?>? lastPingLatencyMs,
      Value<DateTime?>? lastConnectedAt,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return HostsTableCompanion(
      id: id ?? this.id,
      label: label ?? this.label,
      hostname: hostname ?? this.hostname,
      port: port ?? this.port,
      username: username ?? this.username,
      authType: authType ?? this.authType,
      credentialRefId: credentialRefId ?? this.credentialRefId,
      folderId: folderId ?? this.folderId,
      tags: tags ?? this.tags,
      environment: environment ?? this.environment,
      osType: osType ?? this.osType,
      keepAliveIntervalSeconds:
          keepAliveIntervalSeconds ?? this.keepAliveIntervalSeconds,
      dangerousCommandProtection:
          dangerousCommandProtection ?? this.dangerousCommandProtection,
      lastPingLatencyMs: lastPingLatencyMs ?? this.lastPingLatencyMs,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (hostname.present) {
      map['hostname'] = Variable<String>(hostname.value);
    }
    if (port.present) {
      map['port'] = Variable<int>(port.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (authType.present) {
      map['auth_type'] = Variable<String>(authType.value);
    }
    if (credentialRefId.present) {
      map['credential_ref_id'] = Variable<String>(credentialRefId.value);
    }
    if (folderId.present) {
      map['folder_id'] = Variable<String>(folderId.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (environment.present) {
      map['environment'] = Variable<String>(environment.value);
    }
    if (osType.present) {
      map['os_type'] = Variable<String>(osType.value);
    }
    if (keepAliveIntervalSeconds.present) {
      map['keep_alive_interval_seconds'] =
          Variable<int>(keepAliveIntervalSeconds.value);
    }
    if (dangerousCommandProtection.present) {
      map['dangerous_command_protection'] =
          Variable<bool>(dangerousCommandProtection.value);
    }
    if (lastPingLatencyMs.present) {
      map['last_ping_latency_ms'] = Variable<int>(lastPingLatencyMs.value);
    }
    if (lastConnectedAt.present) {
      map['last_connected_at'] = Variable<DateTime>(lastConnectedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HostsTableCompanion(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('hostname: $hostname, ')
          ..write('port: $port, ')
          ..write('username: $username, ')
          ..write('authType: $authType, ')
          ..write('credentialRefId: $credentialRefId, ')
          ..write('folderId: $folderId, ')
          ..write('tags: $tags, ')
          ..write('environment: $environment, ')
          ..write('osType: $osType, ')
          ..write('keepAliveIntervalSeconds: $keepAliveIntervalSeconds, ')
          ..write('dangerousCommandProtection: $dangerousCommandProtection, ')
          ..write('lastPingLatencyMs: $lastPingLatencyMs, ')
          ..write('lastConnectedAt: $lastConnectedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $KeysTableTable extends KeysTable
    with TableInfo<$KeysTableTable, KeyRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KeysTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
      'label', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _keyTypeMeta =
      const VerificationMeta('keyType');
  @override
  late final GeneratedColumn<String> keyType = GeneratedColumn<String>(
      'key_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _encryptedPrivateKeyMeta =
      const VerificationMeta('encryptedPrivateKey');
  @override
  late final GeneratedColumn<Uint8List> encryptedPrivateKey =
      GeneratedColumn<Uint8List>('encrypted_private_key', aliasedName, false,
          type: DriftSqlType.blob, requiredDuringInsert: true);
  static const VerificationMeta _publicKeyMeta =
      const VerificationMeta('publicKey');
  @override
  late final GeneratedColumn<String> publicKey = GeneratedColumn<String>(
      'public_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _encryptedPassphraseMeta =
      const VerificationMeta('encryptedPassphrase');
  @override
  late final GeneratedColumn<Uint8List> encryptedPassphrase =
      GeneratedColumn<Uint8List>('encrypted_passphrase', aliasedName, true,
          type: DriftSqlType.blob, requiredDuringInsert: false);
  static const VerificationMeta _fingerprintMeta =
      const VerificationMeta('fingerprint');
  @override
  late final GeneratedColumn<String> fingerprint = GeneratedColumn<String>(
      'fingerprint', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        label,
        keyType,
        encryptedPrivateKey,
        publicKey,
        encryptedPassphrase,
        fingerprint,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'keys_table';
  @override
  VerificationContext validateIntegrity(Insertable<KeyRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
          _labelMeta, label.isAcceptableOrUnknown(data['label']!, _labelMeta));
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('key_type')) {
      context.handle(_keyTypeMeta,
          keyType.isAcceptableOrUnknown(data['key_type']!, _keyTypeMeta));
    } else if (isInserting) {
      context.missing(_keyTypeMeta);
    }
    if (data.containsKey('encrypted_private_key')) {
      context.handle(
          _encryptedPrivateKeyMeta,
          encryptedPrivateKey.isAcceptableOrUnknown(
              data['encrypted_private_key']!, _encryptedPrivateKeyMeta));
    } else if (isInserting) {
      context.missing(_encryptedPrivateKeyMeta);
    }
    if (data.containsKey('public_key')) {
      context.handle(_publicKeyMeta,
          publicKey.isAcceptableOrUnknown(data['public_key']!, _publicKeyMeta));
    } else if (isInserting) {
      context.missing(_publicKeyMeta);
    }
    if (data.containsKey('encrypted_passphrase')) {
      context.handle(
          _encryptedPassphraseMeta,
          encryptedPassphrase.isAcceptableOrUnknown(
              data['encrypted_passphrase']!, _encryptedPassphraseMeta));
    }
    if (data.containsKey('fingerprint')) {
      context.handle(
          _fingerprintMeta,
          fingerprint.isAcceptableOrUnknown(
              data['fingerprint']!, _fingerprintMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  KeyRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KeyRecord(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      label: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}label'])!,
      keyType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key_type'])!,
      encryptedPrivateKey: attachedDatabase.typeMapping.read(
          DriftSqlType.blob, data['${effectivePrefix}encrypted_private_key'])!,
      publicKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}public_key'])!,
      encryptedPassphrase: attachedDatabase.typeMapping.read(
          DriftSqlType.blob, data['${effectivePrefix}encrypted_passphrase']),
      fingerprint: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}fingerprint']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $KeysTableTable createAlias(String alias) {
    return $KeysTableTable(attachedDatabase, alias);
  }
}

class KeyRecord extends DataClass implements Insertable<KeyRecord> {
  final String id;
  final String label;
  final String keyType;
  final Uint8List encryptedPrivateKey;
  final String publicKey;
  final Uint8List? encryptedPassphrase;
  final String? fingerprint;
  final DateTime createdAt;
  final DateTime updatedAt;
  const KeyRecord(
      {required this.id,
      required this.label,
      required this.keyType,
      required this.encryptedPrivateKey,
      required this.publicKey,
      this.encryptedPassphrase,
      this.fingerprint,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['label'] = Variable<String>(label);
    map['key_type'] = Variable<String>(keyType);
    map['encrypted_private_key'] = Variable<Uint8List>(encryptedPrivateKey);
    map['public_key'] = Variable<String>(publicKey);
    if (!nullToAbsent || encryptedPassphrase != null) {
      map['encrypted_passphrase'] = Variable<Uint8List>(encryptedPassphrase);
    }
    if (!nullToAbsent || fingerprint != null) {
      map['fingerprint'] = Variable<String>(fingerprint);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  KeysTableCompanion toCompanion(bool nullToAbsent) {
    return KeysTableCompanion(
      id: Value(id),
      label: Value(label),
      keyType: Value(keyType),
      encryptedPrivateKey: Value(encryptedPrivateKey),
      publicKey: Value(publicKey),
      encryptedPassphrase: encryptedPassphrase == null && nullToAbsent
          ? const Value.absent()
          : Value(encryptedPassphrase),
      fingerprint: fingerprint == null && nullToAbsent
          ? const Value.absent()
          : Value(fingerprint),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory KeyRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KeyRecord(
      id: serializer.fromJson<String>(json['id']),
      label: serializer.fromJson<String>(json['label']),
      keyType: serializer.fromJson<String>(json['keyType']),
      encryptedPrivateKey:
          serializer.fromJson<Uint8List>(json['encryptedPrivateKey']),
      publicKey: serializer.fromJson<String>(json['publicKey']),
      encryptedPassphrase:
          serializer.fromJson<Uint8List?>(json['encryptedPassphrase']),
      fingerprint: serializer.fromJson<String?>(json['fingerprint']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'label': serializer.toJson<String>(label),
      'keyType': serializer.toJson<String>(keyType),
      'encryptedPrivateKey': serializer.toJson<Uint8List>(encryptedPrivateKey),
      'publicKey': serializer.toJson<String>(publicKey),
      'encryptedPassphrase': serializer.toJson<Uint8List?>(encryptedPassphrase),
      'fingerprint': serializer.toJson<String?>(fingerprint),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  KeyRecord copyWith(
          {String? id,
          String? label,
          String? keyType,
          Uint8List? encryptedPrivateKey,
          String? publicKey,
          Value<Uint8List?> encryptedPassphrase = const Value.absent(),
          Value<String?> fingerprint = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      KeyRecord(
        id: id ?? this.id,
        label: label ?? this.label,
        keyType: keyType ?? this.keyType,
        encryptedPrivateKey: encryptedPrivateKey ?? this.encryptedPrivateKey,
        publicKey: publicKey ?? this.publicKey,
        encryptedPassphrase: encryptedPassphrase.present
            ? encryptedPassphrase.value
            : this.encryptedPassphrase,
        fingerprint: fingerprint.present ? fingerprint.value : this.fingerprint,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  KeyRecord copyWithCompanion(KeysTableCompanion data) {
    return KeyRecord(
      id: data.id.present ? data.id.value : this.id,
      label: data.label.present ? data.label.value : this.label,
      keyType: data.keyType.present ? data.keyType.value : this.keyType,
      encryptedPrivateKey: data.encryptedPrivateKey.present
          ? data.encryptedPrivateKey.value
          : this.encryptedPrivateKey,
      publicKey: data.publicKey.present ? data.publicKey.value : this.publicKey,
      encryptedPassphrase: data.encryptedPassphrase.present
          ? data.encryptedPassphrase.value
          : this.encryptedPassphrase,
      fingerprint:
          data.fingerprint.present ? data.fingerprint.value : this.fingerprint,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KeyRecord(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('keyType: $keyType, ')
          ..write('encryptedPrivateKey: $encryptedPrivateKey, ')
          ..write('publicKey: $publicKey, ')
          ..write('encryptedPassphrase: $encryptedPassphrase, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      label,
      keyType,
      $driftBlobEquality.hash(encryptedPrivateKey),
      publicKey,
      $driftBlobEquality.hash(encryptedPassphrase),
      fingerprint,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KeyRecord &&
          other.id == this.id &&
          other.label == this.label &&
          other.keyType == this.keyType &&
          $driftBlobEquality.equals(
              other.encryptedPrivateKey, this.encryptedPrivateKey) &&
          other.publicKey == this.publicKey &&
          $driftBlobEquality.equals(
              other.encryptedPassphrase, this.encryptedPassphrase) &&
          other.fingerprint == this.fingerprint &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class KeysTableCompanion extends UpdateCompanion<KeyRecord> {
  final Value<String> id;
  final Value<String> label;
  final Value<String> keyType;
  final Value<Uint8List> encryptedPrivateKey;
  final Value<String> publicKey;
  final Value<Uint8List?> encryptedPassphrase;
  final Value<String?> fingerprint;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const KeysTableCompanion({
    this.id = const Value.absent(),
    this.label = const Value.absent(),
    this.keyType = const Value.absent(),
    this.encryptedPrivateKey = const Value.absent(),
    this.publicKey = const Value.absent(),
    this.encryptedPassphrase = const Value.absent(),
    this.fingerprint = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KeysTableCompanion.insert({
    required String id,
    required String label,
    required String keyType,
    required Uint8List encryptedPrivateKey,
    required String publicKey,
    this.encryptedPassphrase = const Value.absent(),
    this.fingerprint = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        label = Value(label),
        keyType = Value(keyType),
        encryptedPrivateKey = Value(encryptedPrivateKey),
        publicKey = Value(publicKey),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<KeyRecord> custom({
    Expression<String>? id,
    Expression<String>? label,
    Expression<String>? keyType,
    Expression<Uint8List>? encryptedPrivateKey,
    Expression<String>? publicKey,
    Expression<Uint8List>? encryptedPassphrase,
    Expression<String>? fingerprint,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (label != null) 'label': label,
      if (keyType != null) 'key_type': keyType,
      if (encryptedPrivateKey != null)
        'encrypted_private_key': encryptedPrivateKey,
      if (publicKey != null) 'public_key': publicKey,
      if (encryptedPassphrase != null)
        'encrypted_passphrase': encryptedPassphrase,
      if (fingerprint != null) 'fingerprint': fingerprint,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KeysTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? label,
      Value<String>? keyType,
      Value<Uint8List>? encryptedPrivateKey,
      Value<String>? publicKey,
      Value<Uint8List?>? encryptedPassphrase,
      Value<String?>? fingerprint,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return KeysTableCompanion(
      id: id ?? this.id,
      label: label ?? this.label,
      keyType: keyType ?? this.keyType,
      encryptedPrivateKey: encryptedPrivateKey ?? this.encryptedPrivateKey,
      publicKey: publicKey ?? this.publicKey,
      encryptedPassphrase: encryptedPassphrase ?? this.encryptedPassphrase,
      fingerprint: fingerprint ?? this.fingerprint,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (keyType.present) {
      map['key_type'] = Variable<String>(keyType.value);
    }
    if (encryptedPrivateKey.present) {
      map['encrypted_private_key'] =
          Variable<Uint8List>(encryptedPrivateKey.value);
    }
    if (publicKey.present) {
      map['public_key'] = Variable<String>(publicKey.value);
    }
    if (encryptedPassphrase.present) {
      map['encrypted_passphrase'] =
          Variable<Uint8List>(encryptedPassphrase.value);
    }
    if (fingerprint.present) {
      map['fingerprint'] = Variable<String>(fingerprint.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KeysTableCompanion(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('keyType: $keyType, ')
          ..write('encryptedPrivateKey: $encryptedPrivateKey, ')
          ..write('publicKey: $publicKey, ')
          ..write('encryptedPassphrase: $encryptedPassphrase, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FoldersTableTable extends FoldersTable
    with TableInfo<$FoldersTableTable, FolderRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoldersTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _parentIdMeta =
      const VerificationMeta('parentId');
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
      'parent_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _colorHexMeta =
      const VerificationMeta('colorHex');
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
      'color_hex', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _iconNameMeta =
      const VerificationMeta('iconName');
  @override
  late final GeneratedColumn<String> iconName = GeneratedColumn<String>(
      'icon_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, parentId, colorHex, iconName, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'folders_table';
  @override
  VerificationContext validateIntegrity(Insertable<FolderRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(_parentIdMeta,
          parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta));
    }
    if (data.containsKey('color_hex')) {
      context.handle(_colorHexMeta,
          colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta));
    }
    if (data.containsKey('icon_name')) {
      context.handle(_iconNameMeta,
          iconName.isAcceptableOrUnknown(data['icon_name']!, _iconNameMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FolderRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FolderRecord(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      parentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}parent_id']),
      colorHex: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color_hex']),
      iconName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon_name']),
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
    );
  }

  @override
  $FoldersTableTable createAlias(String alias) {
    return $FoldersTableTable(attachedDatabase, alias);
  }
}

class FolderRecord extends DataClass implements Insertable<FolderRecord> {
  final String id;
  final String name;
  final String? parentId;
  final String? colorHex;
  final String? iconName;
  final int sortOrder;
  const FolderRecord(
      {required this.id,
      required this.name,
      this.parentId,
      this.colorHex,
      this.iconName,
      required this.sortOrder});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    if (!nullToAbsent || colorHex != null) {
      map['color_hex'] = Variable<String>(colorHex);
    }
    if (!nullToAbsent || iconName != null) {
      map['icon_name'] = Variable<String>(iconName);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  FoldersTableCompanion toCompanion(bool nullToAbsent) {
    return FoldersTableCompanion(
      id: Value(id),
      name: Value(name),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      colorHex: colorHex == null && nullToAbsent
          ? const Value.absent()
          : Value(colorHex),
      iconName: iconName == null && nullToAbsent
          ? const Value.absent()
          : Value(iconName),
      sortOrder: Value(sortOrder),
    );
  }

  factory FolderRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FolderRecord(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      colorHex: serializer.fromJson<String?>(json['colorHex']),
      iconName: serializer.fromJson<String?>(json['iconName']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'parentId': serializer.toJson<String?>(parentId),
      'colorHex': serializer.toJson<String?>(colorHex),
      'iconName': serializer.toJson<String?>(iconName),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  FolderRecord copyWith(
          {String? id,
          String? name,
          Value<String?> parentId = const Value.absent(),
          Value<String?> colorHex = const Value.absent(),
          Value<String?> iconName = const Value.absent(),
          int? sortOrder}) =>
      FolderRecord(
        id: id ?? this.id,
        name: name ?? this.name,
        parentId: parentId.present ? parentId.value : this.parentId,
        colorHex: colorHex.present ? colorHex.value : this.colorHex,
        iconName: iconName.present ? iconName.value : this.iconName,
        sortOrder: sortOrder ?? this.sortOrder,
      );
  FolderRecord copyWithCompanion(FoldersTableCompanion data) {
    return FolderRecord(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      iconName: data.iconName.present ? data.iconName.value : this.iconName,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FolderRecord(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('parentId: $parentId, ')
          ..write('colorHex: $colorHex, ')
          ..write('iconName: $iconName, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, parentId, colorHex, iconName, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FolderRecord &&
          other.id == this.id &&
          other.name == this.name &&
          other.parentId == this.parentId &&
          other.colorHex == this.colorHex &&
          other.iconName == this.iconName &&
          other.sortOrder == this.sortOrder);
}

class FoldersTableCompanion extends UpdateCompanion<FolderRecord> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> parentId;
  final Value<String?> colorHex;
  final Value<String?> iconName;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const FoldersTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.parentId = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.iconName = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FoldersTableCompanion.insert({
    required String id,
    required String name,
    this.parentId = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.iconName = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name);
  static Insertable<FolderRecord> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? parentId,
    Expression<String>? colorHex,
    Expression<String>? iconName,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (parentId != null) 'parent_id': parentId,
      if (colorHex != null) 'color_hex': colorHex,
      if (iconName != null) 'icon_name': iconName,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FoldersTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String?>? parentId,
      Value<String?>? colorHex,
      Value<String?>? iconName,
      Value<int>? sortOrder,
      Value<int>? rowid}) {
    return FoldersTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      colorHex: colorHex ?? this.colorHex,
      iconName: iconName ?? this.iconName,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (iconName.present) {
      map['icon_name'] = Variable<String>(iconName.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoldersTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('parentId: $parentId, ')
          ..write('colorHex: $colorHex, ')
          ..write('iconName: $iconName, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SnippetsTableTable extends SnippetsTable
    with TableInfo<$SnippetsTableTable, SnippetRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SnippetsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _commandMeta =
      const VerificationMeta('command');
  @override
  late final GeneratedColumn<String> command = GeneratedColumn<String>(
      'command', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
      'tags', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _folderIdMeta =
      const VerificationMeta('folderId');
  @override
  late final GeneratedColumn<String> folderId = GeneratedColumn<String>(
      'folder_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, title, command, description, tags, folderId, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'snippets_table';
  @override
  VerificationContext validateIntegrity(Insertable<SnippetRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('command')) {
      context.handle(_commandMeta,
          command.isAcceptableOrUnknown(data['command']!, _commandMeta));
    } else if (isInserting) {
      context.missing(_commandMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('tags')) {
      context.handle(
          _tagsMeta, tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta));
    } else if (isInserting) {
      context.missing(_tagsMeta);
    }
    if (data.containsKey('folder_id')) {
      context.handle(_folderIdMeta,
          folderId.isAcceptableOrUnknown(data['folder_id']!, _folderIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SnippetRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SnippetRecord(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      command: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}command'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      tags: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tags'])!,
      folderId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}folder_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $SnippetsTableTable createAlias(String alias) {
    return $SnippetsTableTable(attachedDatabase, alias);
  }
}

class SnippetRecord extends DataClass implements Insertable<SnippetRecord> {
  final String id;
  final String title;
  final String command;
  final String? description;
  final String tags;
  final String? folderId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SnippetRecord(
      {required this.id,
      required this.title,
      required this.command,
      this.description,
      required this.tags,
      this.folderId,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['command'] = Variable<String>(command);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['tags'] = Variable<String>(tags);
    if (!nullToAbsent || folderId != null) {
      map['folder_id'] = Variable<String>(folderId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SnippetsTableCompanion toCompanion(bool nullToAbsent) {
    return SnippetsTableCompanion(
      id: Value(id),
      title: Value(title),
      command: Value(command),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      tags: Value(tags),
      folderId: folderId == null && nullToAbsent
          ? const Value.absent()
          : Value(folderId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SnippetRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SnippetRecord(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      command: serializer.fromJson<String>(json['command']),
      description: serializer.fromJson<String?>(json['description']),
      tags: serializer.fromJson<String>(json['tags']),
      folderId: serializer.fromJson<String?>(json['folderId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'command': serializer.toJson<String>(command),
      'description': serializer.toJson<String?>(description),
      'tags': serializer.toJson<String>(tags),
      'folderId': serializer.toJson<String?>(folderId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SnippetRecord copyWith(
          {String? id,
          String? title,
          String? command,
          Value<String?> description = const Value.absent(),
          String? tags,
          Value<String?> folderId = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      SnippetRecord(
        id: id ?? this.id,
        title: title ?? this.title,
        command: command ?? this.command,
        description: description.present ? description.value : this.description,
        tags: tags ?? this.tags,
        folderId: folderId.present ? folderId.value : this.folderId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  SnippetRecord copyWithCompanion(SnippetsTableCompanion data) {
    return SnippetRecord(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      command: data.command.present ? data.command.value : this.command,
      description:
          data.description.present ? data.description.value : this.description,
      tags: data.tags.present ? data.tags.value : this.tags,
      folderId: data.folderId.present ? data.folderId.value : this.folderId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SnippetRecord(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('command: $command, ')
          ..write('description: $description, ')
          ..write('tags: $tags, ')
          ..write('folderId: $folderId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, title, command, description, tags, folderId, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SnippetRecord &&
          other.id == this.id &&
          other.title == this.title &&
          other.command == this.command &&
          other.description == this.description &&
          other.tags == this.tags &&
          other.folderId == this.folderId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SnippetsTableCompanion extends UpdateCompanion<SnippetRecord> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> command;
  final Value<String?> description;
  final Value<String> tags;
  final Value<String?> folderId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SnippetsTableCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.command = const Value.absent(),
    this.description = const Value.absent(),
    this.tags = const Value.absent(),
    this.folderId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SnippetsTableCompanion.insert({
    required String id,
    required String title,
    required String command,
    this.description = const Value.absent(),
    required String tags,
    this.folderId = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        command = Value(command),
        tags = Value(tags),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<SnippetRecord> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? command,
    Expression<String>? description,
    Expression<String>? tags,
    Expression<String>? folderId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (command != null) 'command': command,
      if (description != null) 'description': description,
      if (tags != null) 'tags': tags,
      if (folderId != null) 'folder_id': folderId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SnippetsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<String>? command,
      Value<String?>? description,
      Value<String>? tags,
      Value<String?>? folderId,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return SnippetsTableCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      command: command ?? this.command,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      folderId: folderId ?? this.folderId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (command.present) {
      map['command'] = Variable<String>(command.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (folderId.present) {
      map['folder_id'] = Variable<String>(folderId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SnippetsTableCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('command: $command, ')
          ..write('description: $description, ')
          ..write('tags: $tags, ')
          ..write('folderId: $folderId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VaultSettingsTableTable extends VaultSettingsTable
    with TableInfo<$VaultSettingsTableTable, VaultSettingsRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VaultSettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _idleLockTimeoutMinutesMeta =
      const VerificationMeta('idleLockTimeoutMinutes');
  @override
  late final GeneratedColumn<int> idleLockTimeoutMinutes = GeneratedColumn<int>(
      'idle_lock_timeout_minutes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(15));
  static const VerificationMeta _isBiometricsEnabledMeta =
      const VerificationMeta('isBiometricsEnabled');
  @override
  late final GeneratedColumn<bool> isBiometricsEnabled = GeneratedColumn<bool>(
      'is_biometrics_enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_biometrics_enabled" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isPinEnabledMeta =
      const VerificationMeta('isPinEnabled');
  @override
  late final GeneratedColumn<bool> isPinEnabled = GeneratedColumn<bool>(
      'is_pin_enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_pin_enabled" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _themeIdMeta =
      const VerificationMeta('themeId');
  @override
  late final GeneratedColumn<String> themeId = GeneratedColumn<String>(
      'theme_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('deep_slate'));
  static const VerificationMeta _terminalFontFamilyMeta =
      const VerificationMeta('terminalFontFamily');
  @override
  late final GeneratedColumn<String> terminalFontFamily =
      GeneratedColumn<String>('terminal_font_family', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('JetBrains Mono'));
  static const VerificationMeta _terminalFontSizeMeta =
      const VerificationMeta('terminalFontSize');
  @override
  late final GeneratedColumn<double> terminalFontSize = GeneratedColumn<double>(
      'terminal_font_size', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(14.0));
  static const VerificationMeta _enableLiveLatencyPingMeta =
      const VerificationMeta('enableLiveLatencyPing');
  @override
  late final GeneratedColumn<bool> enableLiveLatencyPing =
      GeneratedColumn<bool>('enable_live_latency_ping', aliasedName, false,
          type: DriftSqlType.bool,
          requiredDuringInsert: false,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'CHECK ("enable_live_latency_ping" IN (0, 1))'),
          defaultValue: const Constant(true));
  static const VerificationMeta _pingIntervalSecondsMeta =
      const VerificationMeta('pingIntervalSeconds');
  @override
  late final GeneratedColumn<int> pingIntervalSeconds = GeneratedColumn<int>(
      'ping_interval_seconds', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(45));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        idleLockTimeoutMinutes,
        isBiometricsEnabled,
        isPinEnabled,
        themeId,
        terminalFontFamily,
        terminalFontSize,
        enableLiveLatencyPing,
        pingIntervalSeconds
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vault_settings_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<VaultSettingsRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('idle_lock_timeout_minutes')) {
      context.handle(
          _idleLockTimeoutMinutesMeta,
          idleLockTimeoutMinutes.isAcceptableOrUnknown(
              data['idle_lock_timeout_minutes']!, _idleLockTimeoutMinutesMeta));
    }
    if (data.containsKey('is_biometrics_enabled')) {
      context.handle(
          _isBiometricsEnabledMeta,
          isBiometricsEnabled.isAcceptableOrUnknown(
              data['is_biometrics_enabled']!, _isBiometricsEnabledMeta));
    }
    if (data.containsKey('is_pin_enabled')) {
      context.handle(
          _isPinEnabledMeta,
          isPinEnabled.isAcceptableOrUnknown(
              data['is_pin_enabled']!, _isPinEnabledMeta));
    }
    if (data.containsKey('theme_id')) {
      context.handle(_themeIdMeta,
          themeId.isAcceptableOrUnknown(data['theme_id']!, _themeIdMeta));
    }
    if (data.containsKey('terminal_font_family')) {
      context.handle(
          _terminalFontFamilyMeta,
          terminalFontFamily.isAcceptableOrUnknown(
              data['terminal_font_family']!, _terminalFontFamilyMeta));
    }
    if (data.containsKey('terminal_font_size')) {
      context.handle(
          _terminalFontSizeMeta,
          terminalFontSize.isAcceptableOrUnknown(
              data['terminal_font_size']!, _terminalFontSizeMeta));
    }
    if (data.containsKey('enable_live_latency_ping')) {
      context.handle(
          _enableLiveLatencyPingMeta,
          enableLiveLatencyPing.isAcceptableOrUnknown(
              data['enable_live_latency_ping']!, _enableLiveLatencyPingMeta));
    }
    if (data.containsKey('ping_interval_seconds')) {
      context.handle(
          _pingIntervalSecondsMeta,
          pingIntervalSeconds.isAcceptableOrUnknown(
              data['ping_interval_seconds']!, _pingIntervalSecondsMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VaultSettingsRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VaultSettingsRecord(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      idleLockTimeoutMinutes: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}idle_lock_timeout_minutes'])!,
      isBiometricsEnabled: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}is_biometrics_enabled'])!,
      isPinEnabled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_pin_enabled'])!,
      themeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}theme_id'])!,
      terminalFontFamily: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}terminal_font_family'])!,
      terminalFontSize: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}terminal_font_size'])!,
      enableLiveLatencyPing: attachedDatabase.typeMapping.read(
          DriftSqlType.bool,
          data['${effectivePrefix}enable_live_latency_ping'])!,
      pingIntervalSeconds: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}ping_interval_seconds'])!,
    );
  }

  @override
  $VaultSettingsTableTable createAlias(String alias) {
    return $VaultSettingsTableTable(attachedDatabase, alias);
  }
}

class VaultSettingsRecord extends DataClass
    implements Insertable<VaultSettingsRecord> {
  final int id;
  final int idleLockTimeoutMinutes;
  final bool isBiometricsEnabled;
  final bool isPinEnabled;
  final String themeId;
  final String terminalFontFamily;
  final double terminalFontSize;
  final bool enableLiveLatencyPing;
  final int pingIntervalSeconds;
  const VaultSettingsRecord(
      {required this.id,
      required this.idleLockTimeoutMinutes,
      required this.isBiometricsEnabled,
      required this.isPinEnabled,
      required this.themeId,
      required this.terminalFontFamily,
      required this.terminalFontSize,
      required this.enableLiveLatencyPing,
      required this.pingIntervalSeconds});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['idle_lock_timeout_minutes'] = Variable<int>(idleLockTimeoutMinutes);
    map['is_biometrics_enabled'] = Variable<bool>(isBiometricsEnabled);
    map['is_pin_enabled'] = Variable<bool>(isPinEnabled);
    map['theme_id'] = Variable<String>(themeId);
    map['terminal_font_family'] = Variable<String>(terminalFontFamily);
    map['terminal_font_size'] = Variable<double>(terminalFontSize);
    map['enable_live_latency_ping'] = Variable<bool>(enableLiveLatencyPing);
    map['ping_interval_seconds'] = Variable<int>(pingIntervalSeconds);
    return map;
  }

  VaultSettingsTableCompanion toCompanion(bool nullToAbsent) {
    return VaultSettingsTableCompanion(
      id: Value(id),
      idleLockTimeoutMinutes: Value(idleLockTimeoutMinutes),
      isBiometricsEnabled: Value(isBiometricsEnabled),
      isPinEnabled: Value(isPinEnabled),
      themeId: Value(themeId),
      terminalFontFamily: Value(terminalFontFamily),
      terminalFontSize: Value(terminalFontSize),
      enableLiveLatencyPing: Value(enableLiveLatencyPing),
      pingIntervalSeconds: Value(pingIntervalSeconds),
    );
  }

  factory VaultSettingsRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VaultSettingsRecord(
      id: serializer.fromJson<int>(json['id']),
      idleLockTimeoutMinutes:
          serializer.fromJson<int>(json['idleLockTimeoutMinutes']),
      isBiometricsEnabled:
          serializer.fromJson<bool>(json['isBiometricsEnabled']),
      isPinEnabled: serializer.fromJson<bool>(json['isPinEnabled']),
      themeId: serializer.fromJson<String>(json['themeId']),
      terminalFontFamily:
          serializer.fromJson<String>(json['terminalFontFamily']),
      terminalFontSize: serializer.fromJson<double>(json['terminalFontSize']),
      enableLiveLatencyPing:
          serializer.fromJson<bool>(json['enableLiveLatencyPing']),
      pingIntervalSeconds:
          serializer.fromJson<int>(json['pingIntervalSeconds']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'idleLockTimeoutMinutes': serializer.toJson<int>(idleLockTimeoutMinutes),
      'isBiometricsEnabled': serializer.toJson<bool>(isBiometricsEnabled),
      'isPinEnabled': serializer.toJson<bool>(isPinEnabled),
      'themeId': serializer.toJson<String>(themeId),
      'terminalFontFamily': serializer.toJson<String>(terminalFontFamily),
      'terminalFontSize': serializer.toJson<double>(terminalFontSize),
      'enableLiveLatencyPing': serializer.toJson<bool>(enableLiveLatencyPing),
      'pingIntervalSeconds': serializer.toJson<int>(pingIntervalSeconds),
    };
  }

  VaultSettingsRecord copyWith(
          {int? id,
          int? idleLockTimeoutMinutes,
          bool? isBiometricsEnabled,
          bool? isPinEnabled,
          String? themeId,
          String? terminalFontFamily,
          double? terminalFontSize,
          bool? enableLiveLatencyPing,
          int? pingIntervalSeconds}) =>
      VaultSettingsRecord(
        id: id ?? this.id,
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
      );
  VaultSettingsRecord copyWithCompanion(VaultSettingsTableCompanion data) {
    return VaultSettingsRecord(
      id: data.id.present ? data.id.value : this.id,
      idleLockTimeoutMinutes: data.idleLockTimeoutMinutes.present
          ? data.idleLockTimeoutMinutes.value
          : this.idleLockTimeoutMinutes,
      isBiometricsEnabled: data.isBiometricsEnabled.present
          ? data.isBiometricsEnabled.value
          : this.isBiometricsEnabled,
      isPinEnabled: data.isPinEnabled.present
          ? data.isPinEnabled.value
          : this.isPinEnabled,
      themeId: data.themeId.present ? data.themeId.value : this.themeId,
      terminalFontFamily: data.terminalFontFamily.present
          ? data.terminalFontFamily.value
          : this.terminalFontFamily,
      terminalFontSize: data.terminalFontSize.present
          ? data.terminalFontSize.value
          : this.terminalFontSize,
      enableLiveLatencyPing: data.enableLiveLatencyPing.present
          ? data.enableLiveLatencyPing.value
          : this.enableLiveLatencyPing,
      pingIntervalSeconds: data.pingIntervalSeconds.present
          ? data.pingIntervalSeconds.value
          : this.pingIntervalSeconds,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VaultSettingsRecord(')
          ..write('id: $id, ')
          ..write('idleLockTimeoutMinutes: $idleLockTimeoutMinutes, ')
          ..write('isBiometricsEnabled: $isBiometricsEnabled, ')
          ..write('isPinEnabled: $isPinEnabled, ')
          ..write('themeId: $themeId, ')
          ..write('terminalFontFamily: $terminalFontFamily, ')
          ..write('terminalFontSize: $terminalFontSize, ')
          ..write('enableLiveLatencyPing: $enableLiveLatencyPing, ')
          ..write('pingIntervalSeconds: $pingIntervalSeconds')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      idleLockTimeoutMinutes,
      isBiometricsEnabled,
      isPinEnabled,
      themeId,
      terminalFontFamily,
      terminalFontSize,
      enableLiveLatencyPing,
      pingIntervalSeconds);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VaultSettingsRecord &&
          other.id == this.id &&
          other.idleLockTimeoutMinutes == this.idleLockTimeoutMinutes &&
          other.isBiometricsEnabled == this.isBiometricsEnabled &&
          other.isPinEnabled == this.isPinEnabled &&
          other.themeId == this.themeId &&
          other.terminalFontFamily == this.terminalFontFamily &&
          other.terminalFontSize == this.terminalFontSize &&
          other.enableLiveLatencyPing == this.enableLiveLatencyPing &&
          other.pingIntervalSeconds == this.pingIntervalSeconds);
}

class VaultSettingsTableCompanion extends UpdateCompanion<VaultSettingsRecord> {
  final Value<int> id;
  final Value<int> idleLockTimeoutMinutes;
  final Value<bool> isBiometricsEnabled;
  final Value<bool> isPinEnabled;
  final Value<String> themeId;
  final Value<String> terminalFontFamily;
  final Value<double> terminalFontSize;
  final Value<bool> enableLiveLatencyPing;
  final Value<int> pingIntervalSeconds;
  const VaultSettingsTableCompanion({
    this.id = const Value.absent(),
    this.idleLockTimeoutMinutes = const Value.absent(),
    this.isBiometricsEnabled = const Value.absent(),
    this.isPinEnabled = const Value.absent(),
    this.themeId = const Value.absent(),
    this.terminalFontFamily = const Value.absent(),
    this.terminalFontSize = const Value.absent(),
    this.enableLiveLatencyPing = const Value.absent(),
    this.pingIntervalSeconds = const Value.absent(),
  });
  VaultSettingsTableCompanion.insert({
    this.id = const Value.absent(),
    this.idleLockTimeoutMinutes = const Value.absent(),
    this.isBiometricsEnabled = const Value.absent(),
    this.isPinEnabled = const Value.absent(),
    this.themeId = const Value.absent(),
    this.terminalFontFamily = const Value.absent(),
    this.terminalFontSize = const Value.absent(),
    this.enableLiveLatencyPing = const Value.absent(),
    this.pingIntervalSeconds = const Value.absent(),
  });
  static Insertable<VaultSettingsRecord> custom({
    Expression<int>? id,
    Expression<int>? idleLockTimeoutMinutes,
    Expression<bool>? isBiometricsEnabled,
    Expression<bool>? isPinEnabled,
    Expression<String>? themeId,
    Expression<String>? terminalFontFamily,
    Expression<double>? terminalFontSize,
    Expression<bool>? enableLiveLatencyPing,
    Expression<int>? pingIntervalSeconds,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (idleLockTimeoutMinutes != null)
        'idle_lock_timeout_minutes': idleLockTimeoutMinutes,
      if (isBiometricsEnabled != null)
        'is_biometrics_enabled': isBiometricsEnabled,
      if (isPinEnabled != null) 'is_pin_enabled': isPinEnabled,
      if (themeId != null) 'theme_id': themeId,
      if (terminalFontFamily != null)
        'terminal_font_family': terminalFontFamily,
      if (terminalFontSize != null) 'terminal_font_size': terminalFontSize,
      if (enableLiveLatencyPing != null)
        'enable_live_latency_ping': enableLiveLatencyPing,
      if (pingIntervalSeconds != null)
        'ping_interval_seconds': pingIntervalSeconds,
    });
  }

  VaultSettingsTableCompanion copyWith(
      {Value<int>? id,
      Value<int>? idleLockTimeoutMinutes,
      Value<bool>? isBiometricsEnabled,
      Value<bool>? isPinEnabled,
      Value<String>? themeId,
      Value<String>? terminalFontFamily,
      Value<double>? terminalFontSize,
      Value<bool>? enableLiveLatencyPing,
      Value<int>? pingIntervalSeconds}) {
    return VaultSettingsTableCompanion(
      id: id ?? this.id,
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
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (idleLockTimeoutMinutes.present) {
      map['idle_lock_timeout_minutes'] =
          Variable<int>(idleLockTimeoutMinutes.value);
    }
    if (isBiometricsEnabled.present) {
      map['is_biometrics_enabled'] = Variable<bool>(isBiometricsEnabled.value);
    }
    if (isPinEnabled.present) {
      map['is_pin_enabled'] = Variable<bool>(isPinEnabled.value);
    }
    if (themeId.present) {
      map['theme_id'] = Variable<String>(themeId.value);
    }
    if (terminalFontFamily.present) {
      map['terminal_font_family'] = Variable<String>(terminalFontFamily.value);
    }
    if (terminalFontSize.present) {
      map['terminal_font_size'] = Variable<double>(terminalFontSize.value);
    }
    if (enableLiveLatencyPing.present) {
      map['enable_live_latency_ping'] =
          Variable<bool>(enableLiveLatencyPing.value);
    }
    if (pingIntervalSeconds.present) {
      map['ping_interval_seconds'] = Variable<int>(pingIntervalSeconds.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VaultSettingsTableCompanion(')
          ..write('id: $id, ')
          ..write('idleLockTimeoutMinutes: $idleLockTimeoutMinutes, ')
          ..write('isBiometricsEnabled: $isBiometricsEnabled, ')
          ..write('isPinEnabled: $isPinEnabled, ')
          ..write('themeId: $themeId, ')
          ..write('terminalFontFamily: $terminalFontFamily, ')
          ..write('terminalFontSize: $terminalFontSize, ')
          ..write('enableLiveLatencyPing: $enableLiveLatencyPing, ')
          ..write('pingIntervalSeconds: $pingIntervalSeconds')
          ..write(')'))
        .toString();
  }
}

class $VaultMetadataTableTable extends VaultMetadataTable
    with TableInfo<$VaultMetadataTableTable, VaultMetaRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VaultMetadataTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _metaKeyMeta =
      const VerificationMeta('metaKey');
  @override
  late final GeneratedColumn<String> metaKey = GeneratedColumn<String>(
      'meta_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _metaValueMeta =
      const VerificationMeta('metaValue');
  @override
  late final GeneratedColumn<String> metaValue = GeneratedColumn<String>(
      'meta_value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [metaKey, metaValue];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vault_metadata_table';
  @override
  VerificationContext validateIntegrity(Insertable<VaultMetaRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('meta_key')) {
      context.handle(_metaKeyMeta,
          metaKey.isAcceptableOrUnknown(data['meta_key']!, _metaKeyMeta));
    } else if (isInserting) {
      context.missing(_metaKeyMeta);
    }
    if (data.containsKey('meta_value')) {
      context.handle(_metaValueMeta,
          metaValue.isAcceptableOrUnknown(data['meta_value']!, _metaValueMeta));
    } else if (isInserting) {
      context.missing(_metaValueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {metaKey};
  @override
  VaultMetaRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VaultMetaRecord(
      metaKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}meta_key'])!,
      metaValue: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}meta_value'])!,
    );
  }

  @override
  $VaultMetadataTableTable createAlias(String alias) {
    return $VaultMetadataTableTable(attachedDatabase, alias);
  }
}

class VaultMetaRecord extends DataClass implements Insertable<VaultMetaRecord> {
  final String metaKey;
  final String metaValue;
  const VaultMetaRecord({required this.metaKey, required this.metaValue});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['meta_key'] = Variable<String>(metaKey);
    map['meta_value'] = Variable<String>(metaValue);
    return map;
  }

  VaultMetadataTableCompanion toCompanion(bool nullToAbsent) {
    return VaultMetadataTableCompanion(
      metaKey: Value(metaKey),
      metaValue: Value(metaValue),
    );
  }

  factory VaultMetaRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VaultMetaRecord(
      metaKey: serializer.fromJson<String>(json['metaKey']),
      metaValue: serializer.fromJson<String>(json['metaValue']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'metaKey': serializer.toJson<String>(metaKey),
      'metaValue': serializer.toJson<String>(metaValue),
    };
  }

  VaultMetaRecord copyWith({String? metaKey, String? metaValue}) =>
      VaultMetaRecord(
        metaKey: metaKey ?? this.metaKey,
        metaValue: metaValue ?? this.metaValue,
      );
  VaultMetaRecord copyWithCompanion(VaultMetadataTableCompanion data) {
    return VaultMetaRecord(
      metaKey: data.metaKey.present ? data.metaKey.value : this.metaKey,
      metaValue: data.metaValue.present ? data.metaValue.value : this.metaValue,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VaultMetaRecord(')
          ..write('metaKey: $metaKey, ')
          ..write('metaValue: $metaValue')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(metaKey, metaValue);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VaultMetaRecord &&
          other.metaKey == this.metaKey &&
          other.metaValue == this.metaValue);
}

class VaultMetadataTableCompanion extends UpdateCompanion<VaultMetaRecord> {
  final Value<String> metaKey;
  final Value<String> metaValue;
  final Value<int> rowid;
  const VaultMetadataTableCompanion({
    this.metaKey = const Value.absent(),
    this.metaValue = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VaultMetadataTableCompanion.insert({
    required String metaKey,
    required String metaValue,
    this.rowid = const Value.absent(),
  })  : metaKey = Value(metaKey),
        metaValue = Value(metaValue);
  static Insertable<VaultMetaRecord> custom({
    Expression<String>? metaKey,
    Expression<String>? metaValue,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (metaKey != null) 'meta_key': metaKey,
      if (metaValue != null) 'meta_value': metaValue,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VaultMetadataTableCompanion copyWith(
      {Value<String>? metaKey, Value<String>? metaValue, Value<int>? rowid}) {
    return VaultMetadataTableCompanion(
      metaKey: metaKey ?? this.metaKey,
      metaValue: metaValue ?? this.metaValue,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (metaKey.present) {
      map['meta_key'] = Variable<String>(metaKey.value);
    }
    if (metaValue.present) {
      map['meta_value'] = Variable<String>(metaValue.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VaultMetadataTableCompanion(')
          ..write('metaKey: $metaKey, ')
          ..write('metaValue: $metaValue, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$VaultDatabase extends GeneratedDatabase {
  _$VaultDatabase(QueryExecutor e) : super(e);
  $VaultDatabaseManager get managers => $VaultDatabaseManager(this);
  late final $HostsTableTable hostsTable = $HostsTableTable(this);
  late final $KeysTableTable keysTable = $KeysTableTable(this);
  late final $FoldersTableTable foldersTable = $FoldersTableTable(this);
  late final $SnippetsTableTable snippetsTable = $SnippetsTableTable(this);
  late final $VaultSettingsTableTable vaultSettingsTable =
      $VaultSettingsTableTable(this);
  late final $VaultMetadataTableTable vaultMetadataTable =
      $VaultMetadataTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        hostsTable,
        keysTable,
        foldersTable,
        snippetsTable,
        vaultSettingsTable,
        vaultMetadataTable
      ];
}

typedef $$HostsTableTableCreateCompanionBuilder = HostsTableCompanion Function({
  required String id,
  required String label,
  required String hostname,
  Value<int> port,
  required String username,
  required String authType,
  Value<String?> credentialRefId,
  Value<String?> folderId,
  required String tags,
  required String environment,
  required String osType,
  Value<int> keepAliveIntervalSeconds,
  Value<bool> dangerousCommandProtection,
  Value<int?> lastPingLatencyMs,
  Value<DateTime?> lastConnectedAt,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$HostsTableTableUpdateCompanionBuilder = HostsTableCompanion Function({
  Value<String> id,
  Value<String> label,
  Value<String> hostname,
  Value<int> port,
  Value<String> username,
  Value<String> authType,
  Value<String?> credentialRefId,
  Value<String?> folderId,
  Value<String> tags,
  Value<String> environment,
  Value<String> osType,
  Value<int> keepAliveIntervalSeconds,
  Value<bool> dangerousCommandProtection,
  Value<int?> lastPingLatencyMs,
  Value<DateTime?> lastConnectedAt,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$HostsTableTableFilterComposer
    extends Composer<_$VaultDatabase, $HostsTableTable> {
  $$HostsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get hostname => $composableBuilder(
      column: $table.hostname, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get port => $composableBuilder(
      column: $table.port, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get username => $composableBuilder(
      column: $table.username, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get authType => $composableBuilder(
      column: $table.authType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get credentialRefId => $composableBuilder(
      column: $table.credentialRefId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get folderId => $composableBuilder(
      column: $table.folderId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get environment => $composableBuilder(
      column: $table.environment, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get osType => $composableBuilder(
      column: $table.osType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get keepAliveIntervalSeconds => $composableBuilder(
      column: $table.keepAliveIntervalSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get dangerousCommandProtection => $composableBuilder(
      column: $table.dangerousCommandProtection,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastPingLatencyMs => $composableBuilder(
      column: $table.lastPingLatencyMs,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastConnectedAt => $composableBuilder(
      column: $table.lastConnectedAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$HostsTableTableOrderingComposer
    extends Composer<_$VaultDatabase, $HostsTableTable> {
  $$HostsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get hostname => $composableBuilder(
      column: $table.hostname, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get port => $composableBuilder(
      column: $table.port, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get username => $composableBuilder(
      column: $table.username, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get authType => $composableBuilder(
      column: $table.authType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get credentialRefId => $composableBuilder(
      column: $table.credentialRefId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get folderId => $composableBuilder(
      column: $table.folderId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get environment => $composableBuilder(
      column: $table.environment, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get osType => $composableBuilder(
      column: $table.osType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get keepAliveIntervalSeconds => $composableBuilder(
      column: $table.keepAliveIntervalSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get dangerousCommandProtection => $composableBuilder(
      column: $table.dangerousCommandProtection,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastPingLatencyMs => $composableBuilder(
      column: $table.lastPingLatencyMs,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastConnectedAt => $composableBuilder(
      column: $table.lastConnectedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$HostsTableTableAnnotationComposer
    extends Composer<_$VaultDatabase, $HostsTableTable> {
  $$HostsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get hostname =>
      $composableBuilder(column: $table.hostname, builder: (column) => column);

  GeneratedColumn<int> get port =>
      $composableBuilder(column: $table.port, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get authType =>
      $composableBuilder(column: $table.authType, builder: (column) => column);

  GeneratedColumn<String> get credentialRefId => $composableBuilder(
      column: $table.credentialRefId, builder: (column) => column);

  GeneratedColumn<String> get folderId =>
      $composableBuilder(column: $table.folderId, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get environment => $composableBuilder(
      column: $table.environment, builder: (column) => column);

  GeneratedColumn<String> get osType =>
      $composableBuilder(column: $table.osType, builder: (column) => column);

  GeneratedColumn<int> get keepAliveIntervalSeconds => $composableBuilder(
      column: $table.keepAliveIntervalSeconds, builder: (column) => column);

  GeneratedColumn<bool> get dangerousCommandProtection => $composableBuilder(
      column: $table.dangerousCommandProtection, builder: (column) => column);

  GeneratedColumn<int> get lastPingLatencyMs => $composableBuilder(
      column: $table.lastPingLatencyMs, builder: (column) => column);

  GeneratedColumn<DateTime> get lastConnectedAt => $composableBuilder(
      column: $table.lastConnectedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$HostsTableTableTableManager extends RootTableManager<
    _$VaultDatabase,
    $HostsTableTable,
    HostRecord,
    $$HostsTableTableFilterComposer,
    $$HostsTableTableOrderingComposer,
    $$HostsTableTableAnnotationComposer,
    $$HostsTableTableCreateCompanionBuilder,
    $$HostsTableTableUpdateCompanionBuilder,
    (HostRecord, BaseReferences<_$VaultDatabase, $HostsTableTable, HostRecord>),
    HostRecord,
    PrefetchHooks Function()> {
  $$HostsTableTableTableManager(_$VaultDatabase db, $HostsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HostsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HostsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HostsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> label = const Value.absent(),
            Value<String> hostname = const Value.absent(),
            Value<int> port = const Value.absent(),
            Value<String> username = const Value.absent(),
            Value<String> authType = const Value.absent(),
            Value<String?> credentialRefId = const Value.absent(),
            Value<String?> folderId = const Value.absent(),
            Value<String> tags = const Value.absent(),
            Value<String> environment = const Value.absent(),
            Value<String> osType = const Value.absent(),
            Value<int> keepAliveIntervalSeconds = const Value.absent(),
            Value<bool> dangerousCommandProtection = const Value.absent(),
            Value<int?> lastPingLatencyMs = const Value.absent(),
            Value<DateTime?> lastConnectedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HostsTableCompanion(
            id: id,
            label: label,
            hostname: hostname,
            port: port,
            username: username,
            authType: authType,
            credentialRefId: credentialRefId,
            folderId: folderId,
            tags: tags,
            environment: environment,
            osType: osType,
            keepAliveIntervalSeconds: keepAliveIntervalSeconds,
            dangerousCommandProtection: dangerousCommandProtection,
            lastPingLatencyMs: lastPingLatencyMs,
            lastConnectedAt: lastConnectedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String label,
            required String hostname,
            Value<int> port = const Value.absent(),
            required String username,
            required String authType,
            Value<String?> credentialRefId = const Value.absent(),
            Value<String?> folderId = const Value.absent(),
            required String tags,
            required String environment,
            required String osType,
            Value<int> keepAliveIntervalSeconds = const Value.absent(),
            Value<bool> dangerousCommandProtection = const Value.absent(),
            Value<int?> lastPingLatencyMs = const Value.absent(),
            Value<DateTime?> lastConnectedAt = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              HostsTableCompanion.insert(
            id: id,
            label: label,
            hostname: hostname,
            port: port,
            username: username,
            authType: authType,
            credentialRefId: credentialRefId,
            folderId: folderId,
            tags: tags,
            environment: environment,
            osType: osType,
            keepAliveIntervalSeconds: keepAliveIntervalSeconds,
            dangerousCommandProtection: dangerousCommandProtection,
            lastPingLatencyMs: lastPingLatencyMs,
            lastConnectedAt: lastConnectedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$HostsTableTableProcessedTableManager = ProcessedTableManager<
    _$VaultDatabase,
    $HostsTableTable,
    HostRecord,
    $$HostsTableTableFilterComposer,
    $$HostsTableTableOrderingComposer,
    $$HostsTableTableAnnotationComposer,
    $$HostsTableTableCreateCompanionBuilder,
    $$HostsTableTableUpdateCompanionBuilder,
    (HostRecord, BaseReferences<_$VaultDatabase, $HostsTableTable, HostRecord>),
    HostRecord,
    PrefetchHooks Function()>;
typedef $$KeysTableTableCreateCompanionBuilder = KeysTableCompanion Function({
  required String id,
  required String label,
  required String keyType,
  required Uint8List encryptedPrivateKey,
  required String publicKey,
  Value<Uint8List?> encryptedPassphrase,
  Value<String?> fingerprint,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$KeysTableTableUpdateCompanionBuilder = KeysTableCompanion Function({
  Value<String> id,
  Value<String> label,
  Value<String> keyType,
  Value<Uint8List> encryptedPrivateKey,
  Value<String> publicKey,
  Value<Uint8List?> encryptedPassphrase,
  Value<String?> fingerprint,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$KeysTableTableFilterComposer
    extends Composer<_$VaultDatabase, $KeysTableTable> {
  $$KeysTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get keyType => $composableBuilder(
      column: $table.keyType, builder: (column) => ColumnFilters(column));

  ColumnFilters<Uint8List> get encryptedPrivateKey => $composableBuilder(
      column: $table.encryptedPrivateKey,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get publicKey => $composableBuilder(
      column: $table.publicKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<Uint8List> get encryptedPassphrase => $composableBuilder(
      column: $table.encryptedPassphrase,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fingerprint => $composableBuilder(
      column: $table.fingerprint, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$KeysTableTableOrderingComposer
    extends Composer<_$VaultDatabase, $KeysTableTable> {
  $$KeysTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get keyType => $composableBuilder(
      column: $table.keyType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<Uint8List> get encryptedPrivateKey => $composableBuilder(
      column: $table.encryptedPrivateKey,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get publicKey => $composableBuilder(
      column: $table.publicKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<Uint8List> get encryptedPassphrase => $composableBuilder(
      column: $table.encryptedPassphrase,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fingerprint => $composableBuilder(
      column: $table.fingerprint, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$KeysTableTableAnnotationComposer
    extends Composer<_$VaultDatabase, $KeysTableTable> {
  $$KeysTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get keyType =>
      $composableBuilder(column: $table.keyType, builder: (column) => column);

  GeneratedColumn<Uint8List> get encryptedPrivateKey => $composableBuilder(
      column: $table.encryptedPrivateKey, builder: (column) => column);

  GeneratedColumn<String> get publicKey =>
      $composableBuilder(column: $table.publicKey, builder: (column) => column);

  GeneratedColumn<Uint8List> get encryptedPassphrase => $composableBuilder(
      column: $table.encryptedPassphrase, builder: (column) => column);

  GeneratedColumn<String> get fingerprint => $composableBuilder(
      column: $table.fingerprint, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$KeysTableTableTableManager extends RootTableManager<
    _$VaultDatabase,
    $KeysTableTable,
    KeyRecord,
    $$KeysTableTableFilterComposer,
    $$KeysTableTableOrderingComposer,
    $$KeysTableTableAnnotationComposer,
    $$KeysTableTableCreateCompanionBuilder,
    $$KeysTableTableUpdateCompanionBuilder,
    (KeyRecord, BaseReferences<_$VaultDatabase, $KeysTableTable, KeyRecord>),
    KeyRecord,
    PrefetchHooks Function()> {
  $$KeysTableTableTableManager(_$VaultDatabase db, $KeysTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KeysTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KeysTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KeysTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> label = const Value.absent(),
            Value<String> keyType = const Value.absent(),
            Value<Uint8List> encryptedPrivateKey = const Value.absent(),
            Value<String> publicKey = const Value.absent(),
            Value<Uint8List?> encryptedPassphrase = const Value.absent(),
            Value<String?> fingerprint = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              KeysTableCompanion(
            id: id,
            label: label,
            keyType: keyType,
            encryptedPrivateKey: encryptedPrivateKey,
            publicKey: publicKey,
            encryptedPassphrase: encryptedPassphrase,
            fingerprint: fingerprint,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String label,
            required String keyType,
            required Uint8List encryptedPrivateKey,
            required String publicKey,
            Value<Uint8List?> encryptedPassphrase = const Value.absent(),
            Value<String?> fingerprint = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              KeysTableCompanion.insert(
            id: id,
            label: label,
            keyType: keyType,
            encryptedPrivateKey: encryptedPrivateKey,
            publicKey: publicKey,
            encryptedPassphrase: encryptedPassphrase,
            fingerprint: fingerprint,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$KeysTableTableProcessedTableManager = ProcessedTableManager<
    _$VaultDatabase,
    $KeysTableTable,
    KeyRecord,
    $$KeysTableTableFilterComposer,
    $$KeysTableTableOrderingComposer,
    $$KeysTableTableAnnotationComposer,
    $$KeysTableTableCreateCompanionBuilder,
    $$KeysTableTableUpdateCompanionBuilder,
    (KeyRecord, BaseReferences<_$VaultDatabase, $KeysTableTable, KeyRecord>),
    KeyRecord,
    PrefetchHooks Function()>;
typedef $$FoldersTableTableCreateCompanionBuilder = FoldersTableCompanion
    Function({
  required String id,
  required String name,
  Value<String?> parentId,
  Value<String?> colorHex,
  Value<String?> iconName,
  Value<int> sortOrder,
  Value<int> rowid,
});
typedef $$FoldersTableTableUpdateCompanionBuilder = FoldersTableCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<String?> parentId,
  Value<String?> colorHex,
  Value<String?> iconName,
  Value<int> sortOrder,
  Value<int> rowid,
});

class $$FoldersTableTableFilterComposer
    extends Composer<_$VaultDatabase, $FoldersTableTable> {
  $$FoldersTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get parentId => $composableBuilder(
      column: $table.parentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get colorHex => $composableBuilder(
      column: $table.colorHex, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get iconName => $composableBuilder(
      column: $table.iconName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));
}

class $$FoldersTableTableOrderingComposer
    extends Composer<_$VaultDatabase, $FoldersTableTable> {
  $$FoldersTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get parentId => $composableBuilder(
      column: $table.parentId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get colorHex => $composableBuilder(
      column: $table.colorHex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get iconName => $composableBuilder(
      column: $table.iconName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));
}

class $$FoldersTableTableAnnotationComposer
    extends Composer<_$VaultDatabase, $FoldersTableTable> {
  $$FoldersTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  GeneratedColumn<String> get iconName =>
      $composableBuilder(column: $table.iconName, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$FoldersTableTableTableManager extends RootTableManager<
    _$VaultDatabase,
    $FoldersTableTable,
    FolderRecord,
    $$FoldersTableTableFilterComposer,
    $$FoldersTableTableOrderingComposer,
    $$FoldersTableTableAnnotationComposer,
    $$FoldersTableTableCreateCompanionBuilder,
    $$FoldersTableTableUpdateCompanionBuilder,
    (
      FolderRecord,
      BaseReferences<_$VaultDatabase, $FoldersTableTable, FolderRecord>
    ),
    FolderRecord,
    PrefetchHooks Function()> {
  $$FoldersTableTableTableManager(_$VaultDatabase db, $FoldersTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoldersTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoldersTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoldersTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> parentId = const Value.absent(),
            Value<String?> colorHex = const Value.absent(),
            Value<String?> iconName = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FoldersTableCompanion(
            id: id,
            name: name,
            parentId: parentId,
            colorHex: colorHex,
            iconName: iconName,
            sortOrder: sortOrder,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String?> parentId = const Value.absent(),
            Value<String?> colorHex = const Value.absent(),
            Value<String?> iconName = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FoldersTableCompanion.insert(
            id: id,
            name: name,
            parentId: parentId,
            colorHex: colorHex,
            iconName: iconName,
            sortOrder: sortOrder,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FoldersTableTableProcessedTableManager = ProcessedTableManager<
    _$VaultDatabase,
    $FoldersTableTable,
    FolderRecord,
    $$FoldersTableTableFilterComposer,
    $$FoldersTableTableOrderingComposer,
    $$FoldersTableTableAnnotationComposer,
    $$FoldersTableTableCreateCompanionBuilder,
    $$FoldersTableTableUpdateCompanionBuilder,
    (
      FolderRecord,
      BaseReferences<_$VaultDatabase, $FoldersTableTable, FolderRecord>
    ),
    FolderRecord,
    PrefetchHooks Function()>;
typedef $$SnippetsTableTableCreateCompanionBuilder = SnippetsTableCompanion
    Function({
  required String id,
  required String title,
  required String command,
  Value<String?> description,
  required String tags,
  Value<String?> folderId,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$SnippetsTableTableUpdateCompanionBuilder = SnippetsTableCompanion
    Function({
  Value<String> id,
  Value<String> title,
  Value<String> command,
  Value<String?> description,
  Value<String> tags,
  Value<String?> folderId,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$SnippetsTableTableFilterComposer
    extends Composer<_$VaultDatabase, $SnippetsTableTable> {
  $$SnippetsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get command => $composableBuilder(
      column: $table.command, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get folderId => $composableBuilder(
      column: $table.folderId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$SnippetsTableTableOrderingComposer
    extends Composer<_$VaultDatabase, $SnippetsTableTable> {
  $$SnippetsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get command => $composableBuilder(
      column: $table.command, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get folderId => $composableBuilder(
      column: $table.folderId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$SnippetsTableTableAnnotationComposer
    extends Composer<_$VaultDatabase, $SnippetsTableTable> {
  $$SnippetsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get command =>
      $composableBuilder(column: $table.command, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get folderId =>
      $composableBuilder(column: $table.folderId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SnippetsTableTableTableManager extends RootTableManager<
    _$VaultDatabase,
    $SnippetsTableTable,
    SnippetRecord,
    $$SnippetsTableTableFilterComposer,
    $$SnippetsTableTableOrderingComposer,
    $$SnippetsTableTableAnnotationComposer,
    $$SnippetsTableTableCreateCompanionBuilder,
    $$SnippetsTableTableUpdateCompanionBuilder,
    (
      SnippetRecord,
      BaseReferences<_$VaultDatabase, $SnippetsTableTable, SnippetRecord>
    ),
    SnippetRecord,
    PrefetchHooks Function()> {
  $$SnippetsTableTableTableManager(
      _$VaultDatabase db, $SnippetsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SnippetsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SnippetsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SnippetsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> command = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String> tags = const Value.absent(),
            Value<String?> folderId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SnippetsTableCompanion(
            id: id,
            title: title,
            command: command,
            description: description,
            tags: tags,
            folderId: folderId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String title,
            required String command,
            Value<String?> description = const Value.absent(),
            required String tags,
            Value<String?> folderId = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              SnippetsTableCompanion.insert(
            id: id,
            title: title,
            command: command,
            description: description,
            tags: tags,
            folderId: folderId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SnippetsTableTableProcessedTableManager = ProcessedTableManager<
    _$VaultDatabase,
    $SnippetsTableTable,
    SnippetRecord,
    $$SnippetsTableTableFilterComposer,
    $$SnippetsTableTableOrderingComposer,
    $$SnippetsTableTableAnnotationComposer,
    $$SnippetsTableTableCreateCompanionBuilder,
    $$SnippetsTableTableUpdateCompanionBuilder,
    (
      SnippetRecord,
      BaseReferences<_$VaultDatabase, $SnippetsTableTable, SnippetRecord>
    ),
    SnippetRecord,
    PrefetchHooks Function()>;
typedef $$VaultSettingsTableTableCreateCompanionBuilder
    = VaultSettingsTableCompanion Function({
  Value<int> id,
  Value<int> idleLockTimeoutMinutes,
  Value<bool> isBiometricsEnabled,
  Value<bool> isPinEnabled,
  Value<String> themeId,
  Value<String> terminalFontFamily,
  Value<double> terminalFontSize,
  Value<bool> enableLiveLatencyPing,
  Value<int> pingIntervalSeconds,
});
typedef $$VaultSettingsTableTableUpdateCompanionBuilder
    = VaultSettingsTableCompanion Function({
  Value<int> id,
  Value<int> idleLockTimeoutMinutes,
  Value<bool> isBiometricsEnabled,
  Value<bool> isPinEnabled,
  Value<String> themeId,
  Value<String> terminalFontFamily,
  Value<double> terminalFontSize,
  Value<bool> enableLiveLatencyPing,
  Value<int> pingIntervalSeconds,
});

class $$VaultSettingsTableTableFilterComposer
    extends Composer<_$VaultDatabase, $VaultSettingsTableTable> {
  $$VaultSettingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get idleLockTimeoutMinutes => $composableBuilder(
      column: $table.idleLockTimeoutMinutes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isBiometricsEnabled => $composableBuilder(
      column: $table.isBiometricsEnabled,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isPinEnabled => $composableBuilder(
      column: $table.isPinEnabled, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get themeId => $composableBuilder(
      column: $table.themeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get terminalFontFamily => $composableBuilder(
      column: $table.terminalFontFamily,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get terminalFontSize => $composableBuilder(
      column: $table.terminalFontSize,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get enableLiveLatencyPing => $composableBuilder(
      column: $table.enableLiveLatencyPing,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get pingIntervalSeconds => $composableBuilder(
      column: $table.pingIntervalSeconds,
      builder: (column) => ColumnFilters(column));
}

class $$VaultSettingsTableTableOrderingComposer
    extends Composer<_$VaultDatabase, $VaultSettingsTableTable> {
  $$VaultSettingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get idleLockTimeoutMinutes => $composableBuilder(
      column: $table.idleLockTimeoutMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isBiometricsEnabled => $composableBuilder(
      column: $table.isBiometricsEnabled,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPinEnabled => $composableBuilder(
      column: $table.isPinEnabled,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get themeId => $composableBuilder(
      column: $table.themeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get terminalFontFamily => $composableBuilder(
      column: $table.terminalFontFamily,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get terminalFontSize => $composableBuilder(
      column: $table.terminalFontSize,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get enableLiveLatencyPing => $composableBuilder(
      column: $table.enableLiveLatencyPing,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get pingIntervalSeconds => $composableBuilder(
      column: $table.pingIntervalSeconds,
      builder: (column) => ColumnOrderings(column));
}

class $$VaultSettingsTableTableAnnotationComposer
    extends Composer<_$VaultDatabase, $VaultSettingsTableTable> {
  $$VaultSettingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get idleLockTimeoutMinutes => $composableBuilder(
      column: $table.idleLockTimeoutMinutes, builder: (column) => column);

  GeneratedColumn<bool> get isBiometricsEnabled => $composableBuilder(
      column: $table.isBiometricsEnabled, builder: (column) => column);

  GeneratedColumn<bool> get isPinEnabled => $composableBuilder(
      column: $table.isPinEnabled, builder: (column) => column);

  GeneratedColumn<String> get themeId =>
      $composableBuilder(column: $table.themeId, builder: (column) => column);

  GeneratedColumn<String> get terminalFontFamily => $composableBuilder(
      column: $table.terminalFontFamily, builder: (column) => column);

  GeneratedColumn<double> get terminalFontSize => $composableBuilder(
      column: $table.terminalFontSize, builder: (column) => column);

  GeneratedColumn<bool> get enableLiveLatencyPing => $composableBuilder(
      column: $table.enableLiveLatencyPing, builder: (column) => column);

  GeneratedColumn<int> get pingIntervalSeconds => $composableBuilder(
      column: $table.pingIntervalSeconds, builder: (column) => column);
}

class $$VaultSettingsTableTableTableManager extends RootTableManager<
    _$VaultDatabase,
    $VaultSettingsTableTable,
    VaultSettingsRecord,
    $$VaultSettingsTableTableFilterComposer,
    $$VaultSettingsTableTableOrderingComposer,
    $$VaultSettingsTableTableAnnotationComposer,
    $$VaultSettingsTableTableCreateCompanionBuilder,
    $$VaultSettingsTableTableUpdateCompanionBuilder,
    (
      VaultSettingsRecord,
      BaseReferences<_$VaultDatabase, $VaultSettingsTableTable,
          VaultSettingsRecord>
    ),
    VaultSettingsRecord,
    PrefetchHooks Function()> {
  $$VaultSettingsTableTableTableManager(
      _$VaultDatabase db, $VaultSettingsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VaultSettingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VaultSettingsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VaultSettingsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> idleLockTimeoutMinutes = const Value.absent(),
            Value<bool> isBiometricsEnabled = const Value.absent(),
            Value<bool> isPinEnabled = const Value.absent(),
            Value<String> themeId = const Value.absent(),
            Value<String> terminalFontFamily = const Value.absent(),
            Value<double> terminalFontSize = const Value.absent(),
            Value<bool> enableLiveLatencyPing = const Value.absent(),
            Value<int> pingIntervalSeconds = const Value.absent(),
          }) =>
              VaultSettingsTableCompanion(
            id: id,
            idleLockTimeoutMinutes: idleLockTimeoutMinutes,
            isBiometricsEnabled: isBiometricsEnabled,
            isPinEnabled: isPinEnabled,
            themeId: themeId,
            terminalFontFamily: terminalFontFamily,
            terminalFontSize: terminalFontSize,
            enableLiveLatencyPing: enableLiveLatencyPing,
            pingIntervalSeconds: pingIntervalSeconds,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> idleLockTimeoutMinutes = const Value.absent(),
            Value<bool> isBiometricsEnabled = const Value.absent(),
            Value<bool> isPinEnabled = const Value.absent(),
            Value<String> themeId = const Value.absent(),
            Value<String> terminalFontFamily = const Value.absent(),
            Value<double> terminalFontSize = const Value.absent(),
            Value<bool> enableLiveLatencyPing = const Value.absent(),
            Value<int> pingIntervalSeconds = const Value.absent(),
          }) =>
              VaultSettingsTableCompanion.insert(
            id: id,
            idleLockTimeoutMinutes: idleLockTimeoutMinutes,
            isBiometricsEnabled: isBiometricsEnabled,
            isPinEnabled: isPinEnabled,
            themeId: themeId,
            terminalFontFamily: terminalFontFamily,
            terminalFontSize: terminalFontSize,
            enableLiveLatencyPing: enableLiveLatencyPing,
            pingIntervalSeconds: pingIntervalSeconds,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$VaultSettingsTableTableProcessedTableManager = ProcessedTableManager<
    _$VaultDatabase,
    $VaultSettingsTableTable,
    VaultSettingsRecord,
    $$VaultSettingsTableTableFilterComposer,
    $$VaultSettingsTableTableOrderingComposer,
    $$VaultSettingsTableTableAnnotationComposer,
    $$VaultSettingsTableTableCreateCompanionBuilder,
    $$VaultSettingsTableTableUpdateCompanionBuilder,
    (
      VaultSettingsRecord,
      BaseReferences<_$VaultDatabase, $VaultSettingsTableTable,
          VaultSettingsRecord>
    ),
    VaultSettingsRecord,
    PrefetchHooks Function()>;
typedef $$VaultMetadataTableTableCreateCompanionBuilder
    = VaultMetadataTableCompanion Function({
  required String metaKey,
  required String metaValue,
  Value<int> rowid,
});
typedef $$VaultMetadataTableTableUpdateCompanionBuilder
    = VaultMetadataTableCompanion Function({
  Value<String> metaKey,
  Value<String> metaValue,
  Value<int> rowid,
});

class $$VaultMetadataTableTableFilterComposer
    extends Composer<_$VaultDatabase, $VaultMetadataTableTable> {
  $$VaultMetadataTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get metaKey => $composableBuilder(
      column: $table.metaKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get metaValue => $composableBuilder(
      column: $table.metaValue, builder: (column) => ColumnFilters(column));
}

class $$VaultMetadataTableTableOrderingComposer
    extends Composer<_$VaultDatabase, $VaultMetadataTableTable> {
  $$VaultMetadataTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get metaKey => $composableBuilder(
      column: $table.metaKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get metaValue => $composableBuilder(
      column: $table.metaValue, builder: (column) => ColumnOrderings(column));
}

class $$VaultMetadataTableTableAnnotationComposer
    extends Composer<_$VaultDatabase, $VaultMetadataTableTable> {
  $$VaultMetadataTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get metaKey =>
      $composableBuilder(column: $table.metaKey, builder: (column) => column);

  GeneratedColumn<String> get metaValue =>
      $composableBuilder(column: $table.metaValue, builder: (column) => column);
}

class $$VaultMetadataTableTableTableManager extends RootTableManager<
    _$VaultDatabase,
    $VaultMetadataTableTable,
    VaultMetaRecord,
    $$VaultMetadataTableTableFilterComposer,
    $$VaultMetadataTableTableOrderingComposer,
    $$VaultMetadataTableTableAnnotationComposer,
    $$VaultMetadataTableTableCreateCompanionBuilder,
    $$VaultMetadataTableTableUpdateCompanionBuilder,
    (
      VaultMetaRecord,
      BaseReferences<_$VaultDatabase, $VaultMetadataTableTable, VaultMetaRecord>
    ),
    VaultMetaRecord,
    PrefetchHooks Function()> {
  $$VaultMetadataTableTableTableManager(
      _$VaultDatabase db, $VaultMetadataTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VaultMetadataTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VaultMetadataTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VaultMetadataTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> metaKey = const Value.absent(),
            Value<String> metaValue = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VaultMetadataTableCompanion(
            metaKey: metaKey,
            metaValue: metaValue,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String metaKey,
            required String metaValue,
            Value<int> rowid = const Value.absent(),
          }) =>
              VaultMetadataTableCompanion.insert(
            metaKey: metaKey,
            metaValue: metaValue,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$VaultMetadataTableTableProcessedTableManager = ProcessedTableManager<
    _$VaultDatabase,
    $VaultMetadataTableTable,
    VaultMetaRecord,
    $$VaultMetadataTableTableFilterComposer,
    $$VaultMetadataTableTableOrderingComposer,
    $$VaultMetadataTableTableAnnotationComposer,
    $$VaultMetadataTableTableCreateCompanionBuilder,
    $$VaultMetadataTableTableUpdateCompanionBuilder,
    (
      VaultMetaRecord,
      BaseReferences<_$VaultDatabase, $VaultMetadataTableTable, VaultMetaRecord>
    ),
    VaultMetaRecord,
    PrefetchHooks Function()>;

class $VaultDatabaseManager {
  final _$VaultDatabase _db;
  $VaultDatabaseManager(this._db);
  $$HostsTableTableTableManager get hostsTable =>
      $$HostsTableTableTableManager(_db, _db.hostsTable);
  $$KeysTableTableTableManager get keysTable =>
      $$KeysTableTableTableManager(_db, _db.keysTable);
  $$FoldersTableTableTableManager get foldersTable =>
      $$FoldersTableTableTableManager(_db, _db.foldersTable);
  $$SnippetsTableTableTableManager get snippetsTable =>
      $$SnippetsTableTableTableManager(_db, _db.snippetsTable);
  $$VaultSettingsTableTableTableManager get vaultSettingsTable =>
      $$VaultSettingsTableTableTableManager(_db, _db.vaultSettingsTable);
  $$VaultMetadataTableTableTableManager get vaultMetadataTable =>
      $$VaultMetadataTableTableTableManager(_db, _db.vaultMetadataTable);
}
