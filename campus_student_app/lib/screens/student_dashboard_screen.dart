import 'package:flutter/material.dart';

import '../models/student_portal.dart';
import '../theme/app_theme.dart';
import 'student_detail_screens.dart';

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({
    super.key,
    required this.portal,
    required this.onLogout,
    required this.onRefresh,
  });

  final StudentPortal portal;
  final Future<void> Function() onLogout;
  final Future<void> Function() onRefresh;

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            _StudentBanner(portal: portal),
            const SizedBox(height: 25),
            const Text(
              'Menú Principal',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: CampusColors.text,
              ),
            ),
            const SizedBox(height: 13),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.98,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _MenuTile(
                  title: 'Horario',
                  icon: Icons.calendar_today_rounded,
                  color: CampusColors.orange,
                  onTap: () =>
                      _open(context, ScheduleScreen(schedule: portal.schedule)),
                ),
                _MenuTile(
                  title: 'Tareas',
                  icon: Icons.assignment_rounded,
                  color: CampusColors.green,
                  onTap: () => _open(context, TasksScreen(tasks: portal.tasks)),
                ),
                _MenuTile(
                  title: 'Eventos / Detalle',
                  icon: Icons.event_rounded,
                  color: CampusColors.purple,
                  onTap: () =>
                      _open(context, EventsScreen(events: portal.events)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentBanner extends StatelessWidget {
  const _StudentBanner({required this.portal});

  final StudentPortal portal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [CampusColors.indigo, CampusColors.blue],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            portal.dashboardDate,
            style: const TextStyle(color: Color(0xFFDCE4FF), fontSize: 13),
          ),
          const SizedBox(height: 14),
          Text(
            'Hola, ${portal.student.fullName}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Documento: ${portal.student.documentNumber} | Grado ${portal.student.grade}',
            style: const TextStyle(color: Color(0xFFE5EBFF), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.17),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 27),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: CampusColors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
