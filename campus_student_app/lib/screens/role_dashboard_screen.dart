import 'package:flutter/material.dart';

import '../data/campus_api.dart';
import '../models/student_portal.dart';
import '../theme/app_theme.dart';
import 'course_management_screen.dart';
import 'name_edit_dialog.dart';
import 'student_records_screen.dart';

class RoleDashboardScreen extends StatefulWidget {
  const RoleDashboardScreen({
    super.key,
    required this.session,
    required this.api,
    required this.onLogout,
  });

  final StudentSession session;
  final CampusApi api;
  final Future<void> Function() onLogout;

  @override
  State<RoleDashboardScreen> createState() => _RoleDashboardScreenState();
}

class _RoleDashboardScreenState extends State<RoleDashboardScreen> {
  List<SchoolStudent> _students = [];
  List<Map<String, dynamic>> _myCourses = [];
  Map<String, dynamic> _metrics = {};
  String? _error;
  bool _loading = true;
  late String _displayName = widget.session.fullName;

  String get _roleLabel => switch (widget.session.role) {
    'DOCENTE' => 'Docente',
    'ACUDIENTE' => 'Acudiente',
    'DIRECTIVO' => 'Directivo',
    _ => 'Campus Connect',
  };

  String get _studentHeading => switch (widget.session.role) {
    'DOCENTE' => 'Mis estudiantes',
    'ACUDIENTE' => 'Mis hijos',
    _ => 'Estudiantes',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final students = await widget.api.fetchStudents(widget.session.token);
      final metrics = await widget.api.fetchDashboard(widget.session.token);
      final courses = widget.session.role == 'DOCENTE'
          ? await widget.api.fetchMyCourses(widget.session.token)
          : <Map<String, dynamic>>[];
      if (!mounted) return;
      setState(() {
        _students = students;
        _metrics = metrics;
        _myCourses = courses;
        _error = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _openStudent(SchoolStudent student) async {
    final deleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => StudentRecordsScreen(
          student: student,
          session: widget.session,
          api: widget.api,
        ),
      ),
    );
    if (deleted == true) await _load();
  }

  Future<void> _createStudent() async {
    await showDialog<void>(
      context: context,
      builder: (_) => _StudentCreateDialog(
        api: widget.api,
        token: widget.session.token,
        onCreated: _load,
      ),
    );
  }

  Future<void> _assignAccount() async {
    await showDialog<void>(
      context: context,
      builder: (_) => _AssignStudentDialog(
        api: widget.api,
        token: widget.session.token,
        onAssigned: _load,
      ),
    );
  }

  Future<void> _createAccount() async {
    await showDialog<void>(
      context: context,
      builder: (_) => _AccountCreateDialog(
        api: widget.api,
        token: widget.session.token,
        students: _students,
        onCreated: _load,
      ),
    );
  }

  Future<void> _openCourseManagement() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CourseManagementScreen(
          api: widget.api,
          token: widget.session.token,
        ),
      ),
    );
    await _load();
  }

  Future<void> _editMyName() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) =>
          NameEditDialog(title: 'Cambiar mi nombre', initialName: _displayName),
    );
    if (name == null || name.isEmpty) return;
    try {
      await widget.api.updateMyName(widget.session.token, name);
      if (mounted) setState(() => _displayName = name);
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _createCourseItem(
    Map<String, dynamic> course,
    String itemType,
  ) async {
    final item = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _CourseItemDialog(
        subject: course['subject'] as String,
        itemType: itemType,
      ),
    );
    if (item == null) return;
    try {
      await widget.api.publishCourseItem(
        widget.session.token,
        course['grade'] as String,
        {...item, 'item_type': itemType, 'subject': course['subject']},
      );
      _showMessage(
        itemType == 'TASK' ? 'Tarea publicada.' : 'Evento publicado.',
      );
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isDirector = widget.session.role == 'DIRECTIVO';
    return Scaffold(
      appBar: AppBar(
        title: Text(_roleLabel),
        actions: [
          if (isDirector)
            IconButton(
              tooltip: 'Cursos y horarios',
              onPressed: _openCourseManagement,
              icon: const Icon(Icons.calendar_view_week_rounded),
            ),
          if (isDirector)
            IconButton(
              tooltip: 'Asignar alumno a docente o acudiente',
              onPressed: _assignAccount,
              icon: const Icon(Icons.link_rounded),
            ),
          if (isDirector)
            IconButton(
              tooltip: 'Crear cuenta docente o acudiente',
              onPressed: _createAccount,
              icon: const Icon(Icons.person_add_alt_1_rounded),
            ),
          IconButton(
            tooltip: 'Cambiar mi nombre',
            onPressed: _editMyName,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      floatingActionButton: isDirector
          ? FloatingActionButton.extended(
              onPressed: _createStudent,
              backgroundColor: CampusColors.indigo,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Nuevo estudiante'),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _ErrorState(message: _error!, onRetry: _load)
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
                children: [
                  _RoleBanner(name: _displayName, role: _roleLabel),
                  const SizedBox(height: 18),
                  _MetricsRow(metrics: _metrics),
                  if (widget.session.role == 'DOCENTE') ...[
                    const SizedBox(height: 22),
                    const Text(
                      'Mis cursos y materias',
                      style: TextStyle(
                        color: CampusColors.text,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_myCourses.isEmpty)
                      const _EmptyState(
                        message:
                            'Aún no tienes materias asignadas a tus cursos.',
                      )
                    else
                      ..._myCourses.map(
                        (course) => _TeacherCourseTile(
                          course: course,
                          onTask: () => _createCourseItem(course, 'TASK'),
                          onEvent: () => _createCourseItem(course, 'EVENT'),
                        ),
                      ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    _studentHeading,
                    style: const TextStyle(
                      color: CampusColors.text,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_students.isEmpty)
                    const _EmptyState(
                      message: 'No tienes estudiantes vinculados todavía.',
                    )
                  else
                    ..._students.map(
                      (student) => Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: _StudentTile(
                          student: student,
                          onTap: () => _openStudent(student),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _RoleBanner extends StatelessWidget {
  const _RoleBanner({required this.name, required this.role});

  final String name;
  final String role;

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
            role,
            style: const TextStyle(color: Color(0xFFDCE4FF), fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            'Hola, $name',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({required this.metrics});

  final Map<String, dynamic> metrics;

  @override
  Widget build(BuildContext context) {
    final values = [
      ('Estudiantes', metrics['total_students'] ?? 0, CampusColors.indigo),
      ('Asistencias', metrics['attendance_records'] ?? 0, CampusColors.green),
      ('Notas', metrics['grades_records'] ?? 0, CampusColors.purple),
    ];
    return Row(
      children: values
          .map(
            (item) => Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      '${item.$2}',
                      style: TextStyle(
                        color: item.$3,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.$1,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: CampusColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _StudentTile extends StatelessWidget {
  const _StudentTile({required this.student, required this.onTap});

  final SchoolStudent student;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(11),
      child: ListTile(
        onTap: onTap,
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE7EBFF),
          child: Icon(Icons.person_rounded, color: CampusColors.indigo),
        ),
        title: Text(
          student.fullName,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          'Grado ${student.grade} · ${student.documentNumber}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _TeacherCourseTile extends StatelessWidget {
  const _TeacherCourseTile({
    required this.course,
    required this.onTask,
    required this.onEvent,
  });

  final Map<String, dynamic> course;
  final VoidCallback onTask;
  final VoidCallback onEvent;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        title: Text(course['subject'] as String),
        subtitle: Text('Curso ${course['grade']}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Publicar tarea',
              onPressed: onTask,
              icon: const Icon(Icons.assignment_add, color: CampusColors.green),
            ),
            IconButton(
              tooltip: 'Publicar evento o examen',
              onPressed: onEvent,
              icon: const Icon(
                Icons.event_available,
                color: CampusColors.purple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseItemDialog extends StatefulWidget {
  const _CourseItemDialog({required this.subject, required this.itemType});

  final String subject;
  final String itemType;

  @override
  State<_CourseItemDialog> createState() => _CourseItemDialogState();
}

class _CourseItemDialogState extends State<_CourseItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(days: 7));

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (selected != null) setState(() => _date = selected);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'title': _title.text.trim(),
      'description': _description.text.trim(),
      'date': _date.toIso8601String().substring(0, 10),
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTask = widget.itemType == 'TASK';
    return AlertDialog(
      title: Text(isTask ? 'Nueva tarea' : 'Nuevo evento o examen'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text('${widget.subject} · curso asignado'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _title,
                decoration: InputDecoration(
                  labelText: isTask ? 'Título de tarea' : 'Nombre del evento',
                ),
                validator: _requiredValue,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _description,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Detalle'),
                validator: _requiredValue,
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_rounded),
                title: Text(isTask ? 'Fecha de entrega' : 'Fecha del evento'),
                subtitle: Text('${_date.day}/${_date.month}/${_date.year}'),
                onTap: _selectDate,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Publicar')),
      ],
    );
  }

  String? _requiredValue(String? value) =>
      value == null || value.trim().isEmpty ? 'Campo obligatorio' : null;
}

class _StudentCreateDialog extends StatefulWidget {
  const _StudentCreateDialog({
    required this.api,
    required this.token,
    required this.onCreated,
  });

  final CampusApi api;
  final String token;
  final Future<void> Function() onCreated;

  @override
  State<_StudentCreateDialog> createState() => _StudentCreateDialogState();
}

class _StudentCreateDialogState extends State<_StudentCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _id = TextEditingController();
  final _name = TextEditingController();
  final _document = TextEditingController();
  final _accountEmail = TextEditingController();
  final _accountPassword = TextEditingController();
  String _grade = '6';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _id.dispose();
    _name.dispose();
    _document.dispose();
    _accountEmail.dispose();
    _accountPassword.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.api.createStudent(widget.token, {
        'student_id': _id.text.trim(),
        'full_name': _name.text.trim(),
        'document_number': _document.text.trim(),
        'grade': _grade,
        'account_email': _accountEmail.text.trim(),
        'account_password': _accountPassword.text,
      });
      if (!mounted) return;
      Navigator.pop(context);
      await widget.onCreated();
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo estudiante'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(_id, 'Código de estudiante'),
              _field(_name, 'Nombre completo'),
              _field(_document, 'Documento'),
              DropdownButtonFormField<String>(
                initialValue: _grade,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Curso'),
                items: [
                  for (var grade = 6; grade <= 11; grade++)
                    DropdownMenuItem(
                      value: '$grade',
                      child: Text('$grade.º grado'),
                    ),
                ],
                onChanged: (grade) => setState(() => _grade = grade ?? _grade),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _accountEmail,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo de acceso',
                ),
                validator: (value) => value == null || !value.contains('@')
                    ? 'Ingresa un correo válido'
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _accountPassword,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña inicial',
                ),
                validator: (value) => value == null || value.length < 8
                    ? 'Usa al menos 8 caracteres'
                    : null,
              ),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Guardando...' : 'Crear'),
        ),
      ],
    );
  }

  Widget _field(TextEditingController controller, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      validator: (value) =>
          value == null || value.trim().isEmpty ? 'Campo obligatorio' : null,
    ),
  );
}

class _AssignStudentDialog extends StatefulWidget {
  const _AssignStudentDialog({
    required this.api,
    required this.token,
    required this.onAssigned,
  });

  final CampusApi api;
  final String token;
  final Future<void> Function() onAssigned;

  @override
  State<_AssignStudentDialog> createState() => _AssignStudentDialogState();
}

class _AssignStudentDialogState extends State<_AssignStudentDialog> {
  final _email = TextEditingController(text: 'teacher@campus.com');
  final _studentId = TextEditingController(text: 'stu-diego-001');
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _studentId.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.api.assignStudent(
        widget.token,
        _email.text.trim(),
        _studentId.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context);
      await widget.onAssigned();
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Asignar estudiante'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _email,
            decoration: const InputDecoration(
              labelText: 'Correo docente/acudiente',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _studentId,
            decoration: const InputDecoration(
              labelText: 'Código de estudiante',
            ),
          ),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.red)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Guardando...' : 'Asignar'),
        ),
      ],
    );
  }
}

class _AccountCreateDialog extends StatefulWidget {
  const _AccountCreateDialog({
    required this.api,
    required this.token,
    required this.students,
    required this.onCreated,
  });

  final CampusApi api;
  final String token;
  final List<SchoolStudent> students;
  final Future<void> Function() onCreated;

  @override
  State<_AccountCreateDialog> createState() => _AccountCreateDialogState();
}

class _AccountCreateDialogState extends State<_AccountCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String _role = 'DOCENTE';
  String? _studentId;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.api.createAccount(widget.token, {
        'full_name': _name.text.trim(),
        'email': _email.text.trim(),
        'password': _password.text,
        'role': _role,
        'student_id': _studentId,
      });
      if (!mounted) return;
      Navigator.pop(context);
      await widget.onCreated();
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Crear cuenta'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _role,
                decoration: const InputDecoration(labelText: 'Perfil'),
                items: const [
                  DropdownMenuItem(value: 'DOCENTE', child: Text('Docente')),
                  DropdownMenuItem(
                    value: 'ACUDIENTE',
                    child: Text('Acudiente'),
                  ),
                ],
                onChanged: (value) => setState(() => _role = value ?? _role),
              ),
              const SizedBox(height: 10),
              _requiredField(_name, 'Nombre completo'),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo de acceso',
                ),
                validator: (value) => value == null || !value.contains('@')
                    ? 'Ingresa un correo válido'
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña inicial',
                ),
                validator: (value) => value == null || value.length < 8
                    ? 'Usa al menos 8 caracteres'
                    : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String?>(
                initialValue: _studentId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Vincular estudiante (opcional)',
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Sin asignar'),
                  ),
                  ...widget.students.map(
                    (student) => DropdownMenuItem<String?>(
                      value: student.id,
                      child: Text(
                        student.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _studentId = value),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Guardando...' : 'Crear cuenta'),
        ),
      ],
    );
  }

  Widget _requiredField(TextEditingController controller, String label) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(labelText: label),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Campo obligatorio'
              : null,
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: CampusColors.muted),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: CampusColors.muted),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
