import 'package:core_foundation/core_foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../di/app_providers.dart';
import '../services/ai/gemini_api_client.dart';

/// Gemini API Client Provider
final geminiApiClientProvider = Provider<GeminiApiClient>((ref) {
  final client = GeminiApiClient();
  ref.onDispose(client.close);
  return client;
});

/// Future provider to fetch available models for a given API key.
final geminiModelsProvider =
    FutureProvider.family<List<AiModelInfo>, String>((ref, apiKey) async {
  if (apiKey.trim().isEmpty) return const [];
  final client = ref.watch(geminiApiClientProvider);
  return client.fetchAvailableModels(apiKey.trim());
});

/// State for the AI Snippet Chat
class AiChatState {
  final List<AiChatMessage> messages;
  final bool isGenerating;
  final String? error;

  const AiChatState({
    this.messages = const [],
    this.isGenerating = false,
    this.error,
  });

  AiChatState copyWith({
    List<AiChatMessage>? messages,
    bool? isGenerating,
    String? error,
    bool clearError = false,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isGenerating: isGenerating ?? this.isGenerating,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Controller managing the AI snippet chat thread and communication with Gemini.
class AiChatController extends StateNotifier<AiChatState> {
  final Ref _ref;

  AiChatController(this._ref) : super(const AiChatState());

  /// Sends a user prompt and requests a structured snippet from Gemini.
  Future<void> sendPrompt(String prompt, {String? osType}) async {
    final cleanPrompt = prompt.trim();
    if (cleanPrompt.isEmpty || state.isGenerating) return;

    final repo = _ref.read(appVaultRepositoryProvider);
    final settings = await repo.getSettings();
    final apiKey = settings.geminiApiKey?.trim();
    final modelId = settings.geminiModelId.isNotEmpty
        ? settings.geminiModelId
        : 'gemini-2.5-flash';

    if (apiKey == null || apiKey.isEmpty) {
      state = state.copyWith(
        error: 'Gemini API key is not configured. Please set it in Settings.',
      );
      return;
    }

    final userMessage = AiChatMessage(
      id: 'msg-${DateTime.now().microsecondsSinceEpoch}',
      isUser: true,
      text: cleanPrompt,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isGenerating: true,
      clearError: true,
    );

    try {
      final client = _ref.read(geminiApiClientProvider);
      final snippetResponse = await client.generateSnippet(
        apiKey: apiKey,
        modelId: modelId,
        history: state.messages,
        prompt: cleanPrompt,
        osType: osType,
      );

      final assistantMessage = AiChatMessage(
        id: 'msg-${DateTime.now().microsecondsSinceEpoch}',
        isUser: false,
        text: snippetResponse.explanation.isNotEmpty
            ? snippetResponse.explanation
            : snippetResponse.description,
        snippet: snippetResponse,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
        isGenerating: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isGenerating: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Clears the chat thread history.
  void clearChat() {
    state = const AiChatState();
  }
}

/// Riverpod provider for the AI Chat Controller
final aiChatControllerProvider =
    StateNotifierProvider<AiChatController, AiChatState>((ref) {
  return AiChatController(ref);
});
