// ============================================================
//  GRADE MASTER ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â Create Session Screen
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/session_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'session_detail_screen.dart';

class CreateSessionScreen extends StatefulWidget {
  const CreateSessionScreen({super.key});

  @override
  State<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends State<CreateSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _institutionCtrl = TextEditingController();
  final _semesterCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  GpaScale _selectedScale = GpaScale.scale4;
  bool _creating = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _institutionCtrl.dispose();
    _semesterCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('New Session'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Session Info Card
            _SectionCard(
              title: 'Session Information',
              icon: Icons.info_outline_rounded,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Session Name *',
                    hintText: 'e.g. Fall 2024 Midterm',
                    prefixIcon: Icon(Icons.folder_rounded),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _institutionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Institution (optional)',
                    hintText: 'University / School name',
                    prefixIcon: Icon(Icons.account_balance_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _semesterCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Semester',
                          hintText: 'e.g. Semester 1',
                          prefixIcon: Icon(Icons.calendar_month_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _yearCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Academic Year',
                          hintText: 'e.g. 2024/2025',
                          prefixIcon: Icon(Icons.event_rounded),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    prefixIcon: Icon(Icons.notes_rounded),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // GPA Scale Card
            _SectionCard(
              title: 'Grading Configuration',
              icon: Icons.tune_rounded,
              children: [
                GpaScaleSelector(
                  selected: _selectedScale,
                  onChanged: (s) => setState(() => _selectedScale = s),
                ),
                const SizedBox(height: 12),
                _ScalePreviewTable(scale: _selectedScale),
              ],
            ),
            const SizedBox(height: 16),

            // Academic Standing Reference
            _SectionCard(
              title: 'Academic Standing Reference',
              icon: Icons.emoji_events_rounded,
              children: [
                ...AcademicStanding.standings.map(
                  (s) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
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
                          s.latinHonor,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          ' ${s.minGpa4.toStringAsFixed(1)} / 4.0',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Create Button
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _creating ? null : _createSession,
                icon: _creating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.rocket_launch_rounded),
                label: Text(
                  _creating ? 'Creating...' : 'Create Session',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _createSession() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _creating = true);
    try {
      final session = await context.read<SessionProvider>().createSession(
            name: _nameCtrl.text.trim(),
            description:
                _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
            institution: _institutionCtrl.text.trim().isEmpty
                ? null
                : _institutionCtrl.text.trim(),
            semester: _semesterCtrl.text.trim().isEmpty
                ? null
                : _semesterCtrl.text.trim(),
            academicYear:
                _yearCtrl.text.trim().isEmpty ? null : _yearCtrl.text.trim(),
            gpaScale: _selectedScale,
          );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SessionDetailScreen(session: session),
        ),
      );
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }
}

// ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ Helper Widgets

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ScalePreviewTable extends StatelessWidget {
  final GpaScale scale;

  const _ScalePreviewTable({required this.scale});

  @override
  Widget build(BuildContext context) {
    const grades = GradeTable.standard;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GPA Preview (${scale.label})',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Expanded(
                flex: 1,
                child: Text(
                  'Grade',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '% Range',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'Points',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Remark',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const Divider(height: 10),
          ...grades.take(8).map(
                (g) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: GradeBadge(letter: g.letter, size: 24),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${g.minPercent.toInt()}“${g.maxPercent.toInt()}%',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          g.gpaForScale(scale).toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          g.remark,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
