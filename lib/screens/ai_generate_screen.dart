import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../services/ai_service.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

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

  // Store editable AI output so user can review before applying
  Map<String, dynamic>? _generatedContent;
  final _generatedSummaryController = TextEditingController();
  final _generatedSkillsController = TextEditingController();

  final AIService _aiService = AIService();

  @override
  void dispose() {
    _jobTitleController.dispose();
    _experienceController.dispose();
    _skillsController.dispose();
    _currentRoleController.dispose();
    _generatedSummaryController.dispose();
    _generatedSkillsController.dispose();
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
      _generatedContent = null;
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
        setState(() {
          _generatedContent = content;
          _generatedSummaryController.text = content['summary'] ?? '';
          
          if (content['skills'] is List) {
            _generatedSkillsController.text = (content['skills'] as List).join(', ');
          } else {
            _generatedSkillsController.text = content['skills']?.toString() ?? '';
          }
          
          _isLoading = false;
        });
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

  void _applyContent() {
    if (_generatedContent == null) return;
    
    // Pass back the user-edited versions
    final finalContent = {
      'summary': _generatedSummaryController.text.trim(),
      'skills': _generatedSkillsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
    };
    
    widget.onContentGenerated(finalContent);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Content Generator')),
      body: _generatedContent != null ? _buildReviewStep() : _buildInputStep(),
    );
  }

  Widget _buildInputStep() {
    return IgnorePointer(
      ignoring: _isLoading,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.navyLight.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome, color: AppColors.navyLight),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Let AI write your professional summary and suggest skills based on your target role.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          TextField(
            controller: _jobTitleController,
            decoration: const InputDecoration(
              labelText: 'Target Job Title *',
              hintText: 'e.g., Senior Flutter Developer',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _experienceController,
            decoration: const InputDecoration(
              labelText: 'Years of Experience',
              hintText: 'e.g., 3 years',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _currentRoleController,
            decoration: const InputDecoration(
              labelText: 'Current Role',
              hintText: 'e.g., Mobile App Developer',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _skillsController,
            decoration: const InputDecoration(
              labelText: 'Current Skills',
              hintText: 'e.g., Flutter, Firebase, Dart (optional)',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: AppSpacing.xl),
          
          if (_errorMessage.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                      color: Theme.of(context).colorScheme.error, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(_errorMessage,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          
          if (_isLoading) _buildShimmerLoading()
          else ElevatedButton.icon(
            onPressed: _generateContent,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Generate Profile', style: TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: const Color(0xFF2E8B57).withAlpha(30),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFF2E8B57)),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Content generated! Review and edit before applying.',
                  style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        
        Text('Professional Summary', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _generatedSummaryController,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: 'Generated summary...',
            alignLabelWithHint: true,
          ),
        ),
        
        const SizedBox(height: AppSpacing.lg),
        Text('Suggested Skills', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _generatedSkillsController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Generated skills...',
            alignLabelWithHint: true,
          ),
        ),
        
        const SizedBox(height: AppSpacing.xxl),
        ElevatedButton(
          onPressed: _applyContent,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
          ),
          child: const Text('Apply to Resume', style: TextStyle(fontSize: 16)),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: _generateContent,
          icon: const Icon(Icons.refresh),
          label: const Text('Regenerate'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerLoading() {
    return Column(
      children: [
        Shimmer.fromColors(
          baseColor: Theme.of(context).colorScheme.surface,
          highlightColor: Theme.of(context).colorScheme.primary.withAlpha(20),
          child: Container(
            height: 52,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _statusMessage,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
