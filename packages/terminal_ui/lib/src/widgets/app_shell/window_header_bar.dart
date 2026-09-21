import 'package:flutter/material.dart';
import '../../localization/localization_scope.dart';
import '../../theme/shellit_theme.dart';
import 'shellit_logo.dart';
import 'window_controls.dart';

class WindowHeaderBar extends StatefulWidget {
  final ValueChanged<String>? onQuickConnect;
  final VoidCallback? onOmniBarOpen;
  final Widget? trailing;
  final VoidCallback? onWindowMinimize;
  final VoidCallback? onWindowMaximize;
  final VoidCallback? onWindowClose;
  final bool isWindowMaximized;
  final Widget Function(BuildContext context, Widget child)? dragAreaBuilder;

  const WindowHeaderBar({
    super.key,
    this.onQuickConnect,
    this.onOmniBarOpen,
    this.trailing,
    this.onWindowMinimize,
    this.onWindowMaximize,
    this.onWindowClose,
    this.isWindowMaximized = false,
    this.dragAreaBuilder,
  });

  @override
  State<WindowHeaderBar> createState() => _WindowHeaderBarState();
}

class _WindowHeaderBarState extends State<WindowHeaderBar> {
  void _showQuickConnectDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: ShellitColors.obsidianCard,
          title: Row(
            children: [
              const Icon(Icons.bolt, color: ShellitColors.accentBlue, size: 22),
              const SizedBox(width: 8),
              Text(
                context.tr('hosts.quick_connect', defaultText: 'Quick Connect'),
                style: const TextStyle(
                  fontSize: 16,
                  color: ShellitColors.textPrimary,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(
                    'hosts.quick_connect_desc',
                    defaultText:
                        'Enter target host in format: [user@]hostname[:port]',
                  ),
                  style: const TextStyle(
                    fontSize: 12,
                    color: ShellitColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  autofocus: true,
                  style: const TextStyle(
                    fontSize: 13,
                    color: ShellitColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'user@192.168.1.100:22',
                    prefixIcon: Icon(
                      Icons.terminal,
                      size: 16,
                      color: ShellitColors.accentBlue,
                    ),
                  ),
                  onSubmitted: (val) {
                    final target = val.trim();
                    if (target.isNotEmpty) {
                      Navigator.of(dialogCtx).pop();
                      widget.onQuickConnect?.call(target);
                    }
                  },
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
              onPressed: () {
                final target = controller.text.trim();
                if (target.isNotEmpty) {
                  Navigator.of(dialogCtx).pop();
                  widget.onQuickConnect?.call(target);
                }
              },
              child: Text(context.tr('common.connect', defaultText: 'Connect')),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickConnectButton() {
    return Tooltip(
      message: context.tr(
        'hosts.quick_connect_tooltip',
        defaultText: 'Quick Connect (Ctrl+Q)',
      ),
      child: InkWell(
        onTap: _showQuickConnectDialog,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: ShellitColors.obsidianBackground,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: ShellitColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bolt, size: 14, color: ShellitColors.accentBlue),
              const SizedBox(width: 4),
              Text(
                context.tr('hosts.quick_connect', defaultText: 'Quick Connect'),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: ShellitColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: const BoxDecoration(
        color: ShellitColors.obsidianSidebar,
        border: Border(
          bottom: BorderSide(color: ShellitColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          // 1. Logo (icon only without app title text)
          const SizedBox(width: 10),
          const ShellitLogo(size: 22, borderRadius: 5),
          const SizedBox(width: 8),

          // 2. Central Draggable Area
          Expanded(
            child: widget.dragAreaBuilder != null
                ? widget.dragAreaBuilder!(
                    context,
                    Container(color: Colors.transparent),
                  )
                : const SizedBox.expand(),
          ),

          // 3. Quick Connect button
          _buildQuickConnectButton(),

          // 4. Omni-Bar shortcut / button (Ctrl+K)
          IconButton(
            icon: const Icon(
              Icons.search,
              size: 18,
              color: ShellitColors.textSecondary,
            ),
            tooltip: context.tr(
              'omni.command_palette_tooltip',
              defaultText: 'Command Palette (Ctrl+K)',
            ),
            onPressed: widget.onOmniBarOpen,
            splashRadius: 16,
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 4),

          // 5. Trailing widget (e.g. MCP indicator)
          if (widget.trailing != null) widget.trailing!,

          // 6. Native Window Controls (Minimize, Maximize, Close)
          WindowControls(
            onMinimize: widget.onWindowMinimize,
            onMaximize: widget.onWindowMaximize,
            onClose: widget.onWindowClose,
            isMaximized: widget.isWindowMaximized,
          ),
          if (widget.onWindowClose == null) const SizedBox(width: 8),
        ],
      ),
    );
  }
}
