import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/resume.dart';
import '../services/resume_service.dart';
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

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();

  bool _isLoading = false;
  bool _isEditing = false;

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
    }
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

    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final DateTime now = DateTime.now();

      final resume = Resume(
        id: _isEditing ? widget.existingResume!.id : DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        title: _isEditing ? widget.existingResume!.title : 'Resume - ${now.toLocal()}'.split(' ')[0],
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        summary: _summaryController.text.trim(),
        skills: _skillsController.text.trim().split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
        workExperience: _isEditing ? widget.existingResume!.workExperience : [],
        education: _isEditing ? widget.existingResume!.education : [],
        certifications: _isEditing ? widget.existingResume!.certifications : [],
        projects: _isEditing ? widget.existingResume!.projects : [],
        createdAt: _isEditing ? widget.existingResume!.createdAt : now,
        updatedAt: now,
      );

      if (_isEditing) {
        await _resumeService.updateResume(resume);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Resume updated successfully!')),
          );
        }
      } else {
        await _resumeService.createResume(resume);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Resume created successfully!')),
          );
        }
      }
      
      if (mounted) {
        Navigator.pop(context, true); // return true to refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Resume' : 'Create Resume')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v?.isEmpty ?? true) return 'Required';
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v!)) {
                      return 'Enter valid email';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                ),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                  maxLines: 2,
                ),
                TextFormField(
                  controller: _summaryController,
                  decoration: const InputDecoration(labelText: 'Professional Summary'),
                  maxLines: 4,
                ),
                TextFormField(
                  controller: _skillsController,
                  decoration: const InputDecoration(
                    labelText: 'Skills (comma separated)',
                    hintText: 'Flutter, Firebase, Dart, ...',
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
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
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.purple.shade100,
                    foregroundColor: Colors.purple.shade900,
                  ),
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _saveResume,
                        child: Text(_isEditing ? 'Update Resume' : 'Save Resume', style: const TextStyle(fontSize: 18)),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
