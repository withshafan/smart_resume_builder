import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/resume.dart';
import '../services/resume_service.dart';

class CreateResumeScreen extends StatefulWidget {
  const CreateResumeScreen({super.key});

  @override
  State<CreateResumeScreen> createState() => _CreateResumeScreenState();
}

class _CreateResumeScreenState extends State<CreateResumeScreen> {
  final _formKey = GlobalKey<FormState>();
  final ResumeService _resumeService = ResumeService();

  // Controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();

  bool _isLoading = false;

  Future<void> _saveResume() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final String id = DateTime.now().millisecondsSinceEpoch.toString();
      final DateTime now = DateTime.now();

      final resume = Resume(
        id: id,
        userId: userId,
        title: 'Resume - ${now.toLocal()}'.split(' ')[0],
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        summary: _summaryController.text.trim(),
        skills: _skillsController.text.trim().split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
        workExperience: [],
        education: [],
        certifications: [],
        projects: [],
        createdAt: now,
        updatedAt: now,
      );

      await _resumeService.createResume(resume);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resume created successfully!')),
        );
        Navigator.pop(context, true); // Return true to refresh list
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
      appBar: AppBar(title: const Text('Create Resume')),
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
                const SizedBox(height: 24),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _saveResume,
                        child: const Text('Save Resume', style: TextStyle(fontSize: 18)),
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
