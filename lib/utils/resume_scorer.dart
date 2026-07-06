import '../models/resume.dart';

/// Computes a heuristic completeness score (0–100) for a [Resume].
///
/// No AI call. Purely based on section presence, word counts, and
/// the use of action verbs in the summary.
///
/// Scoring breakdown:
///   - Full name present         → 10 pts
///   - Email present             → 5 pts
///   - Phone present             → 5 pts
///   - Summary ≥ 20 words        → 15 pts (partial: ≥ 5 words → 8 pts)
///   - Summary has action verb   → 5 pts
///   - ≥ 3 skills                → 10 pts (partial: ≥ 1 skill → 5 pts)
///   - ≥ 1 work experience       → 20 pts (each entry with responsibilities → +5, max 10)
///   - ≥ 1 education entry       → 15 pts
///   - ≥ 1 certification         → 5 pts
///   - ≥ 1 project               → 10 pts
abstract final class ResumeScorer {
  static const _actionVerbs = [
    'led', 'built', 'designed', 'developed', 'managed', 'created', 'improved',
    'optimized', 'delivered', 'achieved', 'launched', 'implemented', 'drove',
    'spearheaded', 'coordinated', 'established', 'reduced', 'increased',
    'streamlined', 'authored', 'engineered',
  ];

  /// Returns a score in [0, 100].
  static int score(Resume resume) {
    var pts = 0;

    // Personal info
    if (resume.fullName.trim().isNotEmpty) pts += 10;
    if (resume.email.trim().isNotEmpty) pts += 5;
    if (resume.phone.trim().isNotEmpty) pts += 5;

    // Summary
    final summaryWords = _wordCount(resume.summary);
    if (summaryWords >= 20) {
      pts += 15;
    } else if (summaryWords >= 5) {
      pts += 8;
    }
    if (_hasActionVerb(resume.summary)) pts += 5;

    // Skills
    if (resume.skills.length >= 3) {
      pts += 10;
    } else if (resume.skills.isNotEmpty) {
      pts += 5;
    }

    // Work experience
    if (resume.workExperience.isNotEmpty) {
      pts += 20;
      // Bonus: responsibilities filled in
      final withResp = resume.workExperience
          .where((e) => e.responsibilities.isNotEmpty)
          .length;
      pts += (withResp * 5).clamp(0, 10);
    }

    // Education
    if (resume.education.isNotEmpty) pts += 15;

    // Certifications
    if (resume.certifications.isNotEmpty) pts += 5;

    // Projects
    if (resume.projects.isNotEmpty) pts += 10;

    return pts.clamp(0, 100);
  }

  static int _wordCount(String text) =>
      text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;

  static bool _hasActionVerb(String text) {
    final lower = text.toLowerCase();
    return _actionVerbs.any((v) => lower.contains(v));
  }
}
