import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/session_manager_provider.dart';
import '../../providers/vault_provider.dart';
import '../../theme/shellit_theme.dart';

class TopBarTabs extends ConsumerStatefulWidget {
  final ValueChanged<String>? onQuickConnect;
  final VoidCallback? onOmniBarOpen;

  const TopBarTabs({
    super.key,
    this.onQuickConnect,
    this.onOmniBarOpen,
  });

  @override
  ConsumerState<TopBarTabs> createState() => _TopBarTabsState();
}

class _TopBarTabsState extends ConsumerState<TopBarTabs> {
  final TextEditingController _quickConnectController = TextEditingController();

  @override
  void dispose() {
    _quickConnectController.dispose();
    super.dispose();
  }

  void _submitQuickConnect() {
    final query = _quickConnectController.text.trim();
    if (query.isNotEmpty) {
      widget.onQuickConnect?.call(query);
      _quickConnectController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vaultState = ref.watch(vaultProvider);
    final sessionState = ref.watch(sessionManagerProvider);
    final sessionNotifier = ref.read(sessionManagerProvider.notifier);

    return Container(
      height: 50,
      decoration: const BoxDecoration(
        color: ShellitColors.obsidianHeader,
        border: Border(
          bottom: BorderSide(color: ShellitColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          // 1. Vault Selector & Lock indicator
          _buildVaultSelector(vaultState),

          const VerticalDivider(width: 1),

          // Pinned Hosts / Home catalog tab
          _buildCatalogTab(
            isActive: sessionState.isCatalogActive,
            onSelect: () => sessionNotifier.showCatalog(),
          ),

          const VerticalDivider(width: 1),

          // 2. Open Session Tabs (Scrollable)
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              itemCount: sessionState.tabs.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 4),
              itemBuilder: (context, index) {
                if (index == sessionState.tabs.length) {
                  return _buildNewTabButton(
                    onTap: () => sessionNotifier.showCatalog(),
                  );
                }
                final tab = sessionState.tabs[index];
                final isActive = tab.id == sessionState.activeTabId;
                return _buildTabItem(
                  tab: tab,
                  isActive: isActive,
                  onSelect: () => sessionNotifier.setActiveTab(tab.id),
                  onClose: () => sessionNotifier.closeTab(tab.id),
                );
              },
            ),
          ),

          const VerticalDivider(width: 1),

          // 3. Quick Connect bar
          _buildQuickConnectBar(),

          // 4. Omni-Bar shortcut / button (Ctrl+K)
          IconButton(
            icon: const Icon(Icons.search,
                size: 20, color: ShellitColors.textSecondary),
            tooltip: 'Command Palette (Ctrl+K)',
            onPressed: widget.onOmniBarOpen,
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildCatalogTab({
    required bool isActive,
    required VoidCallback onSelect,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isActive
                ? ShellitColors.obsidianCard
                : ShellitColors.obsidianBackground,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isActive ? ShellitColors.accentBlue : ShellitColors.border,
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.dns_outlined,
                size: 14,
                color: isActive
                    ? ShellitColors.accentBlue
                    : ShellitColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                'Hosts',
                style: TextStyle(
                  color: isActive
                      ? ShellitColors.textPrimary
                      : ShellitColors.textSecondary,
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewTabButton({required VoidCallback onTap}) {
    return Tooltip(
      message: 'New Tab (Open Hosts Catalog)',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 32,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ShellitColors.obsidianBackground,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: ShellitColors.border, width: 1),
          ),
          child: const Icon(
            Icons.add,
            size: 16,
            color: ShellitColors.accentBlue,
          ),
        ),
      ),
    );
  }

  Widget _buildVaultSelector(VaultState vaultState) {
    final isLocked = !vaultState.isUnlocked;
    final isProtected = vaultState.isInitialized;

    return InkWell(
      onTap: () {
        if (!isProtected) {
          _showSetupPasswordDialog(context);
        } else if (vaultState.isUnlocked) {
          ref.read(vaultProvider.notifier).lock();
        } else {
          _showUnlockDialog(context);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLocked
                  ? Icons.lock
                  : (isProtected ? Icons.lock_open : Icons.shield_outlined),
              size: 16,
              color: isLocked
                  ? ShellitColors.statusRed
                  : (isProtected
                      ? ShellitColors.statusGreen
                      : ShellitColors.accentBlue),
            ),
            const SizedBox(width: 8),
            Text(
              isLocked
                  ? '${vaultState.activeVaultName} (Locked)'
                  : (isProtected
                      ? vaultState.activeVaultName
                      : '${vaultState.activeVaultName} (Open)'),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isLocked
                    ? ShellitColors.statusRed
                    : ShellitColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUnlockDialog(BuildContext context) {
    final passController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: ShellitColors.obsidianCard,
          title: const Row(
            children: [
              Icon(Icons.lock, color: ShellitColors.accentBlue, size: 22),
              SizedBox(width: 8),
              Text('Unlock Vault',
                  style: TextStyle(
                      fontSize: 16, color: ShellitColors.textPrimary)),
            ],
          ),
          content: TextField(
            controller: passController,
            obscureText: true,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter Master Password',
            ),
            onSubmitted: (pwd) async {
              final ok = await ref
                  .read(vaultProvider.notifier)
                  .unlockWithPassword(pwd);
              if (dialogCtx.mounted) {
                if (ok) {
                  Navigator.of(dialogCtx).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Invalid master password'),
                      backgroundColor: ShellitColors.statusRed,
                    ),
                  );
                }
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final ok = await ref
                    .read(vaultProvider.notifier)
                    .unlockWithPassword(passController.text);
                if (dialogCtx.mounted) {
                  if (ok) {
                    Navigator.of(dialogCtx).pop();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Invalid master password'),
                        backgroundColor: ShellitColors.statusRed,
                      ),
                    );
                  }
                }
              },
              child: const Text('Unlock'),
            ),
          ],
        );
      },
    );
  }

  void _showSetupPasswordDialog(BuildContext context) {
    final passController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: ShellitColors.obsidianCard,
          title: const Row(
            children: [
              Icon(Icons.shield, color: ShellitColors.accentBlue, size: 22),
              SizedBox(width: 8),
              Text('Set Master Password',
                  style: TextStyle(
                      fontSize: 16, color: ShellitColors.textPrimary)),
            ],
          ),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your vault is currently unencrypted. Setting a master password encrypts your stored SSH keys and credentials with Argon2id and AES-256-GCM.',
                  style: TextStyle(
                      fontSize: 13, color: ShellitColors.textSecondary),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passController,
                  obscureText: true,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Master Password',
                    hintText: 'Choose a strong password',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    hintText: 'Repeat password',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final pwd = passController.text;
                final confirm = confirmController.text;
                if (pwd.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password cannot be empty'),
                      backgroundColor: ShellitColors.statusRed,
                    ),
                  );
                  return;
                }
                if (pwd != confirm) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Passwords do not match'),
                      backgroundColor: ShellitColors.statusRed,
                    ),
                  );
                  return;
                }

                final ok =
                    await ref.read(vaultProvider.notifier).initializeVault(pwd);
                if (dialogCtx.mounted) {
                  if (ok) {
                    Navigator.of(dialogCtx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Master password set successfully! Vault is protected.'),
                        backgroundColor: ShellitColors.statusGreen,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to set master password'),
                        backgroundColor: ShellitColors.statusRed,
                      ),
                    );
                  }
                }
              },
              child: const Text('Set Password'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTabItem({
    required SessionTab tab,
    required bool isActive,
    required VoidCallback onSelect,
    required VoidCallback onClose,
  }) {
    IconData icon;
    switch (tab.type) {
      case TabType.terminal:
        icon = Icons.terminal;
        break;
      case TabType.sftp:
        icon = Icons.folder_shared_outlined;
        break;
      case TabType.splitTerminal:
        icon = Icons.dashboard_customize_outlined;
        break;
    }

    final isProd = tab.isProduction;

    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        constraints: const BoxConstraints(minWidth: 120, maxWidth: 220),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive
              ? ShellitColors.obsidianCard
              : ShellitColors.obsidianBackground,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive
                ? (isProd ? ShellitColors.statusRed : ShellitColors.accentBlue)
                : ShellitColors.border,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isProd
                  ? ShellitColors.statusRed
                  : (tab.type == TabType.sftp
                      ? ShellitColors.accentCyan
                      : (isActive
                          ? ShellitColors.accentBlue
                          : ShellitColors.textSecondary)),
            ),
            const SizedBox(width: 6),
            if (tab.type == TabType.sftp)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: ShellitColors.accentCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: ShellitColors.accentCyan.withValues(alpha: 0.5),
                    width: 0.5,
                  ),
                ),
                child: const Text(
                  'SFTP',
                  style: TextStyle(
                    color: ShellitColors.accentCyan,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (isProd)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: ShellitColors.envProdBg,
                  borderRadius: BorderRadius.circular(3),
                  border:
                      Border.all(color: ShellitColors.envProdText, width: 0.5),
                ),
                child: const Text(
                  'PROD',
                  style: TextStyle(
                    color: ShellitColors.envProdText,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Expanded(
              child: Text(
                tab.title,
                style: TextStyle(
                  color: isActive
                      ? ShellitColors.textPrimary
                      : ShellitColors.textSecondary,
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: onClose,
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.all(2),
                child:
                    Icon(Icons.close, size: 12, color: ShellitColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickConnectBar() {
    return Container(
      width: 250,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: TextField(
        controller: _quickConnectController,
        style: const TextStyle(fontSize: 12, color: ShellitColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'ssh user@hostname',
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          prefixIcon:
              const Icon(Icons.bolt, color: ShellitColors.accentBlue, size: 16),
          suffixIcon: IconButton(
            icon: const Icon(Icons.arrow_forward,
                size: 14, color: ShellitColors.accentBlue),
            tooltip: 'Connect',
            onPressed: _submitQuickConnect,
          ),
        ),
        onSubmitted: (_) => _submitQuickConnect(),
      ),
    );
  }
}
