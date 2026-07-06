import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:typed_data';
import '../models/resume.dart';
import '../utils/result.dart';

class PdfService {
  /// Generate a PDF document from a Resume object.
  /// Returns [Result.fail] with a user-friendly message if generation fails.
  static Future<Result<Uint8List>> generateResumePdf(Resume resume) async {
    try {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header: Name
              pw.Text(
                resume.fullName,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              // Contact Info
              pw.Text(
                '${resume.email}${resume.phone.isNotEmpty ? ' | ${resume.phone}' : ''}${resume.address.isNotEmpty ? ' | ${resume.address}' : ''}',
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
              ),
              pw.Divider(),
              pw.SizedBox(height: 8),

              // Professional Summary
              if (resume.summary.isNotEmpty) ...[
                pw.Text(
                  'Professional Summary',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),
                pw.Text(resume.summary, style: pw.TextStyle(fontSize: 12)),
                pw.SizedBox(height: 12),
              ],

              // Skills
              if (resume.skills.isNotEmpty) ...[
                pw.Text(
                  'Skills',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),
                pw.Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: resume.skills.map((skill) => pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey300),
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(skill, style: pw.TextStyle(fontSize: 10)),
                      )).toList(),
                ),
                pw.SizedBox(height: 12),
              ],

              // Work Experience
              if (resume.workExperience.isNotEmpty) ...[
                pw.Text(
                  'Work Experience',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),
                ...resume.workExperience.map((exp) => pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              exp.position,
                              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.Text(
                              '${exp.startDate} - ${exp.isCurrent ? "Present" : exp.endDate}',
                              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                            ),
                          ],
                        ),
                        pw.Text(
                          exp.company,
                          style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic),
                        ),
                        pw.SizedBox(height: 4),
                        ...exp.responsibilities.map((resp) => pw.Text(
                              '• $resp',
                              style: pw.TextStyle(fontSize: 11),
                            )),
                        pw.SizedBox(height: 8),
                      ],
                    )),
              ],

              // Education
              if (resume.education.isNotEmpty) ...[
                pw.Text(
                  'Education',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),
                ...resume.education.map((edu) => pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              edu.degree,
                              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.Text(
                              '${edu.startDate} - ${edu.isCurrent ? "Present" : edu.endDate}',
                              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                            ),
                          ],
                        ),
                        pw.Text(
                          '${edu.institution} - ${edu.fieldOfStudy}',
                          style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic),
                        ),
                        pw.SizedBox(height: 8),
                      ],
                    )),
              ],

              // Certifications
              if (resume.certifications.isNotEmpty) ...[
                pw.Text(
                  'Certifications',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),
                ...resume.certifications.map((cert) => pw.Text(
                      '• ${cert.name} - ${cert.issuingOrganization} (${cert.issueDate})',
                      style: pw.TextStyle(fontSize: 11),
                    )),
                pw.SizedBox(height: 8),
              ],

              // Projects
              if (resume.projects.isNotEmpty) ...[
                pw.Text(
                  'Projects',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),
                ...resume.projects.map((proj) => pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          proj.name,
                          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(proj.description, style: pw.TextStyle(fontSize: 11)),
                        if (proj.technologies.isNotEmpty)
                          pw.Text(
                            'Technologies: ${proj.technologies.join(", ")}',
                            style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
                          ),
                        pw.SizedBox(height: 4),
                      ],
                    )),
              ],
            ],
          );
        },
      ),
    );

      return Result.ok(await pdf.save());
    } catch (e) {
      return Result.fail(
        "Couldn't generate the PDF. Make sure your resume has at least a name.",
        cause: e,
      );
    }
  }

  /// Share or print the PDF.
  static Future<Result<void>> sharePdf(Uint8List pdfBytes, String fileName) async {
    try {
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: '$fileName.pdf',
      );
      return Result.ok(null);
    } catch (e) {
      return Result.fail("Couldn't share the PDF. Please try again.", cause: e);
    }
  }

  /// Preview PDF in the system print dialog.
  static Future<Result<void>> previewPdf(Uint8List pdfBytes) async {
    try {
      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdfBytes);
      return Result.ok(null);
    } catch (e) {
      return Result.fail("Couldn't preview the PDF. Please try again.", cause: e);
    }
  }
}
