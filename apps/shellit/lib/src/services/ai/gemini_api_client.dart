import 'dart:convert';
import 'package:core_foundation/core_foundation.dart';
import 'package:http/http.dart' as http;

/// Client for communicating directly with Google Gemini REST API (v1beta).
class GeminiApiClient {
  final http.Client _client;

  GeminiApiClient({http.Client? client}) : _client = client ?? http.Client();

  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';

  /// Fetches available generative models from Google Gemini API.
  Future<List<AiModelInfo>> fetchAvailableModels(String apiKey) async {
    final cleanKey = apiKey.trim();
    if (cleanKey.isEmpty) {
      throw const FormatException('API key is empty');
    }

    final uri = Uri.parse('$_baseUrl/models?key=$cleanKey');
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      String errorMessage = 'HTTP ${response.statusCode}';
      try {
        final errorJson = jsonDecode(response.body);
        if (errorJson is Map && errorJson.containsKey('error')) {
          errorMessage = errorJson['error']['message'] ?? errorMessage;
        }
      } catch (_) {}
      throw Exception(errorMessage);
    }

    final data = jsonDecode(response.body);
    if (data is! Map || !data.containsKey('models') || data['models'] is! List) {
      throw const FormatException('Invalid models list response format');
    }

    final rawModels = data['models'] as List;
    final List<AiModelInfo> models = [];

    for (final m in rawModels) {
      if (m is! Map) continue;
      final name = m['name'] as String? ?? '';
      final id = name.replaceFirst('models/', '');
      final supportedMethods = (m['supportedGenerationMethods'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      // Filter only models that support content generation
      if (!supportedMethods.contains('generateContent')) {
        continue;
      }

      final displayName = m['displayName'] as String? ?? id;
      final description = m['description'] as String? ?? '';
      final isRecommended = id == 'gemini-2.5-flash' ||
          id == 'gemini-2.5-pro' ||
          id.startsWith('gemini-2.5');

      models.add(
        AiModelInfo(
          id: id,
          displayName: displayName,
          description: description,
          isRecommended: isRecommended,
        ),
      );
    }

    // Sort: recommended first, then by id
    models.sort((a, b) {
      if (a.isRecommended && !b.isRecommended) return -1;
      if (!a.isRecommended && b.isRecommended) return 1;
      return a.id.compareTo(b.id);
    });

    return models;
  }

  /// Generates a structured shell command snippet from conversation history and user prompt.
  Future<AiSnippetResponse> generateSnippet({
    required String apiKey,
    required String modelId,
    required List<AiChatMessage> history,
    required String prompt,
    String? osType,
  }) async {
    final cleanKey = apiKey.trim();
    if (cleanKey.isEmpty) {
      throw const FormatException('API key is empty');
    }

    final uri = Uri.parse('$_baseUrl/models/$modelId:generateContent?key=$cleanKey');

    // Build multi-turn message payload
    final List<Map<String, dynamic>> contents = [];

    // Keep last 10 messages for context
    final recentHistory = history.length > 10
        ? history.sublist(history.length - 10)
        : history;

    for (final msg in recentHistory) {
      contents.add({
        'role': msg.isUser ? 'user' : 'model',
        'parts': [
          {
            'text': msg.isUser
                ? msg.text
                : (msg.snippet != null
                    ? jsonEncode(msg.snippet!.toJson())
                    : msg.text),
          }
        ],
      });
    }

    // Add current user prompt
    contents.add({
      'role': 'user',
      'parts': [
        {'text': prompt}
      ],
    });

    final targetOs = osType != null && osType.isNotEmpty ? osType : 'Linux/POSIX Bash';

    final requestBody = {
      'systemInstruction': {
        'parts': [
          {
            'text': 'You are an elite DevOps and Systems Engineer inside the Shellit SSH client terminal assistant. '
                'Target platform: $targetOs. '
                'Your task is to write robust, secure, and production-ready shell commands and snippets. '
                'You MUST ALWAYS reply with valid JSON conforming to the requested schema. '
                'Mark isDangerous: true whenever the command deletes data (rm, truncate, wipe), reboots, terminates processes abruptly, modifies disk partitions, or drops databases.',
          }
        ]
      },
      'contents': contents,
      'generationConfig': {
        'responseMimeType': 'application/json',
        'responseSchema': {
          'type': 'OBJECT',
          'properties': {
            'title': {'type': 'STRING'},
            'command': {'type': 'STRING'},
            'description': {'type': 'STRING'},
            'tags': {
              'type': 'ARRAY',
              'items': {'type': 'STRING'}
            },
            'explanation': {'type': 'STRING'},
            'isDangerous': {'type': 'BOOLEAN'},
            'dangerWarning': {'type': 'STRING'}
          },
          'required': ['title', 'command', 'description', 'tags', 'isDangerous']
        }
      }
    };

    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode != 200) {
      String errorMsg = 'HTTP ${response.statusCode}';
      try {
        final errObj = jsonDecode(response.body);
        if (errObj is Map && errObj.containsKey('error')) {
          errorMsg = errObj['error']['message'] ?? errorMsg;
        }
      } catch (_) {}
      throw Exception(errorMsg);
    }

    final responseJson = jsonDecode(response.body);
    try {
      final candidates = responseJson['candidates'] as List;
      final firstCandidate = candidates.first as Map;
      final content = firstCandidate['content'] as Map;
      final parts = content['parts'] as List;
      final rawText = parts.first['text'] as String;

      final snippetJson = jsonDecode(rawText) as Map<String, dynamic>;
      return AiSnippetResponse.fromJson(snippetJson);
    } catch (e, st) {
      throw FormatException('Failed to parse Gemini response: $e', st);
    }
  }

  void close() {
    _client.close();
  }
}
