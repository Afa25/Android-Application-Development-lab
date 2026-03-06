// ============================================================
//  GRADE MASTER  Reusable Widgets
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';


class SessionCard extends StatelessWidget {
  final GradeSession session;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final int index;

  const SessionCard({
    super.key,
    required this.session,
    required this.onTap,
    this.onDelete,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final avgGpa = session.sessionAverageGpa;
    final scale = session.defaultGpaScale.maxGpa;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      session.isLocked
                          ? Icons.lock_rounded
                          : Icons.folder_open_rounded,
                      color: AppTheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (session.academicYear != null ||
                            session.semester != null)
                          Text(
                            [
                              session.academicYear,
                              session.semester,
                            ].where((e) => e != null).join(' Ãƒâ€šÃ‚Â· '),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
                      onPressed: onDelete,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StatChip(
                    icon: Icons.people_rounded,
                    label: '${session.totalStudents} Students',
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    icon: Icons.school_rounded,
                    label:
                        'GPA ${avgGpa.toStringAsFixed(2)}/${scale.toStringAsFixed(0)}',
                    color: AppTheme.success,
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    icon: Icons.scale_rounded,
                    label: '${scale.toStringAsFixed(0)}.0',
                    color: AppTheme.accent,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _GpaProgressBar(gpa: avgGpa, maxGpa: scale),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: index * 60))
        .fadeIn()
        .slideX(begin: 0.05, end: 0);
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _GpaProgressBar extends StatelessWidget {
  final double gpa;
  final double maxGpa;

  const _GpaProgressBar({required this.gpa, required this.maxGpa});

  @override
  Widget build(BuildContext context) {
    final pct = maxGpa > 0 ? (gpa / maxGpa).clamp(0.0, 1.0) : 0.0;
    final color = pct >= 0.8
        ? AppTheme.success
        : pct >= 0.6
            ? AppTheme.warning
            : AppTheme.error;

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: pct,
        minHeight: 6,
        backgroundColor: Colors.grey[200],
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}


class StudentGradeCard extends StatelessWidget {
  final Student student;
  final int rank;
  final VoidCallback? onTap;

  const StudentGradeCard({
    super.key,
    required this.student,
    required this.rank,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final standing = student.standing;
    final standingColor = AppTheme.standingColor(standing.title);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Rank badge
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: rank <= 3
                      ? AppTheme.accentGold.withValues(alpha: 0.15)
                      : Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '#$rank',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: rank <= 3 ? AppTheme.accentGold : Colors.grey[600],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${student.studentId}  Ãƒâ€šÃ‚Â·  ${student.department ?? ""}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: standingColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        standing.title,
                        style: TextStyle(
                          fontSize: 10,
                          color: standingColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    student.gpa.toStringAsFixed(2),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  Text(
                    '${student.averagePercentage.toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 12,
                        color: AppTheme.success,
                      ),
                      Text(
                        ' ${student.passedSubjects}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.cancel, size: 12, color: AppTheme.error),
                      Text(
                        ' ${student.failedSubjects}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class GradeBadge extends StatelessWidget {
  final String letter;
  final double size;

  const GradeBadge({super.key, required this.letter, this.size = 36});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.gradeColor(letter);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(size * 0.25),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.38,
          ),
        ),
      ),
    );
  }
}


class SessionStatsBanner extends StatelessWidget {
  final GradeSession session;

  const SessionStatsBanner({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _BannerStat(
            value: session.totalStudents.toString(),
            label: 'Students',
          ),
          _divider(),
          _BannerStat(
            value: session.sessionAverageGpa.toStringAsFixed(2),
            label: 'Avg GPA',
          ),
          _divider(),
          _BannerStat(
            value: '${session.sessionAveragePercentage.toStringAsFixed(1)}%',
            label: 'Avg Score',
          ),
          _divider(),
          _BannerStat(
            value: session.defaultGpaScale.maxGpa.toStringAsFixed(0),
            label: 'Max GPA',
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        color: Colors.white.withValues(alpha: 0.3),
      );
}

class _BannerStat extends StatelessWidget {
  final String value;
  final String label;

  const _BannerStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}


class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 160, height: 14, color: Colors.grey[200]),
                    const SizedBox(height: 6),
                    Container(width: 100, height: 11, color: Colors.grey[200]),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 6,
              color: Colors.grey[200],
            ),
          ],
        ),
      ),
    );
  }
}


class GpaScaleSelector extends StatelessWidget {
  final GpaScale selected;
  final ValueChanged<GpaScale> onChanged;

  const GpaScaleSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'GPA Scale',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: GpaScale.values.map((scale) {
            final isSelected = scale == selected;
            return ChoiceChip(
              label: Text(scale.label),
              selected: isSelected,
              onSelected: (_) => onChanged(scale),
              selectedColor: AppTheme.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontSize: 12,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}


class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}
