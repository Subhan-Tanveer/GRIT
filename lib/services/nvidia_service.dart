import 'dart:convert';
import 'package:http/http.dart' as http;

/// Thin wrapper around NVIDIA's OpenAI-compatible chat completions endpoint
/// (NIM / integrate.api.nvidia.com). Only called when the user has supplied
/// their own API key.
class NvidiaService {
  static const String _endpoint = 'https://integrate.api.nvidia.com/v1/chat/completions';
  static const String defaultModel = 'moonshotai/kimi-k2.6';

  /// [history] is a list of {role: 'user'|'assistant', content: '...'} maps,
  /// oldest first, NOT including the system prompt.
  static Future<String> sendChat({
    required String apiKey,
    required String systemPrompt,
    required List<Map<String, String>> history,
    String model = defaultModel,
  }) async {
    final messages = [
      {'role': 'system', 'content': systemPrompt},
      ...history,
    ];

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'content-type': 'application/json',
        'Authorization': 'Bearer $apiKey',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'model': model,
        'messages': messages,
        'max_tokens': 600,
        'temperature': 0.7,
        'top_p': 1.0,
        'stream': false,
      }),
    ).timeout(const Duration(seconds: 25));

    if (response.statusCode != 200) {
      throw Exception('NVIDIA API error ${response.statusCode}: ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = decoded['choices'] as List<dynamic>;
    if (choices.isEmpty) return '';
    final message = (choices.first as Map<String, dynamic>)['message'] as Map<String, dynamic>;
    return message['content'] as String? ?? '';
  }
}
