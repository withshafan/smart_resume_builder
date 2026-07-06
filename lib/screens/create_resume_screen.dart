import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/resume.dart';
import '../services/resume_service.dart';
import '../theme/app_spacing.dart';
import 'ai_generate_screen.dart';

class CreateResumeScreen extends StatefulWidget {
  final Resume? existingResume;
  const CreateResumeScreen({super.key, this.existingResume});

  @override
  State<CreateResumeScreen> createState() => _CreateResumeScreenState();
}

class _CreateResumeScreenState extends State<CreateResumeScreen> {
  final _formKey = GlobalKey<FormState>();
  final ResumeService _resumeService = ResumeService();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _summaryController = TextEditingController();
  final _skillsController = TextEditingController();

  String _selectedCategory = 'Other';
  bool _isLoading = false;
  bool _isEditing = false;

  static const _categories = ['Tech', 'Design', 'Marketing', 'Finance', 'Other'];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.existingResume != null;
    if (_isEditing) {
      final r = widget.existingResume!;
      _fullNameController.text = r.fullName;
      _emailController.text = r.email;
      _phoneController.text = r.phone;
      _addressController.text = r.address;
      _summaryController.text = r.summary;
      _skillsController.text = r.skills.join(', ');
      
      // Ensure category is valid or fallback to Other
      _selectedCategory = _categories.contains(r.category) ? r.category : 'Other';
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _summaryController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  void _applyGeneratedContent(Map<String, dynamic> content) {
    setState(() {
      if (content.containsKey('summary')) {
        _summaryController.text = content['summary'] as String;
      }
      if (content.containsKey('skills')) {
        final skillsList = content['skills'] as List;
        _skillsController.text = skillsList.join(', ');
      }
    });
  }

  Future<void> _saveResume() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your session has expired. Please sign in again.')),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    final now = DateTime.now();
    final resume = Resume(
      id: _isEditing
          ? widget.existingResume!.id
          : now.millisecondsSinceEpoch.toString(),
      userId: userId,
      title: _isEditing
          ? widget.existingResume!.title
          : 'Resume - ${now.toLocal()}'.split(' ')[0],
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      summary: _summaryController.text.trim(),
      category: _selectedCategory,
      skills: _skillsController.text
          .trim()
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      workExperience: _isEditing ? widget.existingResume!.workExperience : [],
      education: _isEditing ? widget.existingResume!.education : [],
      certifications: _isEditing ? widget.existingResume!.certifications : [],
      projects: _isEditing ? widget.existingResume!.projects : [],
      createdAt: _isEditing ? widget.existingResume!.createdAt : now,
      updatedAt: now,
    );

    final result = _isEditing
        ? await _resumeService.updateResume(resume)
        : await _resumeService.createResume(resume);

    if (!mounted) return;

    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? 'Resume updated successfully!'
                : 'Resume created successfully!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      },
      failure: (msg) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      },
    );

    if (mounted) setState(() => _isLoading = false);
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Resume' : 'Create Resume')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // ── Basic Info ──────────────────────────────────────────────────
            _buildSectionHeader('Basic Information', Icons.person_outline),
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(labelText: 'Full Name *'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Full name is required' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email *'),
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                    .hasMatch(v.trim())) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    keyboardType: TextInputType.phone,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: _categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(cat),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedCategory = v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address'),
              maxLines: 2,
            ),
            const Divider(height: AppSpacing.xxl),

            // ── Professional Details ────────────────────────────────────────
            _buildSectionHeader('Professional Details', Icons.work_outline),
            TextFormField(
              controller: _summaryController,
              decoration: const InputDecoration(
                labelText: 'Professional Summary',
                alignLabelWithHint: true,
              ),
              maxLines: 4,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _skillsController,
              decoration: const InputDecoration(
                labelText: 'Skills (comma separated)',
                hintText: 'Flutter, Firebase, Dart, ...',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AIGenerateScreen(
                      onContentGenerated: _applyGeneratedContent,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generate with AI'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Save Button ─────────────────────────────────────────────────
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _saveResume,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                    ),
                    child: Text(
                      _isEditing ? 'Update Resume' : 'Save Resume',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
