// ============================================================
//  GRADE MASTER  Session Detail Screen
//  Shows students, stats, and import/export actions
// ============================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';
import '../providers/session_provider.dart';
import '../services/excel_import_service.dart';
import '../services/export_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'student_detail_screen.dart';

enum _ImportMode { singleFile, multipleFiles }

class SessionDetailScreen extends StatefulWidget {
  final GradeSession session;

  const SessionDetailScreen({super.key, required this.session});

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _searchQuery = '';
  String _sortBy = 'rank'; // rank, name, gpa
  final bool _ascending = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  GradeSession get session =>
      context.read<SessionProvider>().currentSession ?? widget.session;

  List<Student> get _filteredStudents {
    final students = List<Student>.from(session.students);
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      students.retainWhere(
        (s) =>
            s.name.toLowerCase().contains(q) ||
            s.studentId.toLowerCase().contains(q) ||
            (s.department?.toLowerCase().contains(q) ?? false),
      );
    }
    switch (_sortBy) {
      case 'name':
        students.sort(
          (a, b) =>
              _ascending ? a.name.compareTo(b.name) : b.name.compareTo(a.name),
        );
      case 'gpa':
        students.sort(
          (a, b) =>
              _ascending ? a.gpa.compareTo(b.gpa) : b.gpa.compareTo(a.gpa),
        );
      default: // rank = by GPA descending
        students.sort((a, b) => b.gpa.compareTo(a.gpa));
    }
    return students;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionProvider>(
      builder: (_, provider, __) {
        final sess = provider.currentSession ?? widget.session;
        return Scaffold(
          backgroundColor: AppTheme.surface,
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sess.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (sess.academicYear != null)
                  Text(
                    sess.academicYear!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
              ],
            ),
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            actions: [
              // Lock toggle
              IconButton(
                icon: Icon(
                  sess.isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                ),
                onPressed: () => provider.toggleSessionLock(),
                tooltip: sess.isLocked ? 'Locked' : 'Unlocked',
              ),
              // Export
              PopupMenuButton<String>(
                icon: const Icon(Icons.ios_share_rounded),
                onSelected: (v) => _handleExport(v, sess),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'excel',
                    child: ListTile(
                      leading: Icon(Icons.table_chart_rounded),
                      title: Text('Export as Excel'),
                      dense: true,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'pdf',
                    child: ListTile(
                      leading: Icon(Icons.picture_as_pdf_rounded),
                      title: Text('Export as PDF'),
                      dense: true,
                    ),
                  ),
                ],
              ),
              // GPA Scale changer
              IconButton(
                icon: const Icon(Icons.tune_rounded),
                onPressed: () => _showScaleDialog(context, provider, sess),
              ),
            ],
            bottom: TabBar(
              controller: _tabCtrl,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: const [
                Tab(
                  icon: Icon(Icons.people_rounded, size: 18),
                  text: 'Students',
                ),
                Tab(
                  icon: Icon(Icons.bar_chart_rounded, size: 18),
                  text: 'Analytics',
                ),
                Tab(icon: Icon(Icons.info_rounded, size: 18), text: 'Info'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabCtrl,
            children: [
              _StudentsTab(
                session: sess,
                filteredStudents: _filteredStudents,
                searchQuery: _searchQuery,
                sortBy: _sortBy,
                ascending: _ascending,
                onSearch: (q) => setState(() => _searchQuery = q),
                onSortChanged: (s) => setState(() => _sortBy = s),
                onStudentTap: (student) => _openStudent(student),
                isLocked: sess.isLocked,
              ),
              _AnalyticsTab(session: sess),
              _InfoTab(session: sess),
            ],
          ),
          floatingActionButton: sess.isLocked
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => _showImportOptions(context, sess),
                  icon: const Icon(Icons.upload_file_rounded),
                  label: const Text(
                    'Import',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: AppTheme.primary,
                ).animate().scale(duration: 300.ms, curve: Curves.elasticOut),
        );
      },
    );
  }

  void _openStudent(Student student) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentDetailScreen(student: student, session: session),
      ),
    );
  }

  void _showImportOptions(BuildContext context, GradeSession sess) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Import Student Data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Session: ${sess.name}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            _ImportOptionTile(
              icon: Icons.upload_file_rounded,
              color: AppTheme.success,
              title: 'Browse Excel File',
              subtitle: 'Select a .xlsx file from your device',
              onTap: () {
                Navigator.pop(context);
                _startExcelImport(sess);
              },
            ),
            const SizedBox(height: 12),
            _ImportOptionTile(
              icon: Icons.qr_code_scanner_rounded,
              color: AppTheme.accent,
              title: 'Scan Document',
              subtitle: 'Use camera to scan a grade sheet (QR/barcode)',
              onTap: () {
                Navigator.pop(context);
                _scanDocument();
              },
            ),
            const SizedBox(height: 12),
            _ImportOptionTile(
              icon: Icons.download_rounded,
              color: AppTheme.primaryLight,
              title: 'Download Template',
              subtitle: 'Get the Excel template for this session',
              onTap: () {
                Navigator.pop(context);
                _downloadTemplate(sess);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _startExcelImport(GradeSession sess) async {
    final mode = await _askImportMode();
    if (!mounted || mode == null) return;
    if (mode == _ImportMode.singleFile) {
      await _importSingleFile(sess);
      return;
    }
    await _importMultipleFiles(sess);
  }

  Future<_ImportMode?> _askImportMode() {
    return showDialog<_ImportMode>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('How are your marks arranged?'),
        content: const Text(
          'Choose one option:\n\n1) One file contains all subjects.\n2) Different files, each file contains one subject.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, _ImportMode.multipleFiles),
            child: const Text('Different Files'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, _ImportMode.singleFile),
            child: const Text('One File'),
          ),
        ],
      ),
    );
  }

  Future<void> _importSingleFile(GradeSession sess) async {
    final importSvc = ExcelImportService.instance;
    _showBlockingDialog('Select an Excel file...');
    try {
      final file = await importSvc.pickExcelFile();
      if (!mounted) return;
      Navigator.pop(context);
      if (file == null) return;
      await _processImport(file, sess);
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showFriendlyError(
        title: 'Could not open file picker',
        message:
            'The app could not open your file browser. Please try again and allow file access if asked.',
        details: '$e',
      );
    }
  }

  Future<void> _importMultipleFiles(GradeSession sess) async {
    final importSvc = ExcelImportService.instance;
    _showBlockingDialog('Select subject files...');
    try {
      final files = await importSvc.pickExcelFiles();
      if (!mounted) return;
      Navigator.pop(context);
      if (files.isEmpty) return;

      _showBlockingDialog('Reading selected files...');
      final warnings = <String>[];
      final importedGroups = <List<Student>>[];
      final failedFiles = <String>[];
      for (final file in files) {
        final result = await importSvc.parseExcelFile(
          file,
          sess.defaultGpaScale,
          mapping: const ExcelMapping(),
        );
        if (result.hasErrors) {
          failedFiles.add(
            '${result.fileName ?? file.path}: ${result.errors.first}',
          );
          continue;
        }
        warnings.addAll(result.warnings);
        importedGroups.add(result.students);
      }
      if (!mounted) return;
      Navigator.pop(context);

      final mergedStudents = _mergeStudentsAcrossFiles(
        importedGroups,
        sess.defaultGpaScale,
      );
      if (mergedStudents.isEmpty) {
        _showFriendlyError(
          title: 'No student data found',
          message:
              'We could not find valid student marks in the selected files. Please check that each file has student names and at least one subject score column.',
          details: failedFiles.join('\n'),
        );
        return;
      }

      final preview = ExcelImportResult(
        students: mergedStudents,
        warnings: [
          'Imported from ${files.length} file(s).',
          if (failedFiles.isNotEmpty)
            '${failedFiles.length} file(s) were skipped due to format issues.',
          ...warnings,
        ],
        fileName: '${files.length} files',
      );
      _showImportPreview(preview, sess);
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showFriendlyError(
        title: 'Could not import multiple files',
        message:
            'Something went wrong while reading your files. Please make sure all selected files are Excel files and try again.',
        details: '$e',
      );
    }
  }
  Future<void> _processImport(File file, GradeSession sess) async {
    _showBlockingDialog('Reading your file...');
    final result = await ExcelImportService.instance.parseExcelFile(
      file,
      sess.defaultGpaScale,
      mapping: const ExcelMapping(),
    );

    if (!mounted) return;
    Navigator.pop(context);

    if (result.hasErrors) {
      _showFriendlyError(
        title: 'Could not import this file',
        message: result.errors.first,
        details: result.warnings.isEmpty ? null : result.warnings.join('\n'),
      );
      return;
    }

    _showImportPreview(result, sess);
  }

  void _showImportPreview(ExcelImportResult result, GradeSession sess) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Import ${result.students.length} Students?'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'File: ${result.fileName}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 10),
              if (result.hasWarnings) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        ' Warnings:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      ...result.warnings.take(5).map(
                            (w) => Text(
                              ' $w',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: result.students.take(10).length,
                  itemBuilder: (_, i) {
                    final s = result.students[i];
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 14,
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      title: Text(s.name, style: const TextStyle(fontSize: 13)),
                      subtitle: Text(
                        '${s.studentId} ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â· ${s.subjects.length} subjects ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â· empty fields: ${s.emptyFieldsCount}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: Text(
                        'GPA: ${s.gpa.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (result.students.length > 10)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '... and ${result.students.length - 10} more',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(_),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(_);
              await context.read<SessionProvider>().addStudentsToSession(
                    result.students,
                  );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ' Imported ${result.students.length} students',
                    ),
                    backgroundColor: AppTheme.success,
                  ),
                );
              }
            },
            icon: const Icon(Icons.check_rounded),
            label: const Text('Confirm Import'),
          ),
        ],
      ),
    );
  }

  void _showBlockingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  List<Student> _mergeStudentsAcrossFiles(
    List<List<Student>> importedGroups,
    GpaScale scale,
  ) {
    final merged = <String, Student>{};
    for (final group in importedGroups) {
      for (final incoming in group) {
        final key = _studentKey(incoming);
        final existing = merged[key];
        if (existing == null) {
          merged[key] = _cloneStudent(incoming, scale);
          continue;
        }

        final subjectMap = <String, Subject>{};
        for (final s in existing.subjects) {
          subjectMap['${s.code.toLowerCase()}|${s.name.toLowerCase()}'] = s;
        }
        for (final s in incoming.subjects) {
          subjectMap['${s.code.toLowerCase()}|${s.name.toLowerCase()}'] =
              _cloneSubject(s);
        }

        merged[key] = Student(
          id: existing.id,
          name: existing.name,
          studentId: existing.studentId,
          department: existing.department ?? incoming.department,
          level: existing.level ?? incoming.level,
          subjects: subjectMap.values.toList(),
          gpaScale: scale,
          emptyFieldsCount: existing.emptyFieldsCount + incoming.emptyFieldsCount,
        );
      }
    }
    return merged.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  String _studentKey(Student s) {
    final id = s.studentId.trim().toLowerCase();
    if (id.isNotEmpty) return 'id:$id';
    return 'name:${s.name.trim().toLowerCase()}';
  }

  Student _cloneStudent(Student s, GpaScale scale) {
    return Student(
      id: s.id,
      name: s.name,
      studentId: s.studentId,
      department: s.department,
      level: s.level,
      subjects: s.subjects.map(_cloneSubject).toList(),
      gpaScale: scale,
      emptyFieldsCount: s.emptyFieldsCount,
    );
  }

  Subject _cloneSubject(Subject s) {
    return Subject(
      id: s.id,
      name: s.name,
      code: s.code,
      creditHours: s.creditHours,
      score: s.score,
      maxScore: s.maxScore,
    );
  }

  void _scanDocument() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          ' Camera scanner  navigate to scan screen',
        ),
        backgroundColor: AppTheme.accent,
      ),
    );
    // TODO: Navigate to ScanScreen when camera is available
  }

  Future<void> _downloadTemplate(GradeSession sess) async {
    final bytes = ExcelImportService.instance.generateTemplate(
      subjectColumns: [
        'MATH101|Mathematics|3',
        'ENG101|English|3',
        'PHY101|Physics|3',
      ],
    );
    // Save and share
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/GradeMaster_Template.xlsx');
    await file.writeAsBytes(bytes);
    ExportService.instance.shareFile(file);
  }

  Future<void> _handleExport(String format, GradeSession sess) async {
    if (sess.students.isEmpty) {
      _showFriendlyError(
        title: 'Nothing to export',
        message:
            'There are no students in this session yet. Please import student data first.',
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text('Generating ${format.toUpperCase()}...'),
          ],
        ),
      ),
    );

    try {
      File? file;
      if (format == 'excel') {
        file = await ExportService.instance.exportToExcel(sess);
      } else {
        file = await ExportService.instance.exportToPdf(sess);
      }

      if (!mounted) return;
      Navigator.pop(context);

      if (file == null) {
        _showFriendlyError(
          title: 'Export did not complete',
          message:
              'We could not create the export file. Please try again and make sure your device has free storage space.',
        );
        return;
      }
      await ExportService.instance.shareFile(file);
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showFriendlyError(
        title: 'Export failed',
        message: 'Something went wrong while generating the export file.',
        details: '$e',
      );
    }
  }

  void _showScaleDialog(
    BuildContext context,
    SessionProvider provider,
    GradeSession sess,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Change GPA Scale'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This will recalculate all student GPAs',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            RadioGroup<GpaScale>(
              groupValue: sess.defaultGpaScale,
              onChanged: (v) {
                if (v == null) return;
                provider.applyGpaScaleToAll(v);
                Navigator.pop(_);
              },
              child: Column(
                children: GpaScale.values
                    .map(
                      (scale) => RadioListTile<GpaScale>(
                        title: Text(scale.label),
                        value: scale,
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFriendlyError({
    required String title,
    required String message,
    String? details,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (details != null && details.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Details: $details',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              'What to check:\n- File format should be .xlsx/.xls\n- Header row should contain student information\n- Subject score columns should contain numbers',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}


//  Students Tab

class _StudentsTab extends StatelessWidget {
  final GradeSession session;
  final List<Student> filteredStudents;
  final String searchQuery;
  final String sortBy;
  final bool ascending;
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onSortChanged;
  final ValueChanged<Student> onStudentTap;
  final bool isLocked;

  const _StudentsTab({
    required this.session,
    required this.filteredStudents,
    required this.searchQuery,
    required this.sortBy,
    required this.ascending,
    required this.onSearch,
    required this.onSortChanged,
    required this.onStudentTap,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SessionStatsBanner(session: session),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: onSearch,
                  decoration: InputDecoration(
                    hintText: 'Search students...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () => onSearch(''),
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.sort_rounded, color: AppTheme.primary),
                onSelected: onSortChanged,
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'rank',
                    child: Text('Sort by Rank'),
                  ),
                  const PopupMenuItem(
                    value: 'name',
                    child: Text('Sort by Name'),
                  ),
                  const PopupMenuItem(value: 'gpa', child: Text('Sort by GPA')),
                ],
              ),
            ],
          ),
        ),
        if (session.students.isEmpty)
          Expanded(
            child: EmptyState(
              icon: Icons.person_add_rounded,
              title: 'No Students Yet',
              subtitle: isLocked
                  ? 'This session is locked. Unlock to import data.'
                  : 'Tap the Import button to load\nstudents from an Excel file.',
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: filteredStudents.length,
              padding: const EdgeInsets.only(bottom: 100),
              itemBuilder: (_, i) => StudentGradeCard(
                student: filteredStudents[i],
                rank: i + 1,
                onTap: () => onStudentTap(filteredStudents[i]),
              ),
            ),
          ),
      ],
    );
  }
}


//  Analytics Tab

class _AnalyticsTab extends StatelessWidget {
  final GradeSession session;

  const _AnalyticsTab({required this.session});

  @override
  Widget build(BuildContext context) {
    if (session.students.isEmpty) {
      return const EmptyState(
        icon: Icons.bar_chart_rounded,
        title: 'No Data Yet',
        subtitle: 'Import students to see analytics',
      );
    }

    final dist = session.standingDistribution;
    final topStudents = session.students.toList()
      ..sort((a, b) => b.gpa.compareTo(a.gpa));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Top performers
        const Text(
          'Top Performers',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...topStudents
            .take(3)
            .toList()
            .asMap()
            .entries
            .map((e) => StudentGradeCard(student: e.value, rank: e.key + 1)),

        const SizedBox(height: 20),
        const Text(
          '  Standing Distribution',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: dist.entries.map((e) {
                final pct = e.value / session.totalStudents;
                final color = AppTheme.standingColor(e.key);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            e.key,
                            style: TextStyle(
                              fontSize: 13,
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${e.value} (${(pct * 100).toStringAsFixed(1)}%)',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 8,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        const SizedBox(height: 20),
        const Text(
          ' Subject Pass Rates',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildSubjectStats(),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Empty Fields Per Student',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: session.students
                  .map(
                    (s) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              s.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            s.emptyFieldsCount.toString(),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectStats() {
    final subjectMap = <String, List<Subject>>{};
    for (final student in session.students) {
      for (final sub in student.subjects) {
        subjectMap.putIfAbsent(sub.name, () => []).add(sub);
      }
    }

    if (subjectMap.isEmpty) return const Text('No subject data');

    return Column(
      children: subjectMap.entries.map((entry) {
        final subs = entry.value;
        final avg =
            subs.map((s) => s.percentage).reduce((a, b) => a + b) / subs.length;
        final passed = subs.where((s) => s.grade.letter != 'F').length;
        final passRate = passed / subs.length;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry.key,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Avg: ${avg.toStringAsFixed(1)}%  Pass: ${(passRate * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: passRate,
                  minHeight: 6,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(
                    passRate >= 0.8
                        ? AppTheme.success
                        : passRate >= 0.6
                            ? AppTheme.warning
                            : AppTheme.error,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}


//  Info Tab

class _InfoTab extends StatelessWidget {
  final GradeSession session;

  const _InfoTab({required this.session});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Session Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                _InfoRow(label: 'Name', value: session.name),
                _InfoRow(
                  label: 'Institution',
                  value: session.institution ?? 'N/A',
                ),
                _InfoRow(label: 'Semester', value: session.semester ?? 'N/A'),
                _InfoRow(
                  label: 'Academic Year',
                  value: session.academicYear ?? 'N/A',
                ),
                _InfoRow(
                  label: 'GPA Scale',
                  value: session.defaultGpaScale.label,
                ),
                _InfoRow(
                  label: 'Status',
                  value: session.isLocked
                      ? ' Locked'
                      : ' Active',
                ),
                _InfoRow(
                  label: 'Created',
                  value: session.createdAt.toString().split('.').first,
                ),
                _InfoRow(
                  label: 'Updated',
                  value: session.updatedAt.toString().split('.').first,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Grade Scale Reference',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                ...AcademicStanding.standings.map(
                  (s) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Color(s.color),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            s.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          ' ${s.minGpa4} / 4.0',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImportOptionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ImportOptionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
          color: color.withValues(alpha: 0.05),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}


