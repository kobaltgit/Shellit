import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/material.dart';
import '../../localization/localization_scope.dart';
import '../../theme/shellit_theme.dart';
import '../hosts/os_icon_badge.dart';

/// Renders an ergonomic, cyber-styled Obsidian/Cyan screen while an SSH or SFTP
/// session is being established, displaying live connection stages, an animated
/// neon spinner, a cancellation button, and comprehensive error/retry options.
class TerminalConnectingView extends StatelessWidget {
  final HostEntity? host;
  final String statusMessage;
  final String? errorMessage;
  final bool isConnecting;
  final bool isDisconnected;
  final VoidCallback? onCancel;
  final VoidCallback? onRetry;
  final VoidCallback? onClose;
  final VoidCallback? onUnlockVault;

  const TerminalConnectingView({
    super.key,
    this.host,
    this.statusMessage = 'Establishing SSH connection...',
    this.errorMessage,
    this.isConnecting = true,
    this.isDisconnected = false,
    this.onCancel,
    this.onRetry,
    this.onClose,
    this.onUnlockVault,
  });

  bool get _isVaultLockedError {
    if (errorMessage == null) return false;
    final msg = errorMessage!.toLowerCase();
    return msg.contains('мастер-пароль') ||
        msg.contains('заблокировано') ||
        msg.contains('locked') ||
        msg.contains('vault is locked');
  }

