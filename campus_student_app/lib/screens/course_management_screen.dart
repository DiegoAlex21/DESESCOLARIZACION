import 'package:flutter/material.dart';

import '../data/campus_api.dart';
import '../models/student_portal.dart';
import '../theme/app_theme.dart';

class CourseManagementScreen extends StatefulWidget {
  const CourseManagementScreen({
    super.key,
    required this.api,
    required this.token,
  });

  final CampusApi api;
  final String token;

  @override
  State<CourseManagementScreen> createState() => _CourseManagementScreenState();
}

class _CourseManagementScreenState extends State<CourseManagementScreen> {
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _teachers = [];
  List<SchoolStudent> _allStudents = [];
  List<Map<String, dynamic>> _schedule = [];
  String _selectedGrade = '6';
  bool _loading = true;
  bool _busy = false;
  String? _error;

  Map<String, dynamic>? get _course {
    for (final course in _courses) {
      if (course['grade'] == _selectedGrade) return course;
    }
    return null;
  }

  List<Map<String, dynamic>> get _assignments =>
      ((_course?['assignments'] as List<dynamic>?) ?? const [])
          .cast<Map<String, dynamic>>();

  List<Map<String, dynamic>> get _students =>
      ((_course?['students'] as List<dynamic>?) ?? const [])
          .cast<Map<String, dynamic>>();

