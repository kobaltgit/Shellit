import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shellit/src/services/ai/gemini_api_client.dart';

void main() {
  group('GeminiApiClient', () {
    test('fetchAvailableModels parses and filters models correctly', () async {
      final mockResponse = {
        'models': [
          {
            'name': 'models/gemini-2.5-flash',
            'displayName': 'Gemini 2.5 Flash',
            'description': 'Fast and lightweight model',
            'supportedGenerationMethods': ['generateContent', 'countTokens'],
          },
          {
            'name': 'models/gemini-2.5-pro',
            'displayName': 'Gemini 2.5 Pro',
            'description': 'Advanced reasoning model',
            'supportedGenerationMethods': ['generateContent'],
          },
          {
            'name': 'models/text-embedding-004',
            'displayName': 'Text Embedding',
            'supportedGenerationMethods': ['embedContent'],
          },
        ],
      };

      final client = MockClient((request) async {
        expect(request.url.path, contains('/v1beta/models'));
        expect(request.url.queryParameters['key'], equals('fake-test-key'));
        return http.Response(jsonEncode(mockResponse), 200);
      });

      final apiClient = GeminiApiClient(client: client);
      final models = await apiClient.fetchAvailableModels('fake-test-key');

      expect(models.length, equals(2));
      expect(models[0].id, equals('gemini-2.5-flash'));
      expect(models[0].isRecommended, isTrue);
      expect(models[1].id, equals('gemini-2.5-pro'));
      expect(models[1].isRecommended, isTrue);
    });

    test(
      'generateSnippet sends structured schema and parses response',
      () async {
        final mockSnippetResponse = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    'text': jsonEncode({
                      'title': 'Top Memory Processes',
                      'command': 'ps aux --sort=-%mem | head -n 11',
                      'description':
                          'Displays the top 10 memory-consuming processes.',
                      'tags': ['memory', 'monitoring', 'processes'],
                      'explanation':
                          'Uses ps aux and sorts by mem usage descending.',
                      'isDangerous': false,
                    }),
                  },
                ],
              },
            },
          ],
        };

        final client = MockClient((request) async {
          expect(
            request.url.path,
            contains('gemini-2.5-flash:generateContent'),
          );
          final body = jsonDecode(request.body);
          expect(
            body['generationConfig']['responseMimeType'],
            equals('application/json'),
          );
          return http.Response(jsonEncode(mockSnippetResponse), 200);
        });

        final apiClient = GeminiApiClient(client: client);
        final snippet = await apiClient.generateSnippet(
          apiKey: 'fake-key',
          modelId: 'gemini-2.5-flash',
          history: [],
          prompt: 'show top 10 processes by ram',
        );

        expect(snippet.title, equals('Top Memory Processes'));
        expect(snippet.command, equals('ps aux --sort=-%mem | head -n 11'));
        expect(snippet.tags, contains('memory'));
        expect(snippet.isDangerous, isFalse);
      },
    );
  });
}
