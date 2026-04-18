import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

/// Groq-powered contractor recommendation service (FREE tier).
///
/// Uses Llama 3.3 70B with function calling to extract structured queries
/// from natural language, then generates human-friendly responses.
///
/// Free key from: https://console.groq.com
/// Free tier: 30 RPM, 14,400 RPD, 131K tokens/min
class OpenAIService {
  static const _model = 'llama-3.3-70b-versatile';
  static const _endpoint = 'https://api.groq.com/openai/v1/chat/completions';

  /// Cached API key.
  static String? _cachedKey;

  /// Load API key from assets/.env
  static Future<String> _getApiKey() async {
    if (_cachedKey != null) return _cachedKey!;
    // 1. Try --dart-define
    const envKey = String.fromEnvironment('GROQ_API_KEY', defaultValue: '');
    if (envKey.isNotEmpty) {
      _cachedKey = envKey;
      return _cachedKey!;
    }
    // 2. Load from assets/.env
    try {
      final content = await rootBundle.loadString('assets/.env');
      for (final line in content.split('\n')) {
        if (line.startsWith('GROQ_API_KEY=')) {
          _cachedKey = line.substring('GROQ_API_KEY='.length).trim();
          return _cachedKey!;
        }
      }
    } catch (e) {
      debugPrint('Failed to load .env from assets: $e');
    }
    return '';
  }

  /// Conversation history (OpenAI chat format).
  final List<Map<String, dynamic>> _history = [];

  static const _systemPrompt = '''
You are AmanBuild AI — a smart contractor recommendation assistant for a home‑services app in Bahrain.

RULES:
1. You ONLY help users find contractors. Do not discuss unrelated topics.
2. When a user describes a problem or asks for a contractor, call the "search_contractors" function with the right parameters.
3. When you receive contractor data back, write a SHORT, helpful response:
   - Start with a one-line acknowledgement of the user's need.
   - List the contractors with: name, category, rating, distance, and a one-line reason why you recommend them.
   - If review summaries are provided, include a brief "Review highlights" line.
   - Keep it concise — no long paragraphs.
4. Remember prior conversation context. If the user says "which one is cheaper?" after asking about AC repair, refer to the same category.
5. NEVER expose emails, phone numbers, or private user data.
6. If the user greets you, respond warmly and ask what they need help with.
7. If the user thanks you, respond politely.
8. Respond in the same language the user uses (English or Arabic).

SERVICE CATEGORIES (use exact strings for the function):
- HVAC (Air Conditioning)
- Electrical Services
- Plumbing
- General Construction & Renovation
- Interior Finishing
- Tree Services
- Movers
- Locksmiths
''';

  static const _tools = [
    {
      'type': 'function',
      'function': {
        'name': 'search_contractors',
        'description':
            'Search the database for contractors matching the user request. '
                'Call this whenever the user needs contractor recommendations.',
        'parameters': {
          'type': 'object',
          'properties': {
            'category': {
              'type': 'string',
              'enum': [
                'HVAC (Air Conditioning)',
                'Electrical Services',
                'Plumbing',
                'General Construction & Renovation',
                'Interior Finishing',
                'Tree Services',
                'Movers',
                'Locksmiths',
              ],
              'description':
                  'The service category. Omit to search all categories.',
            },
            'sort_by': {
              'type': 'string',
              'enum': ['best_match', 'nearest', 'highest_rated'],
              'description':
                  'How to rank results. "nearest" boosts proximity, '
                      '"highest_rated" boosts rating, "best_match" balances both.',
            },
            'limit': {
              'type': 'integer',
              'description': 'Number of results to return (1-3).',
            },
          },
          'required': ['sort_by'],
        },
      },
    },
  ];

  /// Reset conversation history.
  void resetHistory() => _history.clear();

