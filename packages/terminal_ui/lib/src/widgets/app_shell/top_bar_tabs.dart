import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../localization/localization_scope.dart';
import '../../providers/session_manager_provider.dart';
import '../../providers/vault_provider.dart';
import '../../theme/shellit_theme.dart';
import '../hosts/os_icon_badge.dart';
import 'tab_context_menu.dart';
import 'tab_drag_payload.dart';
import 'tab_overflow_menu.dart';

class TopBarTabs extends ConsumerStatefulWidget {
  final ValueChanged<String>? onQuickConnect;
  final VoidCallback? onOmniBarOpen;
  final Future<void> Function(SessionTab)? onDuplicateTab;
  final Future<void> Function(HostEntity)? onOpenSftp;
  final Future<void> Function(SessionTab)? onReconnectTab;
  final Widget? trailing;
  final VoidCallback? onWindowMinimize;
  final VoidCallback? onWindowMaximize;
  final VoidCallback? onWindowClose;
  final bool isWindowMaximized;
  final Widget Function(BuildContext context, Widget child)? dragAreaBuilder;

  const TopBarTabs({
    super.key,
    this.onQuickConnect,
    this.onOmniBarOpen,
    this.onDuplicateTab,
    this.onOpenSftp,
    this.onReconnectTab,
    this.trailing,
    this.onWindowMinimize,
    this.onWindowMaximize,
    this.onWindowClose,
    this.isWindowMaximized = false,
    this.dragAreaBuilder,
  });

  @override
  ConsumerState<TopBarTabs> createState() => _TopBarTabsState();
}

