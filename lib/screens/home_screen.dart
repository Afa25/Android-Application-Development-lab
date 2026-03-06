// ============================================================
//  GRADE MASTER ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â Home Screen (Sessions Dashboard)
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/session_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'session_detail_screen.dart';
import 'create_session_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(vsync: this, duration: 300.ms);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SessionProvider>().loadSessions();
    });
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        slivers: [
          
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.primary,
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
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 60),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.school_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Grade Master',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              title: const Text(
                'Grade Master',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              titlePadding: const EdgeInsetsDirectional.fromSTEB(16, 0, 0, 16),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.info_outline_rounded,
                  color: Colors.white,
                ),
                onPressed: () => _showGradeTableInfo(context),
              ),
            ],
          ),

          // Quick Stats Banner (if sessions exist)
          Consumer<SessionProvider>(
            builder: (_, provider, __) {
              if (provider.sessions.isEmpty) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
              final totalSessions = provider.sessions.length;
              final totalStudents = provider.sessions.fold<int>(
                0,
                (sum, s) => sum + s.totalStudents,
              );
              return SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
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
                        color: AppTheme.primary.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _QuickStat(
                        value: '$totalSessions',
                        label: 'Sessions',
                        icon: Icons.folder_rounded,
                      ),
                      _vDivider(),
                      _QuickStat(
                        value: '$totalStudents',
                        label: 'Students',
                        icon: Icons.people_rounded,
                      ),
                      _vDivider(),
                      const _QuickStat(
                        value: '4',
                        label: 'GPA Scales',
                        icon: Icons.tune_rounded,
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: -0.1, end: 0),
              );
            },
          ),

          //  Section Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Past Sessions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Consumer<SessionProvider>(
                    builder: (_, p, __) => Text(
                      '${p.sessions.length} total',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),

          //  Sessions List
          Consumer<SessionProvider>(
            builder: (_, provider, __) {
              if (provider.isLoading) {
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => const ShimmerCard(),
                    childCount: 4,
                  ),
                );
              }

              if (provider.sessions.isEmpty) {
                return SliverToBoxAdapter(
                  child: EmptyState(
                    icon: Icons.folder_open_rounded,
                    title: 'No Sessions Yet',
                    subtitle:
                        'Create your first session to start\nimporting and calculating grades.',
                    action: ElevatedButton.icon(
                      onPressed: () => _openCreateSession(context),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('New Session'),
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate((ctx, i) {
                  final session = provider.sessions[i];
                  return SessionCard(
                    session: session,
                    index: i,
                    onTap: () => _openSession(context, session),
                    onDelete: () => _confirmDelete(context, session),
                  );
                }, childCount: provider.sessions.length),
              );
            },
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),

      //  New Session
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateSession(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'New Session',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 6,
      ).animate().scale(
            delay: 300.ms,
            duration: 400.ms,
            curve: Curves.elasticOut,
          ),
    );
  }

  void _openCreateSession(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateSessionScreen()),
    );
  }

  void _openSession(BuildContext context, GradeSession session) {
    context.read<SessionProvider>().openSession(session);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SessionDetailScreen(session: session)),
    );
  }

  void _confirmDelete(BuildContext context, GradeSession session) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Session'),
        content: Text(
          'Are you sure you want to delete "${session.name}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<SessionProvider>().deleteSession(session.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showGradeTableInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, ctrl) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Grade Reference Table',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: ctrl,
                itemCount: GradeTable.standard.length,
                itemBuilder: (_, i) {
                  final g = GradeTable.standard[i];
                  return ListTile(
                    leading: GradeBadge(letter: g.letter),
                    title: Text(
                      '${g.minPercent.toInt()}% ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“ ${g.maxPercent.toInt()}%',
                    ),
                    subtitle: Text(g.remark),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        Chip(
                          label: Text('4.0: ${g.gpaPoint4}'),
                          padding: EdgeInsets.zero,
                          labelStyle: const TextStyle(fontSize: 10),
                        ),
                        Chip(
                          label: Text('5.0: ${g.gpaPoint5}'),
                          padding: EdgeInsets.zero,
                          labelStyle: const TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vDivider() => Container(
      width: 1, height: 35, color: Colors.white.withValues(alpha: 0.3));
}

class _QuickStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _QuickStat({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
              fontSize: 11, color: Colors.white.withValues(alpha: 0.8)),
        ),
      ],
    );
  }
}
