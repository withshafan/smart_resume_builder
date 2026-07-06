import 'package:flutter/material.dart';
import '../services/ai_service.dart';

class AIGenerateScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onContentGenerated;

  const AIGenerateScreen({super.key, required this.onContentGenerated});

  @override
  State<AIGenerateScreen> createState() => _AIGenerateScreenState();
}

class _AIGenerateScreenState extends State<AIGenerateScreen> {
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();
  final TextEditingController _currentRoleController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';

  final AIService _aiService = AIService();

  Future<void> _generateContent() async {
    final jobTitle = _jobTitleController.text.trim();
    final experience = _experienceController.text.trim();
    final skills = _skillsController.text.trim();
    final currentRole = _currentRoleController.text.trim();

    if (jobTitle.isEmpty) {
      setState(() => _errorMessage = 'Please enter the job title.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await _aiService.generateResumeContent(
        jobTitle: jobTitle,
        experienceYears: experience.isEmpty ? 'Not specified' : experience,
        skillsInput: skills.isEmpty ? 'Not specified' : skills,
        currentRole: currentRole.isEmpty ? 'Not specified' : currentRole,
      );

      // Pass the generated content back
      widget.onContentGenerated(result);
      if (mounted) {
        Navigator.pop(context); // Go back to the form with generated data
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Generate Content')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: IgnorePointer(
          ignoring: _isLoading,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Let AI help you write your resume.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _jobTitleController,
                decoration: const InputDecoration(
                  labelText: 'Target Job Title *',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Flutter Developer',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _experienceController,
                decoration: const InputDecoration(
                  labelText: 'Years of Experience',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., 3 years',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _currentRoleController,
                decoration: const InputDecoration(
                  labelText: 'Current Role',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Junior Developer',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _skillsController,
                decoration: const InputDecoration(
                  labelText: 'Your Skills (comma separated)',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Flutter, Firebase, Dart',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              if (_errorMessage.isNotEmpty)
                Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 16),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _generateContent,
                      child: const Text('Generate with AI', style: TextStyle(fontSize: 18)),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
