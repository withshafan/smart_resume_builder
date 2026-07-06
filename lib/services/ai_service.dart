import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/result.dart';

class AIService {
  // Key is injected at build time via --dart-define=DEEPSEEK_API_KEY=<your_key>
  // Example: flutter run --dart-define=DEEPSEEK_API_KEY=sk-...
  // IMPORTANT: The previous hardcoded key (commit d4eac14) must be rotated on
  // the DeepSeek platform at https://platform.deepseek.com — rotating invalidates
  // the exposed key and makes the old commit harmless.
  static const String _apiKey = String.fromEnvironment('DEEPSEEK_API_KEY', defaultValue: '');
  static const String _apiUrl = 'https://api.deepseek.com/v1/chat/completions';
  static const Duration _timeout = Duration(seconds: 30);

  /// Generate professional summary and skill suggestions based on user input.
  Future<Result<Map<String, dynamic>>> generateResumeContent({
    required String jobTitle,
    required String experienceYears,
    required String skillsInput,
    required String currentRole,
  }) async {
    if (_apiKey.isEmpty) {
      final msg = kDebugMode
          ? 'DEEPSEEK_API_KEY is not set. Run with: flutter run --dart-define=DEEPSEEK_API_KEY=<your_key>'
          : 'AI service is not configured. Contact support.';
      return Result.fail(msg);
    }

    final prompt = '''
You are an expert resume writer. Based on the following information, generate:
1. A professional summary (3-4 sentences) that highlights the candidate's strengths and aligns with the job title.
2. A list of relevant skills (comma-separated) that should be included in the resume.

User details:
- Job Title: $jobTitle
- Years of Experience: $experienceYears
- Current Role: $currentRole
- Skills they mentioned: $skillsInput

Provide the response in JSON format with keys "summary" and "skills" (where skills is a list of strings).
Example:
{
  "summary": "Experienced software engineer with 5 years in mobile development...",
  "skills": ["Flutter", "Dart", "Firebase", "REST APIs", "Git"]
}
''';

    try {
      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode({
              'model': 'deepseek-chat',
              'messages': [
                {
                  'role': 'system',
                  'content': 'You are a helpful assistant that generates resume content in JSON format only.',
                },
                {'role': 'user', 'content': prompt},
              ],
              'temperature': 0.7,
              'max_tokens': 500,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        // Extract JSON from content (it might be wrapped in markdown code fences)
        final jsonStart = content.indexOf('{');
        final jsonEnd = content.lastIndexOf('}') + 1;
        if (jsonStart == -1 || jsonEnd <= jsonStart) {
          return Result.parseError();
        }
        final parsed = jsonDecode(content.substring(jsonStart, jsonEnd));
        return Result.ok(parsed as Map<String, dynamic>);
      } else if (response.statusCode == 429) {
        return Result.rateLimitError();
      } else if (response.statusCode == 401) {
        return Result.fail(
          kDebugMode
              ? 'DeepSeek API key is invalid or expired (401). Check your --dart-define value.'
              : 'AI service authentication failed. Contact support.',
        );
      } else {
        return Result.fail(
          'AI request failed (${response.statusCode}). Please try again.',
        );
      }
    } on SocketException {
      return Result.networkError();
    } on http.ClientException {
      return Result.networkError();
    } catch (e) {
      return Result.fail('Unexpected error. Please try again.', cause: e);
    }
  }
}
