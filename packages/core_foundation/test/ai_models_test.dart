import 'package:core_foundation/core_foundation.dart';
import 'package:test/test.dart';

void main() {
  group('AiSnippetResponse', () {
    test('parses from valid JSON map correctly', () {
      final json = {
        'title': 'List Big Files',
        'command': 'find . -size +100M',
        'description': 'Finds files larger than 100MB',
        'tags': ['disk', 'find'],
        'explanation': 'Uses find utility with -size parameter',
        'isDangerous': false,
        'dangerWarning': null,
      };

      final response = AiSnippetResponse.fromJson(json);

      expect(response.title, equals('List Big Files'));
      expect(response.command, equals('find . -size +100M'));
      expect(response.description, equals('Finds files larger than 100MB'));
      expect(response.tags, equals(['disk', 'find']));
      expect(response.explanation,
          equals('Uses find utility with -size parameter'));
      expect(response.isDangerous, isFalse);
      expect(response.dangerWarning, isNull);
    });

    test('handles missing or malformed tags gracefully', () {
      final json = {
        'title': 'Remove All',
        'command': 'rm -rf /tmp/data',
        'description': 'Deletes temporary data directory',
        'isDangerous': true,
        'dangerWarning': 'Permanently removes files recursively',
      };

      final response = AiSnippetResponse.fromJson(json);

      expect(response.title, equals('Remove All'));
      expect(response.tags, isEmpty);
      expect(response.isDangerous, isTrue);
      expect(response.dangerWarning,
          equals('Permanently removes files recursively'));
    });
  });

  group('VaultSettingsEntity AI fields', () {
    test('default values for AI settings are correct', () {
      const settings = VaultSettingsEntity();
      expect(settings.geminiApiKey, isNull);
      expect(settings.geminiModelId, equals('gemini-2.5-flash'));
      expect(settings.isAiSnippetEnabled, isFalse);
    });

    test('copyWith updates AI fields correctly', () {
      const settings = VaultSettingsEntity();
      final updated = settings.copyWith(
        geminiApiKey: 'AIzaSyFakeKey123',
        geminiModelId: 'gemini-2.5-pro',
        isAiSnippetEnabled: true,
      );

      expect(updated.geminiApiKey, equals('AIzaSyFakeKey123'));
      expect(updated.geminiModelId, equals('gemini-2.5-pro'));
      expect(updated.isAiSnippetEnabled, isTrue);
      expect(updated, isNot(equals(settings)));
    });
  });
}
