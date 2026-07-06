import 'package:flutter/material.dart';
import '../models/resume.dart';
import '../services/resume_service.dart';
import '../theme/app_spacing.dart';
import '../widgets/resume_card.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  final ResumeService _resumeService = ResumeService();
  List<Resume> _trashedResumes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrashedResumes();
  }

  Future<void> _loadTrashedResumes() async {
    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);
    final result = await _resumeService.getTrashedResumes();
    if (!mounted) return;
    
    result.when(
      success: (resumes) {
        setState(() {
          _trashedResumes = resumes;
        });
      },
      failure: (msg) => messenger.showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
      ),
    );
    setState(() => _isLoading = false);
  }

  Future<void> _handleRestore(Resume resume) async {
    setState(() => _isLoading = true);
    final result = await _resumeService.restoreResume(resume.id);
    if (mounted) {
      result.when(
        success: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Resume restored'), behavior: SnackBarBehavior.floating),
          );
          _loadTrashedResumes();
        },
        failure: (msg) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating, backgroundColor: Theme.of(context).colorScheme.error),
          );
          setState(() => _isLoading = false);
        },
      );
    }
  }

  Future<void> _handlePermanentDelete(Resume resume) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Permanently'),
        content: const Text('This resume will be permanently deleted and cannot be recovered. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    final result = await _resumeService.permanentlyDeleteResume(resume.id);
    if (mounted) {
      result.when(
        success: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Resume permanently deleted'), behavior: SnackBarBehavior.floating),
          );
          _loadTrashedResumes();
        },
        failure: (msg) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating, backgroundColor: Theme.of(context).colorScheme.error),
          );
          setState(() => _isLoading = false);
        },
      );
    }
  }

  void _showOptionsDialog(Resume resume) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.restore),
              title: const Text('Restore Resume'),
              onTap: () {
                Navigator.pop(context);
                _handleRestore(resume);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_forever, color: Theme.of(context).colorScheme.error),
              title: Text('Delete Permanently', style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onTap: () {
                Navigator.pop(context);
                _handlePermanentDelete(resume);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trash'),
      ),
      body: _isLoading
          ? _buildSkeleton()
          : _trashedResumes.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: _trashedResumes.length,
                  itemBuilder: (context, index) {
                    final resume = _trashedResumes[index];
                    return ResumeCard(
                      resume: resume,
                      score: 0, // Trashed items don't need scores really, but component requires it
                      onTap: () => _showOptionsDialog(resume),
                    );
                  },
                ),
    );
  }

  Widget _buildSkeleton() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, size: 80, color: theme.colorScheme.onSurface.withAlpha(60)),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Trash is empty',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Deleted resumes will appear here.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