class _TopBarTabsState extends ConsumerState<TopBarTabs> {
  final TextEditingController _quickConnectController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _canScrollLeft = false;
  bool _canScrollRight = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateScrollIndicators);
  }

  void _updateScrollIndicators() {
    if (!_scrollController.hasClients) return;
    final canLeft = _scrollController.offset > 5;
    final canRight = _scrollController.offset <
        _scrollController.position.maxScrollExtent - 5;
    if (canLeft != _canScrollLeft || canRight != _canScrollRight) {
      setState(() {
        _canScrollLeft = canLeft;
        _canScrollRight = canRight;
      });
    }
  }

  @override
  void dispose() {
    _quickConnectController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollBy(double offset) {
    if (!_scrollController.hasClients) return;
    final target = (_scrollController.offset + offset)
        .clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }


  @override
  Widget build(BuildContext context) {
    final vaultState = ref.watch(vaultProvider);
    final sessionState = ref.watch(sessionManagerProvider);
    final sessionNotifier = ref.read(sessionManagerProvider.notifier);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateScrollIndicators();
    });

    final topBarContent = Container(
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

          // Scroll Left Button
          if (_canScrollLeft)
            IconButton(
              icon: const Icon(Icons.chevron_left, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 38),
              color: ShellitColors.textSecondary,
              onPressed: () => _scrollBy(-160),
            ),

          // 2. Open Session Tabs (Scrollable via Mouse Wheel & Drag)
          Expanded(
            child: Listener(
              onPointerSignal: (pointerSignal) {
                if (pointerSignal is PointerScrollEvent) {
                  if (_scrollController.hasClients) {
                    final target = (_scrollController.offset +
                            pointerSignal.scrollDelta.dy)
                        .clamp(0.0, _scrollController.position.maxScrollExtent);
                    _scrollController.jumpTo(target);
                  }
                }
              },
              child: ListView.separated(
                controller: _scrollController,
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
                  if (tab.isPinned) {
                    return _buildPinnedSquareTab(
                      tab: tab,
                      isActive: isActive,
                      onSelect: () => sessionNotifier.setActiveTab(tab.id),
                    );
                  }
                  return _buildTabItem(
                    tab: tab,
                    isActive: isActive,
                    onSelect: () => sessionNotifier.setActiveTab(tab.id),
                    onClose: () => sessionNotifier.closeTab(tab.id),
                  );
                },
              ),
            ),
          ),

          // Scroll Right Button
          if (_canScrollRight)
            IconButton(
              icon: const Icon(Icons.chevron_right, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 38),
              color: ShellitColors.textSecondary,
              onPressed: () => _scrollBy(160),
            ),

          // Tab Overflow Dropdown Button
          if (sessionState.tabs.length > 2)
            Tooltip(
              message: context
                  .tr('tabs.overflow_all_tabs',
                      defaultText: 'All Open Tabs ({count})')
                  .replaceAll('{count}', sessionState.tabs.length.toString()),
              child: InkWell(
                onTap: () => TabOverflowMenu.show(
                  context,
                  onSelectTab: (id) {
                    sessionNotifier.setActiveTab(id);
                  },
                  onCloseTab: (id) {
                    sessionNotifier.closeTab(id);
                  },
                ),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: ShellitColors.obsidianBackground,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: ShellitColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.layers_outlined,
                          size: 14, color: ShellitColors.accentBlue),
                      const SizedBox(width: 4),
                      Text(
                        '${sessionState.tabs.length}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: ShellitColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.keyboard_arrow_down,
                          size: 14, color: ShellitColors.textSecondary),
                    ],
                  ),
                ),
              ),
            ),

          const SizedBox(width: 8),
        ],
      ),
    );

    if (widget.dragAreaBuilder != null) {
      return widget.dragAreaBuilder!(context, topBarContent);
    }
    return topBarContent;
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
                context.tr('hosts.title', defaultText: 'Hosts'),
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
      message: context.tr('tabs.new_tab_tooltip',
          defaultText: 'New Tab (Open Hosts Catalog)'),
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
                  ? '${vaultState.activeVaultName} (${context.tr('vault.status_locked', defaultText: 'Locked')})'
                  : (isProtected
                      ? vaultState.activeVaultName
                      : '${vaultState.activeVaultName} (${context.tr('vault.status_open', defaultText: 'Open')})'),
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
          title: Row(
            children: [
              const Icon(Icons.lock, color: ShellitColors.accentBlue, size: 22),
              const SizedBox(width: 8),
              Text(
                context.tr('vault.unlock_title',
                    defaultText: 'Unlock Shellit Vault'),
                style: const TextStyle(
                    fontSize: 16, color: ShellitColors.textPrimary),
              ),
            ],
          ),
          content: TextField(
            controller: passController,
            obscureText: true,
            autofocus: true,
            decoration: InputDecoration(
              hintText: context.tr('vault.unlock_password_label',
                  defaultText: 'Master Password'),
            ),
            onSubmitted: (pwd) async {
              final ok = await ref
                  .read(vaultProvider.notifier)
                  .unlockWithPassword(pwd);
              if (dialogCtx.mounted) {
                if (ok) {
                  Navigator.of(dialogCtx).pop();
                } else {
                  final err = ref.read(vaultProvider).errorMessage ??
                      context.tr('vault.unlock_failed',
                          defaultText:
                              'Invalid master password. Please try again.');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(err),
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
              child: Text(context.tr('common.cancel', defaultText: 'Cancel')),
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
                    final err = ref.read(vaultProvider).errorMessage ??
                        context.tr('vault.unlock_failed',
                            defaultText:
                                'Invalid master password. Please try again.');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(err),
                        backgroundColor: ShellitColors.statusRed,
                      ),
                    );
                  }
                }
              },
              child:
                  Text(context.tr('vault.unlock_btn', defaultText: 'Unlock')),
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
          title: Row(
            children: [
              const Icon(Icons.shield,
                  color: ShellitColors.accentBlue, size: 22),
              const SizedBox(width: 8),
              Text(
                context.tr('vault.setup_password_title',
                    defaultText: 'Set Master Password'),
                style: const TextStyle(
                    fontSize: 16, color: ShellitColors.textPrimary),
              ),
            ],
          ),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('vault.setup_password_desc',
                      defaultText:
                          'Your vault is currently unencrypted. Setting a master password encrypts your stored SSH keys and credentials with Argon2id and AES-256-GCM.'),
                  style: const TextStyle(
                      fontSize: 13, color: ShellitColors.textSecondary),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passController,
                  obscureText: true,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: context.tr('vault.setup_password_label',
                        defaultText: 'Master Password'),
                    hintText: context.tr('vault.setup_password_hint',
                        defaultText: 'Choose a strong password'),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: context.tr('vault.confirm_password_label',
                        defaultText: 'Confirm Password'),
                    hintText: context.tr('vault.confirm_password_hint',
                        defaultText: 'Repeat password'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(context.tr('common.cancel', defaultText: 'Cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                final pwd = passController.text;
                final confirm = confirmController.text;
                if (pwd.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.tr('vault.err_password_empty',
                          defaultText: 'Password cannot be empty')),
                      backgroundColor: ShellitColors.statusRed,
                    ),
                  );
                  return;
                }
                if (pwd != confirm) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.tr('vault.err_passwords_mismatch',
                          defaultText: 'Passwords do not match')),
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
                      SnackBar(
                        content: Text(context.tr('vault.setup_password_success',
                            defaultText:
                                'Master password set successfully! Vault is protected.')),
                        backgroundColor: ShellitColors.statusGreen,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.tr('vault.setup_password_failed',
                            defaultText: 'Failed to set master password')),
                        backgroundColor: ShellitColors.statusRed,
                      ),
                    );
                  }
                }
              },
              child: Text(context.tr('vault.setup_password_btn',
                  defaultText: 'Set Password')),
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
      case TabType.localTerminal:
        icon = Icons.terminal;
        break;
    }

    final isProd = tab.isProduction;
    final isPinned = tab.isPinned;
    final minW = isPinned ? 48.0 : 120.0;
    final maxW = isPinned ? 170.0 : 220.0;

    final tabWidget = InkWell(
      onTap: onSelect,
      onSecondaryTapUp: (details) {
        TabContextMenu.show(
          context: context,
          position: details.globalPosition,
          tab: tab,
          ref: ref,
          onDuplicate: widget.onDuplicateTab != null
              ? () => widget.onDuplicateTab!(tab)
              : null,
          onOpenSftp: widget.onOpenSftp != null && tab.host != null
              ? () => widget.onOpenSftp!(tab.host!)
              : null,
          onReconnect: widget.onReconnectTab != null
              ? () => widget.onReconnectTab!(tab)
              : null,
        );
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        constraints: BoxConstraints(minWidth: minW, maxWidth: maxW),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive
              ? ShellitColors.obsidianCard
              : ShellitColors.obsidianBackground,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: tab.colorTag ??
                (tab.connectionError != null
                    ? ShellitColors.statusRed
                    : (tab.isConnecting
                        ? ShellitColors.accentCyan.withValues(alpha: 0.6)
                        : (isActive
                            ? (isProd
                                ? ShellitColors.statusRed
                                : ShellitColors.accentBlue)
                            : ShellitColors.border))),
            width: tab.colorTag != null ? 1.8 : (isActive ? 1.5 : 1.0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (tab.colorTag != null) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: tab.colorTag,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
            ],
            if (tab.isConnecting) ...[
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(ShellitColors.accentCyan),
                ),
              ),
            ] else if (tab.connectionError != null) ...[
              const Icon(
                Icons.error_outline_rounded,
                size: 14,
                color: ShellitColors.statusRed,
              ),
            ] else ...[
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
            ],
            if (isPinned) ...[
              const SizedBox(width: 4),
              const Icon(Icons.push_pin,
                  size: 11, color: ShellitColors.accentBlue),
            ],
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
                child: Text(
                  context.tr('hosts.card.env_prod', defaultText: 'PROD'),
                  style: const TextStyle(
                    color: ShellitColors.envProdText,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (tab.type == TabType.localTerminal)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: ShellitColors.obsidianBackground,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: ShellitColors.borderLight,
                    width: 0.5,
                  ),
                ),
                child: Text(
                  context.tr('local_terminal.tab.badge', defaultText: 'LOCAL'),
                  style: const TextStyle(
                    color: ShellitColors.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Flexible(
              child: Text(
                tab.displayTitle,
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
            if (!isPinned) ...[
              const SizedBox(width: 4),
              InkWell(
                onTap: onClose,
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(Icons.close,
                      size: 12, color: ShellitColors.textMuted),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    // Wrap in Draggable for Drag & Drop into split pane slots
    return Draggable<TabDragPayload>(
      data: TabDragPayload(
        tabId: tab.id,
        host: tab.host,
        title: tab.displayTitle,
        type: tab.type,
      ),
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: ShellitColors.obsidianCard.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: ShellitColors.accentBlue, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: ShellitColors.accentBlue),
              const SizedBox(width: 8),
              Text(
                tab.displayTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.25,
        child: tabWidget,
      ),
      child: tabWidget,
    );
  }

  Widget _buildPinnedSquareTab({
    required SessionTab tab,
    required bool isActive,
    required VoidCallback onSelect,
  }) {
    final isProd = tab.isProduction;
    final tabWidget = Tooltip(
      message: '${tab.displayTitle}${isProd ? ' [PROD]' : ''} (Pinned)',
      child: InkWell(
        onTap: onSelect,
        onSecondaryTapUp: (details) {
          TabContextMenu.show(
            context: context,
            position: details.globalPosition,
            tab: tab,
            ref: ref,
            onDuplicate: widget.onDuplicateTab != null
                ? () => widget.onDuplicateTab!(tab)
                : null,
            onOpenSftp: widget.onOpenSftp != null && tab.host != null
                ? () => widget.onOpenSftp!(tab.host!)
                : null,
            onReconnect: widget.onReconnectTab != null
                ? () => widget.onReconnectTab!(tab)
                : null,
          );
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isActive
                ? ShellitColors.obsidianCard
                : ShellitColors.obsidianBackground,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: tab.colorTag ??
                  (tab.connectionError != null
                      ? ShellitColors.statusRed
                      : (tab.isConnecting
                          ? ShellitColors.accentCyan
                          : (isActive
                              ? (isProd
                                  ? ShellitColors.statusRed
                                  : ShellitColors.accentBlue)
                              : ShellitColors.border))),
              width: tab.colorTag != null ? 1.8 : (isActive ? 1.5 : 1.0),
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (tab.host != null)
                OsIconBadge(
                  os: tab.host!.osType,
                  size: 16,
                )
              else
                Text(
                  tab.displayTitle.isNotEmpty
                      ? tab.displayTitle[0].toUpperCase()
                      : 'T',
                  style: TextStyle(
                    color: isActive
                        ? ShellitColors.accentBlue
                        : ShellitColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              const Positioned(
                top: 2,
                right: 2,
                child: Icon(
                  Icons.push_pin,
                  size: 9,
                  color: ShellitColors.accentBlue,
                ),
              ),
              if (isProd)
                Positioned(
                  bottom: 2,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: ShellitColors.statusRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    return Draggable<TabDragPayload>(
      data: TabDragPayload(
        tabId: tab.id,
        host: tab.host,
        title: tab.displayTitle,
        type: tab.type,
      ),
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: ShellitColors.obsidianCard.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: ShellitColors.accentBlue, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.push_pin,
                  size: 12, color: ShellitColors.accentBlue),
              const SizedBox(width: 6),
              Text(
                tab.displayTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.25, child: tabWidget),
      child: tabWidget,
    );
  }
}
