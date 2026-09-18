import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/material.dart';
import '../../localization/localization_scope.dart';
import '../../theme/shellit_theme.dart';

typedef HostFormSaveCallback = void Function(HostEntity host, String? password);

class HostFormDialog extends StatefulWidget {
  final HostEntity? initialHost;
  final HostFormSaveCallback onSave;
  final List<KeyEntity> availableKeys;
  final List<FolderEntity> availableFolders;
  final Future<FolderEntity?> Function(String folderName)? onCreateFolder;

  const HostFormDialog({
    super.key,
    this.initialHost,
    required this.onSave,
    this.availableKeys = const [],
    this.availableFolders = const [],
    this.onCreateFolder,
  });

  @override
  State<HostFormDialog> createState() => _HostFormDialogState();
}

class _HostFormDialogState extends State<HostFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _labelController;
  late TextEditingController _hostnameController;
  late TextEditingController _portController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _tagsController;

  late List<FolderEntity> _folders;
  String? _selectedFolderId;

  late HostAuthType _authType;
  late HostEnvironment _environment;
  late OsType _osType;
  late bool _dangerousCommandProtection;
  late bool _obscurePassword;
  String? _selectedKeyId;

  @override
  void initState() {
    super.initState();
    final h = widget.initialHost;
    _labelController = TextEditingController(text: h?.label ?? '');
    _hostnameController = TextEditingController(text: h?.hostname ?? '');
    _portController = TextEditingController(text: (h?.port ?? 22).toString());
    _usernameController = TextEditingController(text: h?.username ?? 'root');
    _passwordController = TextEditingController();
    _tagsController = TextEditingController(text: h?.tags.join(', ') ?? '');

    _folders = List.of(widget.availableFolders);
    final initialFolderId = h?.folderId;
    if (initialFolderId != null && initialFolderId.isNotEmpty) {
      if (!_folders.any((f) => f.id == initialFolderId)) {
        _folders.add(FolderEntity(id: initialFolderId, name: initialFolderId));
      }
      _selectedFolderId = initialFolderId;
    }

    _authType = h?.authType ?? HostAuthType.password;
    _environment = h?.environment ?? HostEnvironment.defaultEnv;
    _osType = h?.osType ?? OsType.genericServer;
    _dangerousCommandProtection = h?.dangerousCommandProtection ?? false;
    _obscurePassword = true;
    _selectedKeyId = h?.credentialRefId;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _hostnameController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _promptCreateFolder() async {
    final textCtrl = TextEditingController();
    final folderName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          context.tr(
            'hosts.form.dialog_folder_title',
            defaultText: 'Create New Folder',
          ),
        ),
        content: TextField(
          controller: textCtrl,
          autofocus: true,
          decoration: InputDecoration(
            labelText: context.tr(
              'hosts.form.dialog_folder_name',
              defaultText: 'Folder Name',
            ),
            hintText: context.tr(
              'hosts.form.dialog_folder_hint',
              defaultText: 'e.g. EU Datacenter',
            ),
          ),
          onSubmitted: (val) => Navigator.of(ctx).pop(val.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.tr('common.cancel', defaultText: 'Cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(textCtrl.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: ShellitColors.accentBlue,
              foregroundColor: Colors.white,
            ),
            child: Text(
              context.tr(
                'hosts.form.dialog_folder_btn',
                defaultText: 'Create',
              ),
            ),
          ),
        ],
      ),
    );

    if (folderName != null && folderName.isNotEmpty && mounted) {
      if (widget.onCreateFolder != null) {
        final created = await widget.onCreateFolder!(folderName);
        if (created != null && mounted) {
          setState(() {
            if (!_folders.any((f) => f.id == created.id)) {
              _folders.add(created);
            }
            _selectedFolderId = created.id;
          });
        }
      } else {
        final fallback = FolderEntity(
          id: 'folder-${DateTime.now().millisecondsSinceEpoch}',
          name: folderName,
        );
        setState(() {
          _folders.add(fallback);
          _selectedFolderId = fallback.id;
        });
      }
    }
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final now = DateTime.now();
      final tags = _tagsController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      final host = HostEntity(
        id: widget.initialHost?.id ?? 'host-${now.millisecondsSinceEpoch}',
        label: _labelController.text.trim(),
        hostname: _hostnameController.text.trim(),
        port: int.tryParse(_portController.text.trim()) ?? 22,
        username: _usernameController.text.trim(),
        authType: _authType,
        credentialRefId: _authType == HostAuthType.privateKey
            ? _selectedKeyId
            : widget.initialHost?.credentialRefId,
        environment: _environment,
        osType: _osType,
        tags: tags,
        folderId: _selectedFolderId,
        dangerousCommandProtection: _dangerousCommandProtection,
        lastPingLatencyMs: widget.initialHost?.lastPingLatencyMs,
        createdAt: widget.initialHost?.createdAt ?? now,
        updatedAt: now,
      );

      final enteredPassword = _passwordController.text.trim().isNotEmpty
          ? _passwordController.text.trim()
          : null;

      widget.onSave(host, enteredPassword);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialHost != null;

    return AlertDialog(
      title: Text(
        isEdit
            ? context.tr('hosts.form.title_edit', defaultText: 'Edit Host')
            : context.tr('hosts.form.title_new', defaultText: 'New SSH Host'),
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label
                TextFormField(
                  controller: _labelController,
                  decoration: InputDecoration(
                    labelText: context.tr(
                      'hosts.form.label_field',
                      defaultText: 'Label / Alias',
                    ),
                    hintText: context.tr(
                      'hosts.form.label_hint',
                      defaultText: 'e.g. Production Web 01',
                    ),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? context.tr(
                          'hosts.form.label_required',
                          defaultText: 'Label is required',
                        )
                      : null,
                ),
                const SizedBox(height: 12),

                // Hostname & Port
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _hostnameController,
                        decoration: InputDecoration(
                          labelText: context.tr(
                            'hosts.form.hostname_field',
                            defaultText: 'Hostname / IP',
                          ),
                          hintText: context.tr(
                            'hosts.form.hostname_hint',
                            defaultText: '192.168.1.1 or example.com',
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? context.tr(
                                'hosts.form.hostname_required',
                                defaultText: 'Hostname is required',
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _portController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: context.tr(
                            'hosts.form.port_field',
                            defaultText: 'Port',
                          ),
                        ),
                        validator: (v) {
                          final p = int.tryParse(v ?? '');
                          if (p == null || p <= 0 || p > 65535) {
                            return context.tr(
                              'hosts.form.port_invalid',
                              defaultText: 'Invalid',
                            );
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Username & Auth Type
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: context.tr(
                            'hosts.form.username_field',
                            defaultText: 'Username',
                          ),
                          hintText: context.tr(
                            'hosts.form.username_hint',
                            defaultText: 'root, ubuntu, etc.',
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? context.tr(
                                'hosts.form.username_required',
                                defaultText: 'Username is required',
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<HostAuthType>(
                        isExpanded: true,
                        initialValue: _authType,
                        decoration: InputDecoration(
                          labelText: context.tr(
                            'hosts.form.auth_method',
                            defaultText: 'Auth Method',
                          ),
                        ),
                        items: HostAuthType.values.map((a) {
                          return DropdownMenuItem(
                            value: a,
                            child: Text(a.name,
                                style: const TextStyle(fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _authType = v);
                        },
                      ),
                    ),
                  ],
                ),
                if (_authType == HostAuthType.password) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: isEdit
                          ? context.tr(
                              'hosts.form.password_edit_hint',
                              defaultText:
                                  'SSH Password (leave blank to keep current)',
                            )
                          : context.tr(
                              'hosts.form.password_field',
                              defaultText: 'SSH Password',
                            ),
                      hintText: context.tr(
                        'hosts.form.password_hint',
                        defaultText: 'Enter server password',
                      ),
                      prefixIcon: const Icon(Icons.lock_outline, size: 18),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          size: 18,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                ] else if (_authType == HostAuthType.privateKey) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: _selectedKeyId,
                    decoration: InputDecoration(
                      labelText: context.tr(
                        'hosts.form.key_field',
                        defaultText: 'SSH Key (from Keychain)',
                      ),
                      prefixIcon:
                          const Icon(Icons.vpn_key_outlined, size: 18),
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(
                          context.tr(
                            'hosts.form.key_none',
                            defaultText:
                                'None (Use system agent or prompt)',
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      ...widget.availableKeys
                          .map((k) => DropdownMenuItem<String?>(
                                value: k.id,
                                child: Text(
                                    '${k.label} (${k.keyType.name.toUpperCase()})',
                                    style: const TextStyle(fontSize: 13)),
                              )),
                    ],
                    onChanged: (v) => setState(() => _selectedKeyId = v),
                  ),
                ],
                const SizedBox(height: 12),

                // Environment (OS is auto-detected upon connection)
                DropdownButtonFormField<HostEnvironment>(
                  initialValue: _environment,
                  decoration: InputDecoration(
                    labelText: context.tr(
                      'hosts.form.environment_field',
                      defaultText: 'Environment',
                    ),
                    helperText: context.tr(
                      'hosts.form.environment_helper',
                      defaultText:
                          'OS / Distribution is auto-detected upon SSH connection',
                    ),
                  ),
                  items: HostEnvironment.values.map((env) {
                    return DropdownMenuItem(
                      value: env,
                      child:
                          Text(env.name, style: const TextStyle(fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        _environment = v;
                        if (v == HostEnvironment.production) {
                          _dangerousCommandProtection = true;
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),

                // Folder & Tags
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String?>(
                              isExpanded: true,
                              initialValue: _selectedFolderId,
                              decoration: InputDecoration(
                                labelText: context.tr(
                                  'hosts.form.folder_field',
                                  defaultText: 'Folder',
                                ),
                                prefixIcon: const Icon(
                                  Icons.folder_outlined,
                                  size: 18,
                                ),
                              ),
                              items: [
                                DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text(
                                    context.tr(
                                      'hosts.form.folder_root',
                                      defaultText: 'No Folder (Root)',
                                    ),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                ..._folders
                                    .map((f) => DropdownMenuItem<String?>(
                                          value: f.id,
                                          child: Text(
                                            f.name,
                                            style:
                                                const TextStyle(fontSize: 13),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        )),
                              ],
                              onChanged: (v) =>
                                  setState(() => _selectedFolderId = v),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(
                              Icons.create_new_folder_outlined,
                              size: 20,
                            ),
                            tooltip: context.tr(
                              'hosts.form.tooltip_create_folder',
                              defaultText: 'Create New Folder',
                            ),
                            color: ShellitColors.accentBlue,
                            onPressed: _promptCreateFolder,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _tagsController,
                        decoration: InputDecoration(
                          labelText: context.tr(
                            'hosts.form.tags_field',
                            defaultText: 'Tags (comma separated)',
                          ),
                          hintText: context.tr(
                            'hosts.form.tags_hint',
                            defaultText: 'web, db, k8s',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Dangerous Command Protection switch
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    context.tr(
                      'hosts.form.prod_guard_title',
                      defaultText: 'Production Command Guard',
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    context.tr(
                      'hosts.form.prod_guard_subtitle',
                      defaultText:
                          'Intercept destructive commands (rm -rf, reboot, etc.) and require confirmation',
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                      color: ShellitColors.textSecondary,
                    ),
                  ),
                  value: _dangerousCommandProtection,
                  activeThumbColor: ShellitColors.statusRed,
                  onChanged: (val) {
                    setState(() => _dangerousCommandProtection = val);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.tr('common.cancel', defaultText: 'Cancel')),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: ShellitColors.accentBlue,
            foregroundColor: Colors.white,
          ),
          child: Text(
            isEdit
                ? context.tr(
                    'hosts.form.btn_save',
                    defaultText: 'Save Changes',
                  )
                : context.tr('hosts.form.btn_create', defaultText: 'Create'),
          ),
        ),
      ],
    );
  }
}
