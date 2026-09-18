import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_ui/terminal_ui.dart';

enum TunnelForwardType { local, remote }

class PortForwardItem {
  final String id;
  final String label;
  final TunnelForwardType type;
  final int localPort;
  final String remoteHost;
  final int remotePort;
  bool isRunning;

  PortForwardItem({
    required this.id,
    required this.label,
    required this.type,
    required this.localPort,
    required this.remoteHost,
    required this.remotePort,
    this.isRunning = false,
  });
}

final tunnelsListProvider = StateProvider<List<PortForwardItem>>((ref) {
  return [
    PortForwardItem(
      id: 'rule_1',
      label: 'PostgreSQL Database Tunnel',
      type: TunnelForwardType.local,
      localPort: 5433,
      remoteHost: '127.0.0.1',
      remotePort: 5432,
      isRunning: false,
    ),
    PortForwardItem(
      id: 'rule_2',
      label: 'Remote Web Preview (8080)',
      type: TunnelForwardType.remote,
      localPort: 3000,
      remoteHost: '0.0.0.0',
      remotePort: 8080,
      isRunning: false,
    ),
  ];
});

class TunnelsScreen extends ConsumerWidget {
  const TunnelsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(tunnelsListProvider);

    return Scaffold(
      backgroundColor: ShellitColors.obsidianBackground,
      appBar: AppBar(
        title: Text(
          context.tr('tunnels.title', defaultText: 'Port Forwarding & Tunnels'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        backgroundColor: ShellitColors.obsidianBackground,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_circle_outline, size: 16),
              label: Text(
                context.tr('tunnels.btn_new', defaultText: 'New Tunnel'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ShellitColors.accentBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
              ),
              onPressed: () => _showAddTunnelDialog(context, ref),
            ),
          ),
        ],
      ),
      body: rules.isEmpty
          ? Center(
              child: Text(
                context.tr('tunnels.empty_title', defaultText: 'No active port forwarding rules'),
                style: const TextStyle(color: ShellitColors.textMuted),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: rules.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final rule = rules[index];
                return Card(
                  color: ShellitColors.obsidianCard,
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: ShellitColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            (rule.isRunning
                                    ? ShellitColors.statusGreen
                                    : ShellitColors.textMuted)
                                .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.alt_route,
                        color: rule.isRunning
                            ? ShellitColors.statusGreen
                            : ShellitColors.textMuted,
                        size: 20,
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          rule.label,
                          style: const TextStyle(
                            color: ShellitColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: ShellitColors.border,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            rule.type == TunnelForwardType.local
                                ? context.tr('tunnels.type_local', defaultText: 'LOCAL (L)')
                                : context.tr('tunnels.type_remote', defaultText: 'REMOTE (R)'),
                            style: const TextStyle(
                              color: ShellitColors.accentCyan,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      '127.0.0.1:${rule.localPort} ➔ ${rule.remoteHost}:${rule.remotePort}',
                      style: const TextStyle(
                        color: ShellitColors.textSecondary,
                        fontFamily: 'JetBrains Mono',
                        fontSize: 12,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: rule.isRunning,
                          activeThumbColor: ShellitColors.statusGreen,
                          onChanged: (val) {
                            ref.read(tunnelsListProvider.notifier).update((
                              state,
                            ) {
                              return state.map((r) {
                                if (r.id == rule.id) {
                                  r.isRunning = val;
                                }
                                return r;
                              }).toList();
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: ShellitColors.statusRed,
                            size: 18,
                          ),
                          onPressed: () {
                            ref
                                .read(tunnelsListProvider.notifier)
                                .update(
                                  (state) => state
                                      .where((r) => r.id != rule.id)
                                      .toList(),
                                );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showAddTunnelDialog(BuildContext context, WidgetRef ref) {
    final labelCtrl = TextEditingController();
    final localPortCtrl = TextEditingController(text: '8080');
    final remoteHostCtrl = TextEditingController(text: '127.0.0.1');
    final remotePortCtrl = TextEditingController(text: '80');
    TunnelForwardType selectedType = TunnelForwardType.local;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: ShellitColors.obsidianCard,
          title: Text(
            context.tr('tunnels.dialog_title', defaultText: 'Add Port Forwarding Rule'),
            style: const TextStyle(color: ShellitColors.textPrimary, fontSize: 16),
          ),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: labelCtrl,
                  style: const TextStyle(
                    color: ShellitColors.textPrimary,
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    labelText: context.tr(
                      'tunnels.rule_label',
                      defaultText: 'Rule Label (e.g. Redis Dev Tunnel)',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<TunnelForwardType>(
                  initialValue: selectedType,
                  decoration: InputDecoration(
                    labelText: context.tr('tunnels.forward_type', defaultText: 'Forward Type'),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: TunnelForwardType.local,
                      child: Text(
                        context.tr('tunnels.forward_local_opt', defaultText: 'Local Forward (-L)'),
                      ),
                    ),
                    DropdownMenuItem(
                      value: TunnelForwardType.remote,
                      child: Text(
                        context.tr('tunnels.forward_remote_opt', defaultText: 'Remote Forward (-R)'),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => selectedType = val);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: localPortCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          color: ShellitColors.textPrimary,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          labelText: context.tr('tunnels.local_port', defaultText: 'Local Port'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: remotePortCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          color: ShellitColors.textPrimary,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          labelText: context.tr('tunnels.remote_port', defaultText: 'Remote Port'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: remoteHostCtrl,
                  style: const TextStyle(
                    color: ShellitColors.textPrimary,
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    labelText: context.tr('tunnels.remote_host', defaultText: 'Remote Target Host'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.tr('common.cancel', defaultText: 'Cancel')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ShellitColors.accentBlue,
              ),
              onPressed: () {
                if (labelCtrl.text.isNotEmpty) {
                  ref
                      .read(tunnelsListProvider.notifier)
                      .update(
                        (state) => [
                          ...state,
                          PortForwardItem(
                            id: 'rule_${DateTime.now().millisecondsSinceEpoch}',
                            label: labelCtrl.text.trim(),
                            type: selectedType,
                            localPort: int.tryParse(localPortCtrl.text) ?? 8080,
                            remoteHost: remoteHostCtrl.text.trim(),
                            remotePort: int.tryParse(remotePortCtrl.text) ?? 80,
                          ),
                        ],
                      );
                  Navigator.pop(ctx);
                }
              },
              child: Text(
                context.tr('tunnels.btn_add', defaultText: 'Add Rule'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