  @override
  Widget build(BuildContext context) {
    final isProd = host?.isProduction ?? false;
    final isStage = host?.environment == HostEnvironment.staging;

    return Center(
      child: SingleChildScrollView(
        child: Container(
          width: 480,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: ShellitColors.obsidianCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: errorMessage != null
                  ? (_isVaultLockedError
                      ? Colors.amber.withValues(alpha: 0.6)
                      : ShellitColors.statusRed.withValues(alpha: 0.5))
                  : (isProd
                      ? ShellitColors.envProdText.withValues(alpha: 0.4)
                      : ShellitColors.border),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              if (isConnecting && errorMessage == null && !isDisconnected)
                BoxShadow(
                  color: ShellitColors.accentCyan.withValues(alpha: 0.05),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Thin progress bar at top of card while connecting
                if (isConnecting && errorMessage == null && !isDisconnected)
                  const LinearProgressIndicator(
                    minHeight: 3,
                    backgroundColor: ShellitColors.obsidianBackground,
                    color: ShellitColors.accentCyan,
                  ),

                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header: Host info & Environment badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          OsIconBadge(
                            os: host?.osType ?? OsType.genericServer,
                            size: 32,
                            padding: 8,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        host?.label ??
                                            context.tr(
                                                'connecting.connecting_host',
                                                defaultText: 'Connecting Host'),
                                        style: const TextStyle(
                                          color: ShellitColors.textPrimary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isProd) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: ShellitColors.envProdBg,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(
                                            color: ShellitColors.envProdText,
                                            width: 0.5,
                                          ),
                                        ),
                                        child: Text(
                                          context.tr('hosts.card.env_prod',
                                              defaultText: 'PROD'),
                                          style: const TextStyle(
                                            color: ShellitColors.envProdText,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ] else if (isStage) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: ShellitColors.envStageBg,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(
                                            color: ShellitColors.envStageText,
                                            width: 0.5,
                                          ),
                                        ),
                                        child: Text(
                                          context.tr('hosts.card.env_stage',
                                              defaultText: 'STAGE'),
                                          style: const TextStyle(
                                            color: ShellitColors.envStageText,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  host != null
                                      ? '${host!.username}@${host!.hostname}:${host!.port}'
                                      : context.tr(
                                          'connecting.resolving_endpoint',
                                          defaultText: 'Resolving endpoint...'),
                                  style: const TextStyle(
                                    color: ShellitColors.textSecondary,
                                    fontSize: 12,
                                    fontFamily: 'JetBrains Mono',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      const Divider(color: ShellitColors.border, height: 1),
                      const SizedBox(height: 24),

                      // Content: Disconnected Standby / Connecting Spinner / Error
                      if (errorMessage != null)
                        _buildErrorContent(context)
                      else if (isDisconnected || (!isConnecting && errorMessage == null))
                        _buildDisconnectedContent(context)
                      else
                        _buildConnectingContent(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDisconnectedContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Standby Power Icon
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ShellitColors.obsidianBackground,
            border: Border.all(
              color: ShellitColors.border.withValues(alpha: 0.8),
              width: 1.2,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.power_settings_new_rounded,
              size: 28,
              color: ShellitColors.textMuted,
            ),
          ),
        ),
        const SizedBox(height: 18),

        Text(
          statusMessage.isNotEmpty
              ? statusMessage
              : context.tr(
                  'connecting.session_restored',
                  defaultText: 'Session Restored (Disconnected)',
                ),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: ShellitColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          context.tr(
            'connecting.session_restored_subtitle',
            defaultText:
                'Previous session tab was restored in standby mode.',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: ShellitColors.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 24),

        // Action Buttons: [ ⏻ Connect ] & [ Close Tab ]
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(
                Icons.power_settings_new_rounded,
                size: 16,
              ),
              label: Text(
                context.tr(
                  'connecting.connect_btn',
                  defaultText: 'Connect',
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ShellitColors.accentCyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            if (onClose != null) ...[
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded, size: 15),
                label: Text(
                  context.tr(
                    'connecting.btn_close_tab',
                    defaultText: 'Close Tab',
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ShellitColors.textSecondary,
                  side: const BorderSide(color: ShellitColors.border),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  textStyle: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildConnectingContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pulsing / Glowing Spinner
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ShellitColors.obsidianBackground,
            boxShadow: [
              BoxShadow(
                color: ShellitColors.accentCyan.withValues(alpha: 0.2),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Center(
            child: SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.8,
                valueColor:
                    AlwaysStoppedAnimation<Color>(ShellitColors.accentCyan),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Live status message
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            statusMessage,
            key: ValueKey(statusMessage),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ShellitColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Multi-step connection pipeline timeline
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: ShellitColors.obsidianBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: ShellitColors.border, width: 0.8),
          ),
          child: Column(
            children: [
              _buildStepItem(
                label: context.tr('connecting.step_decrypt',
                    defaultText: 'Decrypt credentials & keys'),
                isActive: statusMessage.contains('credentials') ||
                    statusMessage.contains('key'),
                isDone: !statusMessage.contains('credentials') &&
                    !statusMessage.contains('key') &&
                    !statusMessage.startsWith('Connecting...'),
              ),
              const SizedBox(height: 8),
              _buildStepItem(
                label: context.tr('connecting.step_tcp',
                    defaultText: 'Connect TCP socket'),
                isActive: statusMessage.contains('socket') ||
                    statusMessage.startsWith('Connecting...'),
                isDone: statusMessage.contains('handshake') ||
                    statusMessage.contains('Authenticating') ||
                    statusMessage.contains('shell') ||
                    statusMessage.contains('SFTP'),
              ),
              const SizedBox(height: 8),
              _buildStepItem(
                label: context.tr('connecting.step_handshake',
                    defaultText: 'SSH protocol handshake'),
                isActive: statusMessage.contains('handshake'),
                isDone: statusMessage.contains('Authenticating') ||
                    statusMessage.contains('shell') ||
                    statusMessage.contains('SFTP'),
              ),
              const SizedBox(height: 8),
              _buildStepItem(
                label: context.tr('connecting.step_auth',
                    defaultText: 'User authentication'),
                isActive: statusMessage.contains('Authenticating'),
                isDone: statusMessage.contains('shell') ||
                    statusMessage.contains('SFTP'),
              ),
              const SizedBox(height: 8),
              _buildStepItem(
                label: context.tr('connecting.step_subsystem',
                    defaultText: 'Allocate remote shell / subsystem'),
                isActive: statusMessage.contains('shell') ||
                    statusMessage.contains('SFTP') ||
                    statusMessage.contains('subsystem'),
                isDone: false,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Cancel Button
        if (onCancel != null)
          OutlinedButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.close, size: 14),
            label: Text(context.tr('connecting.cancel_btn',
                defaultText: 'Cancel Connection')),
            style: OutlinedButton.styleFrom(
              foregroundColor: ShellitColors.textSecondary,
              side: const BorderSide(color: ShellitColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStepItem({
    required String label,
    required bool isActive,
    required bool isDone,
  }) {
    IconData icon;
    Color color;

    if (isDone) {
      icon = Icons.check_circle_rounded;
      color = ShellitColors.statusGreen;
    } else if (isActive) {
      icon = Icons.radio_button_checked_rounded;
      color = ShellitColors.accentCyan;
    } else {
      icon = Icons.radio_button_unchecked_rounded;
      color = ShellitColors.textMuted;
    }

    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDone
                  ? ShellitColors.textPrimary
                  : (isActive
                      ? ShellitColors.accentCyan
                      : ShellitColors.textMuted),
              fontWeight:
                  isActive || isDone ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorContent(BuildContext context) {
    if (_isVaultLockedError) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.amber.withValues(alpha: 0.15),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.2),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.lock_outline_rounded,
                color: Colors.amber,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('connecting.vault_locked_title',
                defaultText: 'Master Password Required'),
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              context.tr('connecting.vault_locked_desc',
                  defaultText:
                      'Credentials for this host (password or key) are encrypted in the vault. Enter master password to connect.'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ShellitColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              if (onUnlockVault != null)
                ElevatedButton.icon(
                  onPressed: onUnlockVault,
                  icon: const Icon(Icons.lock_open_rounded, size: 16),
                  label: Text(context.tr('vault.unlock_btn',
                      defaultText: 'Unlock Vault')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ShellitColors.accentBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              if (onClose != null)
                OutlinedButton.icon(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, size: 14),
                  label: Text(
                      context.tr('common.close_tab', defaultText: 'Close Tab')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ShellitColors.textSecondary,
                    side: const BorderSide(color: ShellitColors.border),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
            ],
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ShellitColors.statusRed.withValues(alpha: 0.12),
          ),
          child: const Center(
            child: Icon(
              Icons.error_outline_rounded,
              color: ShellitColors.statusRed,
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          context.tr('connecting.failed_title',
              defaultText: 'Connection Failed'),
          style: const TextStyle(
            color: ShellitColors.statusRed,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ShellitColors.obsidianBackground,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: ShellitColors.statusRed.withValues(alpha: 0.3),
            ),
          ),
          child: SelectableText(
            errorMessage ??
                context.tr('common.unknown_error',
                    defaultText: 'Unknown error occurred'),
            style: const TextStyle(
              color: ShellitColors.textSecondary,
              fontSize: 11,
              fontFamily: 'JetBrains Mono',
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (onRetry != null)
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 14),
                label: Text(context.tr('common.retry', defaultText: 'Retry')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ShellitColors.accentBlue,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            if (onRetry != null && onClose != null) const SizedBox(width: 12),
            if (onClose != null)
              OutlinedButton.icon(
                onPressed: onClose,
                icon: const Icon(Icons.close, size: 14),
                label: Text(
                    context.tr('common.close_tab', defaultText: 'Close Tab')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ShellitColors.textSecondary,
                  side: const BorderSide(color: ShellitColors.border),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
