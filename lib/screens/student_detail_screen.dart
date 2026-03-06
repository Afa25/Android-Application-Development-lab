// ============================================================
//  GRADE MASTER ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â Student Detail Screen
//  Shows full grade breakdown per student
// ============================================================

import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class StudentDetailScreen extends StatelessWidget {
  final Student student;
  final GradeSession session;

  const StudentDetailScreen({
    super.key,
    required this.student,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    final standing = student.standing;
    final standingColor = AppTheme.standingColor(standing.title);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        slivers: [
          //  Hero Header
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryDark, AppTheme.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.2),
                              child: Text(
                                student.name.isNotEmpty
                                    ? student.name.substring(0, 1).toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    student.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'ID: ${student.studentId}',
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.8),
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (student.department != null)
                                    Text(
                                      student.department!,
                                      style: TextStyle(
                                        color:
                                            Colors.white.withValues(alpha: 0.7),
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  student.gpa.toStringAsFixed(3),
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  '/ ${student.gpaScale.maxGpa.toStringAsFixed(1)} GPA',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: standingColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                standing.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                ' ${standing.latinHonor}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          //  Summary Stats Row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _StatCard(
                    label: 'Avg Score',
                    value: '${student.averagePercentage.toStringAsFixed(1)}%',
                    icon: Icons.percent_rounded,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    label: 'Subjects',
                    value: '${student.subjects.length}',
                    icon: Icons.book_rounded,
                    color: AppTheme.accent,
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    label: 'Credits',
                    value: '${student.totalCreditHours}',
                    icon: Icons.star_rounded,
                    color: AppTheme.accentGold,
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    label: 'Failed',
                    value: '${student.failedSubjects}',
                    icon: Icons.cancel_rounded,
                    color: AppTheme.error,
                  ),
                ],
              ),
            ),
          ),

          // Subjects Header
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Subject',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Score',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Grade',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'GPA',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'CR',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Subjects List
          SliverList(
            delegate: SliverChildBuilderDelegate((_, i) {
              final sub = student.subjects[i];
              final grade = sub.grade;
              final gradeColor = AppTheme.gradeColor(grade.letter);
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sub.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              sub.code,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            Text(
                              '${sub.percentage.toStringAsFixed(1)}%',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '${sub.score.toStringAsFixed(0)}/${sub.maxScore.toStringAsFixed(0)}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Center(
                          child: GradeBadge(letter: grade.letter, size: 32),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          grade
                              .gpaForScale(student.gpaScale)
                              .toStringAsFixed(1),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: gradeColor,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          '${sub.creditHours}cr',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }, childCount: student.subjects.length),
          ),

          // Remark Breakdown
          SliverToBoxAdapter(
            child: Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Grade Breakdown',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...{for (final s in student.subjects) s.grade.letter}.map((
                      letter,
                    ) {
                      final count = student.subjects
                          .where((s) => s.grade.letter == letter)
                          .length;
                      final color = AppTheme.gradeColor(letter);
                      final pct = count / student.subjects.length;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            GradeBadge(letter: letter, size: 28),
                            const SizedBox(width: 10),
                            Text(
                              '$count subject${count > 1 ? 's' : ''}',
                              style: const TextStyle(fontSize: 13),
                            ),
                            const Spacer(),
                            SizedBox(
                              width: 120,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  minHeight: 8,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation(color),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 30)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
