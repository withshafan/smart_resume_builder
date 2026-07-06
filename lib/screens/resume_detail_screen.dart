import 'package:flutter/material.dart';
import '../models/resume.dart';
import '../services/resume_service.dart';
import 'create_resume_screen.dart';
import '../services/pdf_service.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

class ResumeDetailScreen extends StatefulWidget {
  final Resume resume;

  const ResumeDetailScreen({super.key, required this.resume});

  @override
  State<ResumeDetailScreen> createState() => _ResumeDetailScreenState();
}

class _ResumeDetailScreenState extends State<ResumeDetailScreen> {
  late Resume _resume;
  final ResumeService _resumeService = ResumeService();

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
        content: const Text('Are you sure you want to delete this resume?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _resumeService.deleteResume(_resume.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Resume deleted.')),
          );
          Navigator.pop(context, true); // refresh list
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting: ${e.toString()}')),
          );
        }
      }
    }
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
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateResumeScreen(existingResume: _resume),
                ),
              );
              if (result == true) {
                // Reload the resume data
                try {
                  final updated = await _resumeService.getResume(_resume.id);
                  setState(() => _resume = updated);
                } catch (e) {
                  // ignore
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteResume,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Personal Info
            Text(_resume.fullName, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(_resume.email, style: Theme.of(context).textTheme.bodyMedium),
            if (_resume.phone.isNotEmpty) Text(_resume.phone),
            if (_resume.address.isNotEmpty) Text(_resume.address),
            const Divider(height: 32),
            // Summary
            if (_resume.summary.isNotEmpty) ...[
              Text('Professional Summary', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(_resume.summary),
              const SizedBox(height: 16),
            ],
            // Skills
            if (_resume.skills.isNotEmpty) ...[
              Text('Skills', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _resume.skills.map((skill) => Chip(label: Text(skill))).toList(),
              ),
              const SizedBox(height: 16),
            ],
            // Work Experience
            if (_resume.workExperience.isNotEmpty) ...[
              Text('Work Experience', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ..._resume.workExperience.map((exp) => Card(
                    child: ListTile(
                      title: Text(exp.position),
                      subtitle: Text(exp.company),
                      trailing: Text('${exp.startDate} - ${exp.isCurrent ? "Present" : exp.endDate}'),
                    ),
                  )),
              const SizedBox(height: 16),
            ],
            // Education
            if (_resume.education.isNotEmpty) ...[
              Text('Education', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ..._resume.education.map((edu) => Card(
                    child: ListTile(
                      title: Text(edu.degree),
                      subtitle: Text('${edu.institution} - ${edu.fieldOfStudy}'),
                      trailing: Text('${edu.startDate} - ${edu.isCurrent ? "Present" : edu.endDate}'),
                    ),
                  )),
              const SizedBox(height: 16),
            ],
            // Certifications
            if (_resume.certifications.isNotEmpty) ...[
              Text('Certifications', style: Theme.of(context).textTheme.titleLarge),
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
            // Projects
            if (_resume.projects.isNotEmpty) ...[
              Text('Projects', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ..._resume.projects.map((proj) => Card(
                    child: ListTile(
                      title: Text(proj.name),
                      subtitle: Text(proj.description),
                      trailing: proj.link != null ? const Icon(Icons.link) : null,
                    ),
                  )),
              const SizedBox(height: 16),
            ],
            
            // Export and Preview PDF buttons
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final pdfBytes = await PdfService.generateResumePdf(_resume);
                        await Printing.layoutPdf(
                          onLayout: (PdfPageFormat format) async => pdfBytes,
                        );
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: ${e.toString()}')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.preview),
                    label: const Text('Preview PDF'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        // Show loading indicator
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Generating PDF...')),
                        );
                        
                        final pdfBytes = await PdfService.generateResumePdf(_resume);
                        await PdfService.sharePdf(pdfBytes, '${_resume.fullName}_Resume');
                        
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('PDF shared successfully!')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error generating PDF: ${e.toString()}')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Share PDF'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
