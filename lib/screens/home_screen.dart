import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/resume_service.dart';
import '../models/resume.dart';
import 'create_resume_screen.dart';
import 'resume_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ResumeService _resumeService = ResumeService();
  List<Resume> _resumes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadResumes();
  }

  Future<void> _loadResumes() async {
    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);
    final result = await _resumeService.getResumes();
    if (!mounted) return;
    result.when(
      success: (resumes) => setState(() => _resumes = resumes),
      failure: (msg) => messenger.showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
      ),
    );
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Resume Builder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final nav = Navigator.of(context);
              await FirebaseAuth.instance.signOut();
              nav.pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _resumes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.description_outlined, size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No resumes yet',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap + to create your first resume',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _resumes.length,
                  itemBuilder: (context, index) {
                    final resume = _resumes[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(resume.fullName.isNotEmpty
                              ? resume.fullName[0].toUpperCase()
                              : '?'),
                        ),
                        title: Text(resume.fullName.isNotEmpty
                            ? resume.fullName
                            : 'Untitled'),
                        subtitle: Text(
                          '${resume.skills.take(3).join(', ')}${resume.skills.length > 3 ? '...' : ''}',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () async {
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ResumeDetailScreen(resume: resume),
                            ),
                          );
                          if (result == true) _loadResumes();
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
                builder: (context) => const CreateResumeScreen()),
          );
          if (result == true) _loadResumes();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
