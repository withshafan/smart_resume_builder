import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AIService {
  // Key is injected at build time via --dart-define=DEEPSEEK_API_KEY=<your_key>
  // Example: flutter run --dart-define=DEEPSEEK_API_KEY=sk-...
  // IMPORTANT: The previous hardcoded key (commit d4eac14) must be rotated on
  // the DeepSeek platform at https://platform.deepseek.com — rotating invalidates
  // the exposed key and makes the old commit harmless.
  static const String _apiKey = String.fromEnvironment('DEEPSEEK_API_KEY', defaultValue: '');
  static const String _apiUrl = 'https://api.deepseek.com/v1/chat/completions';

  /// Generate professional summary and skill suggestions based on user input.
  Future<Map<String, dynamic>> generateResumeContent({
    required String jobTitle,
    required String experienceYears,
    required String skillsInput,
    required String currentRole,
  }) async {
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
      if (_apiKey.isEmpty) {
        throw Exception(
          kDebugMode
              ? 'DEEPSEEK_API_KEY is not set.\n'
                'Run with: flutter run --dart-define=DEEPSEEK_API_KEY=<your_key>'
              : 'AI service is not configured. Contact support.',
        );
      }
      final response = await http.post(
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
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        // Extract JSON from content (it might be wrapped in markdown)
        final jsonStart = content.indexOf('{');
        final jsonEnd = content.lastIndexOf('}') + 1;
        final jsonString = content.substring(jsonStart, jsonEnd);
        return jsonDecode(jsonString);
      } else {
        throw Exception('API request failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to generate resume content: $e');
    }
  }
}
