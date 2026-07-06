import 'package:flutter/material.dart';
import '../models/resume.dart';
import '../services/resume_service.dart';
import '../services/pdf_service.dart';
import '../utils/result.dart';
import 'create_resume_screen.dart';

class ResumeDetailScreen extends StatefulWidget {
  final Resume resume;
  const ResumeDetailScreen({super.key, required this.resume});

  @override
  State<ResumeDetailScreen> createState() => _ResumeDetailScreenState();
}

class _ResumeDetailScreenState extends State<ResumeDetailScreen> {
  late Resume _resume;
  final ResumeService _resumeService = ResumeService();
  bool _pdfLoading = false;

  @override
  void initState() {
    super.initState();
    _resume = widget.resume;
  }

  Future<void> _deleteResume() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Resume'),
        content: const Text('This cannot be undone. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final result = await _resumeService.deleteResume(_resume.id);
    if (!mounted) return;
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Resume deleted.'),
              behavior: SnackBarBehavior.floating),
        );
        Navigator.pop(context, true);
      },
      failure: (msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(msg),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error),
      ),
    );
  }

  Future<void> _handlePdf({required bool share}) async {
    setState(() => _pdfLoading = true);
    final genResult = await PdfService.generateResumePdf(_resume);
    if (!mounted) return;

    void showError(String msg) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(msg),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    }

    if (genResult.isFailure) {
      showError((genResult as Failure<dynamic>).userMessage);
    } else {
      final bytes = genResult.dataOrNull!;
      final actionResult = share
          ? await PdfService.sharePdf(bytes, '${_resume.fullName}_Resume')
          : await PdfService.previewPdf(bytes);
      if (mounted) {
        actionResult.when(
          success: (_) {},
          failure: showError,
        );
      }
    }

    if (mounted) setState(() => _pdfLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_resume.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      CreateResumeScreen(existingResume: _resume),
                ),
              );
              if (updated == true) {
                final result = await _resumeService.getResume(_resume.id);
                if (mounted) {
                  result.when(
                    success: (r) => setState(() => _resume = r),
                    failure: (_) {},
                  );
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteResume,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_resume.fullName,
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(_resume.email),
            if (_resume.phone.isNotEmpty) Text(_resume.phone),
            if (_resume.address.isNotEmpty) Text(_resume.address),
            const Divider(height: 32),
            if (_resume.summary.isNotEmpty) ...[
              Text('Professional Summary',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(_resume.summary),
              const SizedBox(height: 16),
            ],
            if (_resume.skills.isNotEmpty) ...[
              Text('Skills', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children:
                    _resume.skills.map((s) => Chip(label: Text(s))).toList(),
              ),
              const SizedBox(height: 16),
            ],
            if (_resume.workExperience.isNotEmpty) ...[
              Text('Work Experience',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ..._resume.workExperience.map((exp) => Card(
                    child: ListTile(
                      title: Text(exp.position),
                      subtitle: Text(exp.company),
                      trailing: Text(
                          '${exp.startDate} - ${exp.isCurrent ? "Present" : (exp.endDate ?? "")}'),
                    ),
                  )),
              const SizedBox(height: 16),
            ],
            if (_resume.education.isNotEmpty) ...[
              Text('Education',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ..._resume.education.map((edu) => Card(
                    child: ListTile(
                      title: Text(edu.degree),
                      subtitle:
                          Text('${edu.institution} — ${edu.fieldOfStudy}'),
                      trailing: Text(
                          '${edu.startDate} - ${edu.isCurrent ? "Present" : (edu.endDate ?? "")}'),
                    ),
                  )),
              const SizedBox(height: 16),
            ],
            if (_resume.certifications.isNotEmpty) ...[
              Text('Certifications',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ..._resume.certifications.map((cert) => Card(
                    child: ListTile(
                      title: Text(cert.name),
                      subtitle: Text(cert.issuingOrganization),
                      trailing: Text(cert.issueDate),
                    ),
                  )),
              const SizedBox(height: 16),
            ],
            if (_resume.projects.isNotEmpty) ...[
              Text('Projects',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ..._resume.projects.map((proj) => Card(
                    child: ListTile(
                      title: Text(proj.name),
                      subtitle: Text(proj.description),
                      trailing: proj.link != null
                          ? const Icon(Icons.link)
                          : null,
                    ),
                  )),
              const SizedBox(height: 16),
            ],
            const Divider(),
            const SizedBox(height: 8),
            if (_pdfLoading)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _handlePdf(share: false),
                      icon: const Icon(Icons.preview),
                      label: const Text('Preview PDF'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handlePdf(share: true),
                      icon: const Icon(Icons.share),
                      label: const Text('Share PDF'),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
