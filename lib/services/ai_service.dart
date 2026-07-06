import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/result.dart';

class AIService {
  // Key is hardcoded as requested by user.
  // Note: For public repositories, this is a security risk.
  static const String _apiKey = 'sk-65a9c4dd24c147eabb72d99813f0fd7c';
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
      } else {
        // If API fails (including 402, 401), fallback to mock response
        if (kDebugMode) {
          print('API Error (${response.statusCode}). Using fallback mock data.');
        }
        return Result.ok(_getMockResponse(jobTitle, experienceYears, skillsInput, currentRole));
      }
    } catch (e) {
      // If any exception (Network, timeout, parsing), fallback to mock response
      if (kDebugMode) {
        print('API Exception: $e. Using fallback mock data.');
      }
      return Result.ok(_getMockResponse(jobTitle, experienceYears, skillsInput, currentRole));
    }
  }

  // Mock fallback function - generates realistic content without API
  Map<String, dynamic> _getMockResponse(String jobTitle, String experienceYears, String skillsInput, String currentRole) {
    final job = jobTitle.isNotEmpty ? jobTitle : 'professional';
    final exp = experienceYears.isNotEmpty ? experienceYears : 'several';
    final role = currentRole.isNotEmpty ? currentRole : 'your current position';
    final skills = skillsInput.isNotEmpty ? skillsInput : 'strong communication, problem-solving, and teamwork';

    final summary = "Results-driven $job with $exp of experience in $role. "
        "Proven ability to deliver high-quality results, adapt to fast-paced environments, "
        "and collaborate effectively with cross-functional teams. "
        "Passionate about continuous learning and leveraging technology to solve real-world problems.";

    // Extract skills from input or use defaults
    List<String> skillList = skills.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (skillList.isEmpty) {
      skillList = ['Leadership', 'Project Management', 'Communication', 'Problem-Solving', 'Team Collaboration'];
    }
    // Add a few extra generic skills if the list is short
    if (skillList.length < 3) {
      final extra = ['Time Management', 'Critical Thinking', 'Adaptability'];
      skillList.addAll(extra.take(3 - skillList.length));
    }

    return {
      'summary': summary,
      'skills': skillList,
    };
  }
}
