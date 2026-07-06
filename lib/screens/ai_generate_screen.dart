import 'package:flutter/material.dart';
import '../services/ai_service.dart';

class AIGenerateScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onContentGenerated;
  const AIGenerateScreen({super.key, required this.onContentGenerated});

  @override
  State<AIGenerateScreen> createState() => _AIGenerateScreenState();
}

class _AIGenerateScreenState extends State<AIGenerateScreen> {
  final _jobTitleController = TextEditingController();
  final _experienceController = TextEditingController();
  final _skillsController = TextEditingController();
  final _currentRoleController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';
  String _statusMessage = '';

  final AIService _aiService = AIService();

  @override
  void dispose() {
    _jobTitleController.dispose();
    _experienceController.dispose();
    _skillsController.dispose();
    _currentRoleController.dispose();
    super.dispose();
  }

  Future<void> _generateContent() async {
    final jobTitle = _jobTitleController.text.trim();
    if (jobTitle.isEmpty) {
      setState(() => _errorMessage = 'Please enter a target job title.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _statusMessage = 'Connecting to AI…';
    });

    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) setState(() => _statusMessage = 'Writing your summary…');

    final result = await _aiService.generateResumeContent(
      jobTitle: jobTitle,
      experienceYears: _experienceController.text.trim().isEmpty
          ? 'Not specified'
          : _experienceController.text.trim(),
      skillsInput: _skillsController.text.trim().isEmpty
          ? 'Not specified'
          : _skillsController.text.trim(),
      currentRole: _currentRoleController.text.trim().isEmpty
          ? 'Not specified'
          : _currentRoleController.text.trim(),
    );

    if (!mounted) return;

    result.when(
      success: (content) {
        widget.onContentGenerated(content);
        Navigator.pop(context);
      },
      failure: (msg) {
        setState(() {
          _errorMessage = msg;
          _isLoading = false;
          _statusMessage = '';
        });
      },
    );
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
                'Let AI write your resume content.',
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
              if (_errorMessage.isNotEmpty) ...[
                Text(
                  _errorMessage,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _generateContent,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
              const SizedBox(height: 8),
              if (_isLoading) ...[
                Text(
                  _statusMessage,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                const LinearProgressIndicator(),
              ] else
                ElevatedButton(
                  onPressed: _generateContent,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Generate with AI',
                      style: TextStyle(fontSize: 18)),
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
