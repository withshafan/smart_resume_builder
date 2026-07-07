import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/resume.dart';
import '../services/resume_service.dart';
import '../services/certificate_db_helper.dart';
import '../theme/app_spacing.dart';
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

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _summaryController = TextEditingController();
  final _skillsController = TextEditingController();

  String _selectedCategory = 'Other';
  bool _isLoading = false;
  bool _isEditing = false;

  List<WorkExperience> _workExperiences = [];
  List<Education> _educations = [];
  List<Certification> _certifications = [];
  List<Project> _projects = [];

  static const _categories = ['Tech', 'Design', 'Marketing', 'Finance', 'Other'];

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
      
      _workExperiences = List<WorkExperience>.from(r.workExperience);
      _educations = List<Education>.from(r.education);
      _certifications = List<Certification>.from(r.certifications);
      _projects = List<Project>.from(r.projects);
      
      // Ensure category is valid or fallback to Other
      _selectedCategory = _categories.contains(r.category) ? r.category : 'Other';
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _summaryController.dispose();
    _skillsController.dispose();
    super.dispose();
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

  Future<String?> _selectDate(BuildContext context, {String? initialValue}) async {
    DateTime initial = DateTime.now();
    if (initialValue != null && initialValue.isNotEmpty) {
      final parts = initialValue.split('-');
      if (parts.length >= 2) {
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (y != null && m != null) {
          initial = DateTime(y, m);
        }
      }
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      return '${picked.year}-${picked.month.toString().padLeft(2, '0')}';
    }
    return null;
  }

  void _showWorkExperienceDialog({int? index}) {
    final isEditing = index != null;
    final item = isEditing ? _workExperiences[index] : null;

    final companyController = TextEditingController(text: item?.company);
    final positionController = TextEditingController(text: item?.position);
    final startDateController = TextEditingController(text: item?.startDate);
    final endDateController = TextEditingController(text: item?.endDate);
    bool isCurrent = item?.isCurrent ?? false;
    final respController = TextEditingController(text: item?.responsibilities.join(', '));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.work_history_outlined, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(isEditing ? 'Edit Work Experience' : 'Add Work Experience', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: companyController,
                  decoration: const InputDecoration(labelText: 'Company *', prefixIcon: Icon(Icons.business)),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: positionController,
                  decoration: const InputDecoration(labelText: 'Position *', prefixIcon: Icon(Icons.badge)),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: startDateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Start Date *',
                    prefixIcon: Icon(Icons.calendar_today),
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                  onTap: () async {
                    final date = await _selectDate(ctx, initialValue: startDateController.text);
                    if (date != null) setDialogState(() => startDateController.text = date);
                  },
                ),
                CheckboxListTile(
                  title: const Text('Currently Work Here', style: TextStyle(fontSize: 14)),
                  value: isCurrent,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() => isCurrent = v);
                    }
                  },
                ),
                if (!isCurrent) ...[
                  TextField(
                    controller: endDateController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'End Date',
                      prefixIcon: Icon(Icons.calendar_today),
                      suffixIcon: Icon(Icons.arrow_drop_down),
                    ),
                    onTap: () async {
                      final date = await _selectDate(ctx, initialValue: endDateController.text);
                      if (date != null) setDialogState(() => endDateController.text = date);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                TextField(
                  controller: respController,
                  decoration: const InputDecoration(
                    labelText: 'Responsibilities (comma separated)',
                    prefixIcon: Icon(Icons.list),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (companyController.text.trim().isEmpty ||
                    positionController.text.trim().isEmpty ||
                    startDateController.text.trim().isEmpty) {
                  return;
                }
                final resp = respController.text
                    .split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();
                
                final newItem = WorkExperience(
                  company: companyController.text.trim(),
                  position: positionController.text.trim(),
                  startDate: startDateController.text.trim(),
                  endDate: isCurrent ? null : endDateController.text.trim(),
                  isCurrent: isCurrent,
                  responsibilities: resp,
                );

                setState(() {
                  if (isEditing) {
                    _workExperiences[index] = newItem;
                  } else {
                    _workExperiences.add(newItem);
                  }
                });
                Navigator.pop(ctx);
              },
              child: Text(isEditing ? 'Save' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEducationDialog({int? index}) {
    final isEditing = index != null;
    final item = isEditing ? _educations[index] : null;

    final institutionController = TextEditingController(text: item?.institution);
    final degreeController = TextEditingController(text: item?.degree);
    final fieldController = TextEditingController(text: item?.fieldOfStudy);
    final startDateController = TextEditingController(text: item?.startDate);
    final endDateController = TextEditingController(text: item?.endDate);
    bool isCurrent = item?.isCurrent ?? false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.school_outlined, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(isEditing ? 'Edit Education' : 'Add Education', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: institutionController,
                  decoration: const InputDecoration(labelText: 'Institution *', prefixIcon: Icon(Icons.account_balance)),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: degreeController,
                  decoration: const InputDecoration(labelText: 'Degree *', prefixIcon: Icon(Icons.school)),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: fieldController,
                  decoration: const InputDecoration(labelText: 'Field of Study *', prefixIcon: Icon(Icons.book)),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: startDateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Start Date *',
                    prefixIcon: Icon(Icons.calendar_today),
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                  onTap: () async {
                    final date = await _selectDate(ctx, initialValue: startDateController.text);
                    if (date != null) setDialogState(() => startDateController.text = date);
                  },
                ),
                CheckboxListTile(
                  title: const Text('Currently Enrolled', style: TextStyle(fontSize: 14)),
                  value: isCurrent,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() => isCurrent = v);
                    }
                  },
                ),
                if (!isCurrent) ...[
                  TextField(
                    controller: endDateController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'End Date',
                      prefixIcon: Icon(Icons.calendar_today),
                      suffixIcon: Icon(Icons.arrow_drop_down),
                    ),
                    onTap: () async {
                      final date = await _selectDate(ctx, initialValue: endDateController.text);
                      if (date != null) setDialogState(() => endDateController.text = date);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (institutionController.text.trim().isEmpty ||
                    degreeController.text.trim().isEmpty ||
                    fieldController.text.trim().isEmpty ||
                    startDateController.text.trim().isEmpty) {
                  return;
                }

                final newItem = Education(
                  institution: institutionController.text.trim(),
                  degree: degreeController.text.trim(),
                  fieldOfStudy: fieldController.text.trim(),
                  startDate: startDateController.text.trim(),
                  endDate: isCurrent ? null : endDateController.text.trim(),
                  isCurrent: isCurrent,
                );

                setState(() {
                  if (isEditing) {
                    _educations[index] = newItem;
                  } else {
                    _educations.add(newItem);
                  }
                });
                Navigator.pop(ctx);
              },
              child: Text(isEditing ? 'Save' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCertificationDialog({int? index}) {
    final isEditing = index != null;
    final item = isEditing ? _certifications[index] : null;

    final nameController = TextEditingController(text: item?.name);
    final orgController = TextEditingController(text: item?.issuingOrganization);
    final dateController = TextEditingController(text: item?.issueDate);
    String? fileUrl = item?.fileUrl;
    String? fileName = item?.fileName;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.verified_outlined, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(isEditing ? 'Edit Certification' : 'Add Certification', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Certification Name *', prefixIcon: Icon(Icons.card_membership)),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: orgController,
                  decoration: const InputDecoration(labelText: 'Issuing Organization *', prefixIcon: Icon(Icons.business)),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: dateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Issue Date *',
                    prefixIcon: Icon(Icons.calendar_today),
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                  onTap: () async {
                    final date = await _selectDate(ctx, initialValue: dateController.text);
                    if (date != null) setDialogState(() => dateController.text = date);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                if (isUploading)
                  const Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('Uploading certificate...', style: TextStyle(fontSize: 12)),
                    ],
                  )
                else if (fileUrl != null && fileName != null)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer.withAlpha(50),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Theme.of(context).colorScheme.outline.withAlpha(20)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.attach_file, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            fileName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.cancel, color: Theme.of(context).colorScheme.error, size: 20),
                          onPressed: () {
                            setDialogState(() {
                              fileUrl = null;
                              fileName = null;
                            });
                          },
                        ),
                      ],
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        final result = await fp.FilePicker.pickFiles(
                          type: fp.FileType.custom,
                          allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
                        );
                        if (result != null && result.files.isNotEmpty) {
                          setDialogState(() => isUploading = true);
                          final pickedFile = result.files.first;
                          if (pickedFile.path == null) throw Exception("Cannot read file path. Pick a local file.");

                          final appDir = await getApplicationDocumentsDirectory();
                          final uniqueName = '${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';
                          final localFile = File(p.join(appDir.path, uniqueName));
                          
                          // Copy file to local directory
                          await File(pickedFile.path!).copy(localFile.path);

                          // Insert into SQLite database
                          await CertificateDbHelper.instance.insertCertificate({
                            'fileName': pickedFile.name,
                            'localPath': localFile.path,
                          });

                          setDialogState(() {
                            fileUrl = 'file://${localFile.path}';
                            fileName = pickedFile.name;
                            isUploading = false;
                          });
                        }
                      } catch (e) {
                        debugPrint("❌ UPLOAD ERROR: $e");
                        setDialogState(() => isUploading = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('Failed to upload file: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload Certificate (PDF/Image)'),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty ||
                    orgController.text.trim().isEmpty ||
                    dateController.text.trim().isEmpty) {
                  return;
                }

                final newItem = Certification(
                  name: nameController.text.trim(),
                  issuingOrganization: orgController.text.trim(),
                  issueDate: dateController.text.trim(),
                  fileUrl: fileUrl,
                  fileName: fileName,
                );

                setState(() {
                  if (isEditing) {
                    _certifications[index] = newItem;
                  } else {
                    _certifications.add(newItem);
                  }
                });
                Navigator.pop(ctx);
              },
              child: Text(isEditing ? 'Save' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showProjectDialog({int? index}) {
    final isEditing = index != null;
    final item = isEditing ? _projects[index] : null;

    final nameController = TextEditingController(text: item?.name);
    final descController = TextEditingController(text: item?.description);
    final linkController = TextEditingController(text: item?.link);
    final techController = TextEditingController(text: item?.technologies.join(', '));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.folder_special_outlined, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: AppSpacing.sm),
            Text(isEditing ? 'Edit Project' : 'Add Project', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Project Name *', prefixIcon: Icon(Icons.title)),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description *', prefixIcon: Icon(Icons.description)),
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: linkController,
                decoration: const InputDecoration(labelText: 'Project Link', prefixIcon: Icon(Icons.link)),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: techController,
                decoration: const InputDecoration(labelText: 'Technologies (comma separated)', prefixIcon: Icon(Icons.psychology)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty ||
                  descController.text.trim().isEmpty) {
                return;
              }

              final newItem = Project(
                name: nameController.text.trim(),
                description: descController.text.trim(),
                link: linkController.text.trim().isEmpty ? null : linkController.text.trim(),
                technologies: techController.text
                    .split(',')
                    .map((t) => t.trim())
                    .where((t) => t.isNotEmpty)
                    .toList(),
              );

              setState(() {
                if (isEditing) {
                  _projects[index] = newItem;
                } else {
                  _projects.add(newItem);
                }
              });
              Navigator.pop(ctx);
            },
            child: Text(isEditing ? 'Save' : 'Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveResume() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your session has expired. Please sign in again.')),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    final now = DateTime.now();
    final resume = Resume(
      id: _isEditing
          ? widget.existingResume!.id
          : now.millisecondsSinceEpoch.toString(),
      userId: userId,
      title: _isEditing
          ? widget.existingResume!.title
          : 'Resume - ${now.toLocal()}'.split(' ')[0],
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      summary: _summaryController.text.trim(),
      category: _selectedCategory,
      skills: _skillsController.text
          .trim()
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      workExperience: _workExperiences,
      education: _educations,
      certifications: _certifications,
      projects: _projects,
      createdAt: _isEditing ? widget.existingResume!.createdAt : now,
      updatedAt: now,
    );

    final result = _isEditing
        ? await _resumeService.updateResume(resume)
        : await _resumeService.createResume(resume);

    if (!mounted) return;

    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? 'Resume updated successfully!'
                : 'Resume created successfully!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      },
      failure: (msg) {
        // Log the error to the terminal so we can see it
        debugPrint('❌ SAVE ERROR: $msg');
        
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Error Saving Resume'),
            content: Text('Something went wrong:\n\n$msg\n\nPlease check your internet and Firestore settings.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      },
    );

    if (mounted) setState(() => _isLoading = false);
  }

  Widget _buildListSection<T>({
    required String title,
    required IconData icon,
    required List<T> items,
    required Color accentColor,
    required VoidCallback onAdd,
    required void Function(int) onEdit,
    required void Function(int) onDelete,
    required String Function(T) getTitle,
    required String Function(T) getSubtitle,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: accentColor, size: 22),
                const SizedBox(width: AppSpacing.sm),
                Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            IconButton(
              icon: Icon(Icons.add_circle_outline, color: accentColor),
              onPressed: onAdd,
            ),
          ],
        ),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text(
              'No items added yet.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withAlpha(150),
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outline.withAlpha(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(5),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          width: 4,
                          color: accentColor,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  getTitle(item),
                                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  getSubtitle(item),
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              onPressed: () => onEdit(index),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline, size: 20, color: theme.colorScheme.error),
                              onPressed: () => onDelete(index),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        const Divider(height: AppSpacing.xl),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Resume' : 'Create Resume')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // ── Basic Info ──────────────────────────────────────────────────
            _buildSectionHeader('Basic Information', Icons.person_outline),
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(labelText: 'Full Name *'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Full name is required' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email *'),
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                    .hasMatch(v.trim())) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    keyboardType: TextInputType.phone,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: _categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(cat),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedCategory = v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address'),
              maxLines: 2,
            ),
            const Divider(height: AppSpacing.xxl),

            // ── Professional Details ────────────────────────────────────────
            _buildSectionHeader('Professional Details', Icons.work_outline),
            TextFormField(
              controller: _summaryController,
              decoration: const InputDecoration(
                labelText: 'Professional Summary',
                alignLabelWithHint: true,
              ),
              maxLines: 4,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _skillsController,
              decoration: const InputDecoration(
                labelText: 'Skills (comma separated)',
                hintText: 'Flutter, Firebase, Dart, ...',
              ),
            ),
            const Divider(height: AppSpacing.xxl),

            // ── Dynamic Sections ────────────────────────────────────────────
            _buildListSection<WorkExperience>(
              title: 'Work Experience',
              icon: Icons.work_history_outlined,
              items: _workExperiences,
              accentColor: Colors.blue,
              onAdd: _showWorkExperienceDialog,
              onEdit: (idx) => _showWorkExperienceDialog(index: idx),
              onDelete: (idx) => setState(() => _workExperiences.removeAt(idx)),
              getTitle: (item) => item.position,
              getSubtitle: (item) => '${item.company} (${item.startDate} - ${item.isCurrent ? "Present" : item.endDate ?? ""})',
            ),

            _buildListSection<Education>(
              title: 'Education',
              icon: Icons.school_outlined,
              items: _educations,
              accentColor: Colors.purple,
              onAdd: _showEducationDialog,
              onEdit: (idx) => _showEducationDialog(index: idx),
              onDelete: (idx) => setState(() => _educations.removeAt(idx)),
              getTitle: (item) => item.degree,
              getSubtitle: (item) => '${item.institution} — ${item.fieldOfStudy} (${item.startDate} - ${item.isCurrent ? "Present" : item.endDate ?? ""})',
            ),

            _buildListSection<Certification>(
              title: 'Certifications',
              icon: Icons.verified_outlined,
              items: _certifications,
              accentColor: Colors.green,
              onAdd: _showCertificationDialog,
              onEdit: (idx) => _showCertificationDialog(index: idx),
              onDelete: (idx) => setState(() => _certifications.removeAt(idx)),
              getTitle: (item) => item.name,
              getSubtitle: (item) => '${item.issuingOrganization} (${item.issueDate})',
            ),

            _buildListSection<Project>(
              title: 'Projects',
              icon: Icons.folder_special_outlined,
              items: _projects,
              accentColor: Colors.teal,
              onAdd: _showProjectDialog,
              onEdit: (idx) => _showProjectDialog(index: idx),
              onDelete: (idx) => setState(() => _projects.removeAt(idx)),
              getTitle: (item) => item.name,
              getSubtitle: (item) => item.description,
            ),

            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: () async {
                await Navigator.push(
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
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Save Button ─────────────────────────────────────────────────
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _saveResume,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                    ),
                    child: Text(
                      _isEditing ? 'Update Resume' : 'Save Resume',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
