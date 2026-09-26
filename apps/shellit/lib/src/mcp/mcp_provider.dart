import 'dart:convert';
import 'dart:io';

import 'package:core_foundation/core_foundation.dart';
import 'package:desktop_plugin_sdk/desktop_plugin_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_ui/terminal_ui.dart';

import '../di/app_providers.dart';

/// Provider for the singleton McpServerService in Shellit Desktop
final mcpServerServiceProvider = Provider<McpServerService>((ref) {
  final service = McpServerService(port: McpServerService.defaultPort);

  // Auto-start listening on desktop loopback port
  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    service.start().catchError((e) {
      AppLogger.w('Failed to auto-start McpServerService: $e');
      return service.port;
    });
  }

  service.setToolHandler((toolName, arguments) async {
    switch (toolName) {
      case 'shellit_list_servers':
        final hostRepo = ref.read(appHostRepositoryProvider);
        final hosts = await hostRepo.getAllHosts();
        final serverList = hosts
            .map(
              (h) => {
                'id': h.id,
                'label': h.label,
                'hostname': h.hostname,
                'port': h.port,
                'username': h.username,
                'environment': h.environment.name,
                'osType': h.osType.name,
                'lastPingLatencyMs': h.lastPingLatencyMs,
                'dangerousCommandProtection': h.dangerousCommandProtection,
              },
            )
            .toList();

        return {'text': json.encode(serverList), 'isError': false};

      case 'shellit_list_active_sessions':
        final sessionManager = ref.read(sessionManagerProvider);
        final sessionList = sessionManager.tabs
            .map(
              (tab) => {
                'id': tab.id,
                'title': tab.title,
                'type': tab.type.name,
                'hostId': tab.host?.id,
                'hostLabel': tab.host?.label,
                'hostname': tab.host?.hostname,
                'environment': tab.host?.environment.name,
                'isConnected': tab.terminalSession?.underlyingClient != null,
              },
            )
            .toList();

        return {'text': json.encode(sessionList), 'isError': false};

      case 'shellit_exec_command':
        final command = arguments['command'] as String?;
        if (command == null || command.trim().isEmpty) {
          return {
            'text': 'Error: Missing required parameter "command"',
            'isError': true,
          };
        }

        final serverId = arguments['serverId'] as String?;
        final sessionManager = ref.read(sessionManagerProvider);

        // Find target tab
        SessionTab? targetTab;
        if (serverId != null && serverId.isNotEmpty) {
          try {
            targetTab = sessionManager.tabs.firstWhere(
              (t) =>
                  t.host?.id == serverId ||
                  (t.host?.label.toLowerCase() == serverId.toLowerCase()),
            );
          } catch (_) {
            targetTab = sessionManager.activeTab;
          }
        } else {
          targetTab = sessionManager.activeTab;
        }

        if (targetTab == null || targetTab.terminalSession == null) {
          return {
            'text':
                'Error: No active terminal session found. Please open an SSH connection in Shellit.',
            'isError': true,
          };
        }

        final host = targetTab.host;
        // Command Guard Protection Check
        final isGuarded = host != null &&
            (host.environment == HostEnvironment.production ||
                host.dangerousCommandProtection);

        if (isGuarded && DangerousCommandChecker.isDangerous(command)) {
          AppLogger.w(
            'MCP blocked destructive command: $command on ${host.label}',
            tag: 'McpServer',
          );
          return {
            'text':
                'Command Guard Alert: Command "$command" is classified as dangerous and was blocked on server "${host.label}". Please execute it directly in Shellit terminal if intended.',
            'isError': true,
          };
        }

        final client = targetTab.terminalSession?.underlyingClient;
        if (client == null) {
          return {
            'text':
                'Error: SSH client is not connected for "${targetTab.title}".',
            'isError': true,
          };
        }

        try {
          final cleanCmd = command.endsWith('\n')
              ? command.substring(0, command.length - 1)
              : command;
          final resultBytes = await client.run(cleanCmd);
          final output = utf8.decode(resultBytes as List<int>);
          return {
            'text': output.isEmpty
                ? '(Command executed successfully with empty output)'
                : output,
            'isError': false,
          };
        } catch (e) {
          return {'text': 'SSH command failed: $e', 'isError': true};
        }

      case 'shellit_get_terminal_buffer':
        final sessionManager = ref.read(sessionManagerProvider);
        final activeTab = sessionManager.activeTab;
        if (activeTab == null) {
          return {'text': 'No active tab open in Shellit.', 'isError': false};
        }
        return {
          'text':
              'Active tab "${activeTab.title}" (${activeTab.host?.connectionTarget ?? 'local'})',
          'isError': false,
        };

      default:
        return {
          'text': 'Tool not implemented in Shellit bridge: $toolName',
          'isError': true,
        };
    }
  });

  ref.onDispose(() {
    service.stop();
  });

  return service;
});