  List<String> get _subjects =>
      ((_course?['subjects'] as List<dynamic>?) ?? const []).cast<String>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        widget.api.fetchCourses(widget.token),
        widget.api.fetchTeachers(widget.token),
        widget.api.fetchStudents(widget.token),
      ]);
      if (!mounted) return;
      setState(() {
        _courses = results[0] as List<Map<String, dynamic>>;
        _teachers = results[1] as List<Map<String, dynamic>>;
        _allStudents = results[2] as List<SchoolStudent>;
        _error = null;
        _loading = false;
      });
      await _loadSchedule();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _loadSchedule() async {
    try {
      final schedule = await widget.api.fetchCourseSchedule(
        widget.token,
        _selectedGrade,
      );
      if (!mounted) return;
      setState(() => _schedule = schedule);
    } catch (_) {
      if (mounted) setState(() => _schedule = []);
    }
  }

  Future<void> _selectGrade(String? grade) async {
    if (grade == null) return;
    setState(() {
      _selectedGrade = grade;
      _schedule = [];
    });
    await _loadSchedule();
  }

  Future<void> _assignTeacher(String subject) async {
    final existing = _assignmentFor(subject);
    String? selectedEmail = existing?['teacher_email'] as String?;
    final email = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Docente de $subject'),
          content: DropdownButtonFormField<String>(
            initialValue: selectedEmail,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Seleccionar docente'),
            items: _teachers
                .map(
                  (teacher) => DropdownMenuItem(
                    value: teacher['email'] as String,
                    child: Text(
                      teacher['full_name'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) => setDialogState(() => selectedEmail = value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: selectedEmail == null
                  ? null
                  : () => Navigator.pop(context, selectedEmail),
              child: const Text('Asignar'),
            ),
          ],
        ),
      ),
    );
    if (email == null) return;
    setState(() => _busy = true);
    try {
      if (existing == null) {
        await widget.api.assignCourseTeacher(
          widget.token,
          _selectedGrade,
          subject,
          email,
        );
      } else {
        await widget.api.replaceCourseTeacher(
          widget.token,
          _selectedGrade,
          subject,
          email,
        );
      }
      await _load();
      _showMessage('Docente asignado a $subject. Genera de nuevo el horario.');
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _moveStudent() async {
    String? selectedStudentId;
    final studentId = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Agregar estudiante a $_selectedGrade.º'),
          content: DropdownButtonFormField<String>(
            initialValue: selectedStudentId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Seleccionar estudiante',
            ),
            items: _allStudents
                .map(
                  (student) => DropdownMenuItem(
                    value: student.id,
                    child: Text(
                      '${student.fullName} · ${student.grade}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) =>
                setDialogState(() => selectedStudentId = value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: selectedStudentId == null
                  ? null
                  : () => Navigator.pop(context, selectedStudentId),
              child: const Text('Asignar'),
            ),
          ],
        ),
      ),
    );
    if (studentId == null) return;
    setState(() => _busy = true);
    try {
      await widget.api.updateStudent(widget.token, studentId, {
        'grade': _selectedGrade,
      });
      await _load();
      _showMessage('Estudiante asignado a $_selectedGrade.º.');
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _generateSchedule() async {
    setState(() => _busy = true);
    try {
      await widget.api.generateCourseSchedules(widget.token);
      await _loadSchedule();
      _showMessage('Horario generado sin cruces de docente ni curso.');
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Map<String, dynamic>? _assignmentFor(String subject) {
    for (final assignment in _assignments) {
      if (assignment['subject'] == subject) return assignment;
    }
    return null;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cursos y horarios'),
        leading: const BackButton(),
        actions: [
          IconButton(
            tooltip: 'Generar horarios sin cruces',
            onPressed: _busy ? null : _generateSchedule,
            icon: const Icon(Icons.auto_awesome_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _selectedGrade,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Curso'),
                      items: _courses
                          .map(
                            (course) => DropdownMenuItem(
                              value: course['grade'] as String,
                              child: Text('${course['grade']}.º'),
                            ),
                          )
                          .toList(),
                      onChanged: _selectGrade,
                    ),
                    const SizedBox(height: 22),
                    _SectionHeader(
                      title: 'Materias y docentes',
                      action: IconButton(
                        tooltip: 'Asignar docente',
                        onPressed: _teachers.isEmpty
                            ? null
                            : () => _chooseSubject(),
                        icon: const Icon(Icons.person_add_alt_1_rounded),
                      ),
                    ),
                    ..._subjects.map(_subjectTile),
                    const SizedBox(height: 20),
                    _SectionHeader(
                      title: 'Estudiantes (${_students.length})',
                      action: IconButton(
                        tooltip: 'Elegir estudiante para este curso',
                        onPressed: _allStudents.isEmpty ? null : _moveStudent,
                        icon: const Icon(Icons.group_add_rounded),
                      ),
                    ),
                    if (_students.isEmpty)
                      const _EmptyCourseMessage(
                        message: 'No hay estudiantes en este grado.',
                      )
                    else
                      ..._students.map(
                        (student) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.person_outline_rounded),
                          title: Text(student['full_name'] as String),
                          subtitle: Text(
                            'Documento ${student['document_number']}',
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    const _SectionHeader(title: 'Horario semanal'),
                    if (_schedule.isEmpty)
                      const _EmptyCourseMessage(
                        message: 'Asigna docentes y genera el horario para este curso.',
                      )
                    else
                      ..._schedule.map(
                        (entry) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Text(
                            '${entry['start']}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          title: Text('${entry['day']} · ${entry['subject']}'),
                          subtitle: Text(
                            '${entry['start']}–${entry['end']} · ${entry['teacher_name']}',
                          ),
                        ),
                      ),
                  ],
                ),
                if (_busy)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Color(0x33FFFFFF),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _subjectTile(String subject) {
    final assignment = _assignmentFor(subject);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(subject),
      subtitle: Text(
        assignment?['teacher_name'] as String? ?? 'Sin docente asignado',
      ),
      trailing: IconButton(
        tooltip: 'Elegir docente para $subject',
        onPressed: _busy || _teachers.isEmpty
            ? null
            : () => _assignTeacher(subject),
        icon: Icon(
          assignment == null
              ? Icons.person_add_alt_1_rounded
              : Icons.edit_outlined,
          color: CampusColors.indigo,
        ),
      ),
    );
  }

  Future<void> _chooseSubject() async {
    String? selectedSubject;
    final subject = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Materia de $_selectedGrade.º'),
          content: DropdownButtonFormField<String>(
            initialValue: selectedSubject,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Materia'),
            items: _subjects
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (value) => setDialogState(() => selectedSubject = value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: selectedSubject == null
                  ? null
                  : () => Navigator.pop(context, selectedSubject),
              child: const Text('Continuar'),
            ),
          ],
        ),
      ),
    );
    if (subject != null) await _assignTeacher(subject);
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      ?action,
    ],
  );
}

class _EmptyCourseMessage extends StatelessWidget {
  const _EmptyCourseMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(message, style: const TextStyle(color: CampusColors.muted)),
  );
}
