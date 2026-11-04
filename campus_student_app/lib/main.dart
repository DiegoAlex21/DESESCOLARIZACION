import 'package:flutter/material.dart';

import 'data/campus_api.dart';
import 'models/student_portal.dart';
import 'screens/login_screen.dart';
import 'screens/role_dashboard_screen.dart';
import 'screens/student_dashboard_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CampusStudentApp());
}

class CampusStudentApp extends StatefulWidget {
  const CampusStudentApp({super.key});

  @override
  State<CampusStudentApp> createState() => _CampusStudentAppState();
}

class _CampusStudentAppState extends State<CampusStudentApp> {
  final CampusApi _api = CampusApi();
  StudentSession? _session;
  StudentPortal? _portal;
  bool _restoring = true;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final token = await _api.readToken();
    StudentSession? session;
    StudentPortal? portal;
    if (token != null) {
      try {
        session = await _api.currentSession(token);
        if (session.role == 'ESTUDIANTE') {
          portal = await _api.fetchStudentPortal(token);
        }
      } catch (_) {
        await _api.clearToken();
        session = null;
      }
    }
    if (!mounted) return;
    setState(() {
      _session = session;
      _portal = portal;
      _restoring = false;
    });
  }

  Future<void> _login(String email, String password) async {
    final session = await _api.login(email, password);
    const supportedRoles = {'ESTUDIANTE', 'DOCENTE', 'ACUDIENTE', 'DIRECTIVO'};
    if (!supportedRoles.contains(session.role)) {
      throw Exception('El perfil de esta cuenta no está habilitado en la app.');
    }
    final portal = session.role == 'ESTUDIANTE'
        ? await _api.fetchStudentPortal(session.token)
        : null;
    await _api.saveToken(session.token);
    if (!mounted) return;
    setState(() {
      _session = session;
      _portal = portal;
    });
  }

  Future<void> _refreshPortal() async {
    final token = _session?.token;
    if (token == null) return;
    final portal = await _api.fetchStudentPortal(token);
    if (!mounted) return;
    setState(() => _portal = portal);
  }

  Future<void> _logout() async {
    await _api.clearToken();
    if (!mounted) return;
    setState(() {
      _session = null;
      _portal = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Connect',
      debugShowCheckedModeBanner: false,
      theme: CampusTheme.light,
      home: _restoring
          ? const _SessionLoadingScreen()
          : _session == null
          ? LoginScreen(onLogin: _login)
          : _session!.role == 'ESTUDIANTE'
          ? StudentDashboardScreen(
              portal: _portal!,
              onLogout: _logout,
              onRefresh: _refreshPortal,
            )
          : RoleDashboardScreen(
              session: _session!,
              api: _api,
              onLogout: _logout,
            ),
    );
  }
}

class _SessionLoadingScreen extends StatelessWidget {
  const _SessionLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
