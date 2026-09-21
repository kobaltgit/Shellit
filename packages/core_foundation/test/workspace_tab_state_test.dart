import 'package:core_foundation/core_foundation.dart';
import 'package:test/test.dart';

void main() {
  group('WorkspaceTabState serialization tests', () {
    test('roundtrip serialization of single WorkspaceTabState', () {
      const state = WorkspaceTabState(
        id: 'tab-1',
        title: 'prod-server',
        customTitle: 'Production Bastion',
        colorTagValue: 0xFFE53935,
        isPinned: true,
        type: 'terminal',
        hostId: 'host-123',
        splitLayout: 'single',
      );

      final json = state.toJson();
      final restored = WorkspaceTabState.fromJson(json);

      expect(restored.id, 'tab-1');
      expect(restored.title, 'prod-server');
      expect(restored.customTitle, 'Production Bastion');
      expect(restored.colorTagValue, 0xFFE53935);
      expect(restored.isPinned, isTrue);
      expect(restored.type, 'terminal');
      expect(restored.hostId, 'host-123');
      expect(restored.splitLayout, 'single');
      expect(restored, equals(state));
    });

    test('encodeList and decodeList roundtrip', () {
      final list = [
        const WorkspaceTabState(
          id: 'tab-1',
          title: 'web-1',
          isPinned: true,
          type: 'terminal',
          hostId: 'h1',
        ),
        const WorkspaceTabState(
          id: 'tab-2',
          title: 'sftp-web',
          type: 'sftp',
          hostId: 'h1',
        ),
      ];

      final encoded = WorkspaceTabState.encodeList(list);
      final decoded = WorkspaceTabState.decodeList(encoded);

      expect(decoded.length, 2);
      expect(decoded[0].id, 'tab-1');
      expect(decoded[0].isPinned, isTrue);
      expect(decoded[1].id, 'tab-2');
      expect(decoded[1].type, 'sftp');
    });
  });
}
