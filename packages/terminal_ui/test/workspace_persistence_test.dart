import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

void main() {
  group('Workspace Persistence & Restoration Tests', () {
    test('exportWorkspaceState serializes open session tabs correctly', () {
      final notifier = SessionManagerNotifier();
      final now = DateTime.now();
      final host = HostEntity(
        id: 'h-100',
        label: 'Prod Server',
        hostname: '10.0.0.1',
        port: 22,
        username: 'root',
        authType: HostAuthType.password,
        environment: HostEnvironment.production,
        createdAt: now,
        updatedAt: now,
      );

      final tab1 = SessionTab(
        id: 'tab-1',
        title: 'Prod Server',
        customTitle: 'Bastion Host',
        colorTag: const Color(0xFFE53935),
        isPinned: true,
        type: TabType.terminal,
        host: host,
      );

      final tab2 = SessionTab(
        id: 'tab-2',
        title: 'SFTP View',
        type: TabType.sftp,
        host: host,
      );

      notifier.addRawTab(tab1);
      notifier.addRawTab(tab2);

      final exported = notifier.exportWorkspaceState();
      expect(exported.length, 2);
      expect(exported[0].id, 'tab-1');
      expect(exported[0].customTitle, 'Bastion Host');
      expect(exported[0].isPinned, isTrue);
      expect(exported[0].type, 'terminal');
      expect(exported[0].hostId, 'h-100');

      expect(exported[1].id, 'tab-2');
      expect(exported[1].type, 'sftp');
      expect(exported[1].isPinned, isFalse);
    });

    test('restoreWorkspaceTabs recreates tabs in lazy disconnected state', () {
      final notifier = SessionManagerNotifier();
      final now = DateTime.now();
      final host = HostEntity(
        id: 'h-200',
        label: 'Stage Server',
        hostname: '10.0.0.2',
        port: 22,
        username: 'ubuntu',
        authType: HostAuthType.privateKey,
        environment: HostEnvironment.staging,
        createdAt: now,
        updatedAt: now,
      );

      final savedStates = [
        const WorkspaceTabState(
          id: 'restored-1',
          title: 'Stage Server',
          customTitle: 'Staging App',
          colorTagValue: 0xFFFFC107,
          isPinned: true,
          type: 'terminal',
          hostId: 'h-200',
          splitLayout: 'single',
        ),
        const WorkspaceTabState(
          id: 'restored-2',
          title: 'Stage SFTP',
          type: 'sftp',
          hostId: 'h-200',
        ),
      ];

      notifier.restoreWorkspaceTabs(savedStates, [host], autoReconnect: false);

      expect(notifier.state.tabs.length, 2);
      final restoredTab1 = notifier.state.tabs[0];
      expect(restoredTab1.id, 'restored-1');
      expect(restoredTab1.customTitle, 'Staging App');
      expect(restoredTab1.isPinned, isTrue);
      expect(restoredTab1.isDisconnected, isTrue);
      expect(restoredTab1.isConnecting, isFalse);
      expect(restoredTab1.host?.id, 'h-200');

      final restoredTab2 = notifier.state.tabs[1];
      expect(restoredTab2.id, 'restored-2');
      expect(restoredTab2.type, TabType.sftp);
      expect(restoredTab2.isDisconnected, isTrue);
    });
  });
}
