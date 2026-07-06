import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/resume.dart';
import '../services/resume_service.dart';
import '../services/pdf_service.dart';
import '../utils/result.dart';
import '../utils/resume_scorer.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../widgets/score_ring.dart';
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
        title: const Text('Move to Trash'),
        content: const Text('This resume will be moved to the Trash.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
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
              content: Text('Moved to Trash.'),
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
    final theme = Theme.of(context);
    final score = ResumeScorer.score(_resume);

    return Scaffold(
      appBar: AppBar(
        title: Text(_resume.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Resume',
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
            tooltip: 'Move to Trash',
            onPressed: _deleteResume,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header & Score Card ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outline.withAlpha(40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(5),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _resume.fullName.isNotEmpty
                              ? _resume.fullName
                              : 'Untitled',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.categoryColor(_resume.category)
                                    .withAlpha(30),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _resume.category,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.categoryColor(_resume.category),
                                ),
                              ),
                            ),
                            Text(
                              'Updated ${_resume.updatedAt.toLocal().toString().split(' ')[0]}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    children: [
                      ScoreRing(score: score, size: 56, strokeWidth: 5),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Completeness',
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── PDF Actions ─────────────────────────────────────────────────
            if (_pdfLoading)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _handlePdf(share: false),
                      icon: const Icon(Icons.preview_outlined),
                      label: const Text('Preview PDF'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handlePdf(share: true),
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('Share PDF'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: AppSpacing.xxl),

            // ── Resume Content Preview ──────────────────────────────────────
            if (_resume.email.isNotEmpty ||
                _resume.phone.isNotEmpty ||
                _resume.address.isNotEmpty) ...[
              Text('Contact', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              if (_resume.email.isNotEmpty)
                _buildContactRow(context, Icons.email_outlined, _resume.email),
              if (_resume.phone.isNotEmpty)
                _buildContactRow(context, Icons.phone_outlined, _resume.phone),
              if (_resume.address.isNotEmpty)
                _buildContactRow(context, Icons.location_on_outlined, _resume.address),
              const SizedBox(height: AppSpacing.xl),
            ],

            if (_resume.summary.isNotEmpty) ...[
              Text('Professional Summary', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _resume.summary,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],

            if (_resume.skills.isNotEmpty) ...[
              Text('Skills', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _resume.skills
                    .map((s) => Chip(
                          label: Text(s),
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          side: BorderSide.none,
                        ))
                    .toList(),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],

            if (_resume.workExperience.isNotEmpty) ...[
              Text('Work Experience', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              ..._resume.workExperience.map((exp) => _buildExperienceCard(
                    context,
                    title: exp.position,
                    subtitle: exp.company,
                    trailing:
                        '${exp.startDate} - ${exp.isCurrent ? "Present" : (exp.endDate ?? "")}',
                  )),
              const SizedBox(height: AppSpacing.lg),
            ],

            if (_resume.education.isNotEmpty) ...[
              Text('Education', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              ..._resume.education.map((edu) => _buildExperienceCard(
                    context,
                    title: edu.degree,
                    subtitle: '${edu.institution} — ${edu.fieldOfStudy}',
                    trailing:
                        '${edu.startDate} - ${edu.isCurrent ? "Present" : (edu.endDate ?? "")}',
                  )),
              const SizedBox(height: AppSpacing.lg),
            ],
            
            if (_resume.certifications.isNotEmpty) ...[
              Text('Certifications', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              ..._resume.certifications.map((cert) => _buildExperienceCard(
                    context,
                    title: cert.name,
                    subtitle: cert.issuingOrganization,
                    trailing: cert.issueDate,
                    fileUrl: cert.fileUrl,
                  )),
              const SizedBox(height: AppSpacing.lg),
            ],
            
            if (_resume.projects.isNotEmpty) ...[
              Text('Projects', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              ..._resume.projects.map((proj) => _buildExperienceCard(
                    context,
                    title: proj.name,
                    subtitle: proj.description,
                    trailing: proj.link != null ? 'Link provided' : '',
                  )),
              const SizedBox(height: AppSpacing.lg),
            ],
            
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String trailing,
    String? fileUrl,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outline.withAlpha(30)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                if (trailing.isNotEmpty) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    trailing,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                if (fileUrl != null && fileUrl.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.attachment_outlined, size: 20),
                    tooltip: 'View Certificate',
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    onPressed: () async {
                      final uri = Uri.parse(fileUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Could not open file link.')),
                          );
                        }
                      }
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
