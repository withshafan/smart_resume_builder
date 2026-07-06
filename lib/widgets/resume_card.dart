import 'package:flutter/material.dart';
import '../models/resume.dart';
import '../theme/app_theme.dart';
import '../theme/app_spacing.dart';
import 'score_ring.dart';

/// A resume list card with a left colored category tab and a completeness ring.
class ResumeCard extends StatelessWidget {
  const ResumeCard({
    super.key,
    required this.resume,
    required this.score,
    required this.onTap,
  });

  final Resume resume;

  /// Completeness score 0–100 from [ResumeScorer].
  final int score;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tabColor = AppColors.categoryColor(resume.category);
    final initials = resume.fullName.isNotEmpty
        ? resume.fullName.trim().split(' ').take(2).map((w) => w[0]).join()
        : '?';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // ── Left category tab ─────────────────────────────────────────
              Container(width: 5, color: tabColor),

              // ── Card body ─────────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.md12),
                  child: Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: tabColor.withAlpha(40),
                        child: Text(
                          initials,
                          style: theme.textTheme.titleSmall?.copyWith(
                              color: tabColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),

                      // Name + skills
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              resume.fullName.isNotEmpty
                                  ? resume.fullName
                                  : 'Untitled',
                              style: theme.textTheme.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              resume.skills.isEmpty
                                  ? resume.category
                                  : resume.skills.take(3).join(' · '),
                              style: theme.textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),

                      // Completeness ring
                      ScoreRing(score: score, size: 42, strokeWidth: 4),

                      const SizedBox(width: AppSpacing.sm),
                      Icon(Icons.chevron_right,
                          color: theme.colorScheme.onSurfaceVariant, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
