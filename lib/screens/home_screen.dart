import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../services/resume_service.dart';
import '../models/resume.dart';
import '../theme/app_theme.dart';
import '../theme/app_spacing.dart';
import '../utils/resume_scorer.dart';
import '../widgets/resume_card.dart';
import 'create_resume_screen.dart';
import 'resume_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ResumeService _resumeService = ResumeService();
  List<Resume> _allResumes = [];
  List<Resume> _filtered = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _sortBy = 'updated'; // 'updated' | 'name'

  static const _categories = ['All', 'Tech', 'Design', 'Marketing', 'Finance', 'Other'];

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
      success: (resumes) {
        _allResumes = resumes;
        _applyFilters();
      },
      failure: (msg) => messenger.showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
      ),
    );
    setState(() => _isLoading = false);
  }

  void _applyFilters() {
    var list = List<Resume>.from(_allResumes);

    // Category filter
    if (_selectedCategory != 'All') {
      list = list
          .where((r) =>
              r.category.toLowerCase() == _selectedCategory.toLowerCase())
          .toList();
    }

    // Search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((r) =>
              r.fullName.toLowerCase().contains(q) ||
              r.summary.toLowerCase().contains(q) ||
              r.skills.any((s) => s.toLowerCase().contains(q)))
          .toList();
    }

    // Sort
    if (_sortBy == 'name') {
      list.sort((a, b) => a.fullName.compareTo(b.fullName));
    } else {
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }

    setState(() => _filtered = list);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume Builder'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Colors.white),
            tooltip: 'Sort',
            onSelected: (v) {
              setState(() => _sortBy = v);
              _applyFilters();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'updated', child: Text('Last modified')),
              const PopupMenuItem(value: 'name', child: Text('Name')),
            ],
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.description, size: 48, color: Colors.white),
                  SizedBox(height: 8),
                  Text(
                    'Resume Builder',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('My Resumes'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Trash'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/trash').then((_) => _loadResumes());
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings');
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Search bar ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search resumes…',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) {
                _searchQuery = v;
                _applyFilters();
              },
            ),
          ),

          // ── Category filter chips ─────────────────────────────────────────
          SizedBox(
            height: 52,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              itemCount: _categories.length,
              itemBuilder: (context, i) {
                final cat = _categories[i];
                final selected = _selectedCategory == cat;
                final catColor = cat == 'All'
                    ? theme.colorScheme.primary
                    : AppColors.categoryColor(cat);
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: FilterChip(
                    label: Text(cat),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _selectedCategory = cat);
                      _applyFilters();
                    },
                    selectedColor: catColor.withAlpha(40),
                    checkmarkColor: catColor,
                    labelStyle: TextStyle(
                      color: selected ? catColor : null,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    side: selected
                        ? BorderSide(color: catColor)
                        : const BorderSide(color: Colors.transparent),
                  ),
                );
              },
            ),
          ),

          // ── List ──────────────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? _buildSkeleton()
                : _filtered.isEmpty
                    ? _buildEmptyState(context)
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final resume = _filtered[index];
                          return ResumeCard(
                            resume: resume,
                            score: ResumeScorer.score(resume),
                            onTap: () async {
                              final updated = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ResumeDetailScreen(resume: resume),
                                ),
                              );
                              if (updated == true) _loadResumes();
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
                builder: (context) => const CreateResumeScreen()),
          );
          if (created == true) _loadResumes();
        },
        icon: const Icon(Icons.add),
        label: const Text('New Resume'),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.surface,
      highlightColor:
          Theme.of(context).colorScheme.onSurface.withAlpha(15),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: 5,
        itemBuilder: (context, _) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined,
                size: 80,
                color: theme.colorScheme.onSurface.withAlpha(60)),
            const SizedBox(height: AppSpacing.md),
            Text(
              _searchQuery.isNotEmpty || _selectedCategory != 'All'
                  ? 'No resumes match your filter'
                  : 'No resumes yet',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _searchQuery.isNotEmpty || _selectedCategory != 'All'
                  ? 'Try adjusting the search or category filter.'
                  : 'Your resumes live here. Tap "New Resume" to create your first one — it only takes a few minutes.',
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