  /// POST to Groq with retry on 429.
  Future<http.Response> _post(Map<String, dynamic> body) async {
    final key = await _getApiKey();
    if (key.isEmpty) {
      return http.Response('{"error":"No API key configured"}', 401);
    }
    const maxRetries = 3;
    for (var attempt = 0; attempt < maxRetries; attempt++) {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $key',
        },
        body: jsonEncode(body),
      );
      debugPrint('Groq response: ${response.statusCode}');
      if (response.statusCode == 429 && attempt < maxRetries - 1) {
        final waitSecs = (attempt + 1) * 3;
        debugPrint('Groq 429 — retrying in ${waitSecs}s...');
        await Future.delayed(Duration(seconds: waitSecs));
        continue;
      }
      return response;
    }
    return http.Response('Rate limit exceeded', 429);
  }

  /// Build the request body.
  Map<String, dynamic> _buildBody({bool withTools = true}) {
    final messages = [
      {'role': 'system', 'content': _systemPrompt},
      ..._history,
    ];
    final body = <String, dynamic>{
      'model': _model,
      'messages': messages,
      'temperature': 0.3,
      'max_tokens': 600,
    };
    if (withTools) {
      body['tools'] = _tools;
      body['tool_choice'] = 'auto';
    }
    return body;
  }

  /// Send a user message. Returns text or function call.
  Future<AIResponse> sendMessage(String userMessage) async {
    _history.add({'role': 'user', 'content': userMessage});

    http.Response response;
    try {
      response = await _post(_buildBody());
    } catch (e) {
      debugPrint('Groq network error: $e');
      if (_history.isNotEmpty) _history.removeLast();
      return AIResponse.text(
        'Network error — please check your internet connection and try again.',
      );
    }

    if (response.statusCode != 200) {
      debugPrint('Groq API error ${response.statusCode}: ${response.body}');
      if (_history.isNotEmpty) _history.removeLast();
      return AIResponse.text(
        'I\'m having trouble connecting right now (${response.statusCode}). Please try again in a moment.',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final choice = (json['choices'] as List).first as Map<String, dynamic>;
    final message = choice['message'] as Map<String, dynamic>;

    // Check for tool calls
    if (message.containsKey('tool_calls') && message['tool_calls'] != null) {
      final toolCalls = message['tool_calls'] as List;
      if (toolCalls.isNotEmpty) {
        final tc = toolCalls.first as Map<String, dynamic>;
        final fn = tc['function'] as Map<String, dynamic>;
        final fnName = fn['name'] as String;
        final args = jsonDecode(fn['arguments'] as String) as Map<String, dynamic>;
        final toolCallId = tc['id'] as String;

        // Store assistant message with tool call in history
        _history.add(message);

        if (fnName == 'search_contractors') {
          return AIResponse.functionCall(
            toolCallId: toolCallId,
            category: args['category'] as String?,
            sortBy: args['sort_by'] as String? ?? 'best_match',
            limit: (args['limit'] as num?)?.toInt() ?? 3,
          );
        }
      }
    }

    // Direct text response
    final text = message['content'] as String? ?? '';
    _history.add({'role': 'assistant', 'content': text});
    return AIResponse.text(text);
  }

  /// Send tool results back to get the AI's natural-language response.
  Future<String> sendToolResult({
    required String toolCallId,
    required String contractorDataJson,
  }) async {
    _history.add({
      'role': 'tool',
      'tool_call_id': toolCallId,
      'content': contractorDataJson,
    });

    http.Response response;
    try {
      response = await _post(_buildBody(withTools: false));
    } catch (e) {
      debugPrint('Groq tool-result network error: $e');
      return 'Here are the best contractors I found for you:';
    }

    if (response.statusCode != 200) {
      debugPrint('Groq tool-result error ${response.statusCode}: ${response.body}');
      return 'Here are the best contractors I found for you:';
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final choice = (json['choices'] as List).first as Map<String, dynamic>;
    final message = choice['message'] as Map<String, dynamic>;
    final text = message['content'] as String? ?? '';

    _history.add({'role': 'assistant', 'content': text});
    return text.isNotEmpty ? text : 'Here are the best contractors I found:';
  }
}

// ─────────────────────────────────────────────────────────
//  Response types
// ─────────────────────────────────────────────────────────

enum AIResponseType { text, functionCall }

class AIResponse {
  final AIResponseType type;

  /// For text responses.
  final String? text;

  /// For function-call responses.
  final String? toolCallId;
  final String? category;
  final String? sortBy;
  final int? limit;

  AIResponse._({
    required this.type,
    this.text,
    this.toolCallId,
    this.category,
    this.sortBy,
    this.limit,
  });

  factory AIResponse.text(String text) =>
      AIResponse._(type: AIResponseType.text, text: text);

  factory AIResponse.functionCall({
    required String toolCallId,
    String? category,
    required String sortBy,
    required int limit,
  }) =>
      AIResponse._(
        type: AIResponseType.functionCall,
        toolCallId: toolCallId,
        category: category,
        sortBy: sortBy,
        limit: limit,
      );
}
