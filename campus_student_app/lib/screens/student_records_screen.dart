import 'package:flutter/material.dart';

import '../data/campus_api.dart';
import '../models/student_portal.dart';
import '../theme/app_theme.dart';
import 'name_edit_dialog.dart';

class StudentRecordsScreen extends StatefulWidget {
  const StudentRecordsScreen({
    super.key,
    required this.student,
    required this.session,
    required this.api,
  });

  final SchoolStudent student;
  final StudentSession session;
  final CampusApi api;

  @override
  State<StudentRecordsScreen> createState() => _StudentRecordsScreenState();
}

class _StudentRecordsScreenState extends State<StudentRecordsScreen> {
  List<Map<String, dynamic>> _attendance = [];
  List<Map<String, dynamic>> _grades = [];
  List<Map<String, dynamic>> _observations = [];
  late SchoolStudent _student;
  bool _loading = true;
  String? _error;

  bool get _canWrite => widget.session.role == 'DOCENTE';
  bool get _isDirector => widget.session.role == 'DIRECTIVO';

  @override
  void initState() {
    super.initState();
    _student = widget.student;
    _load();
  }

  Future<void> _load() async {
    try {
      final records = await Future.wait([
        widget.api.fetchStudentRecords(
          widget.session.token,
          _student.id,
          'attendance',
        ),
        widget.api.fetchStudentRecords(
          widget.session.token,
          _student.id,
          'grades',
        ),
        widget.api.fetchStudentRecords(
          widget.session.token,
          _student.id,
          'observations',
        ),
      ]);
      if (!mounted) return;
      setState(() {
        _attendance = records[0];
        _grades = records[1];
        _observations = records[2];
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

  Future<void> _addRecord() async {
    final type = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(
                Icons.fact_check_outlined,
                color: CampusColors.green,
              ),
              title: const Text('Registrar asistencia'),
              onTap: () => Navigator.pop(context, 'attendance'),
            ),
            ListTile(
              leading: const Icon(
                Icons.grade_outlined,
                color: CampusColors.indigo,
              ),
              title: const Text('Registrar nota'),
              onTap: () => Navigator.pop(context, 'grades'),
            ),
            ListTile(
              leading: const Icon(
                Icons.notes_rounded,
                color: CampusColors.purple,
              ),
              title: const Text('Agregar observación'),
              onTap: () => Navigator.pop(context, 'observations'),
            ),
          ],
        ),
      ),
    );
    if (type == null || !mounted) return;

    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _RecordEntryDialog(type: type, studentId: _student.id),
    );
    if (data == null || !mounted) return;

    try {
      switch (type) {
        case 'attendance':
          await widget.api.registerAttendance(widget.session.token, data);
        case 'grades':
          await widget.api.registerGrade(widget.session.token, data);
        case 'observations':
          await widget.api.registerObservation(widget.session.token, data);
      }
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _editStudentName() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => NameEditDialog(
        title: 'Cambiar nombre del estudiante',
        initialName: _student.fullName,
      ),
    );
    if (name == null || name.isEmpty) return;
    try {
      await widget.api.updateStudent(widget.session.token, _student.id, {
        'full_name': name,
      });
      if (!mounted) return;
      setState(() {
        _student = SchoolStudent(
          id: _student.id,
          fullName: name,
          documentNumber: _student.documentNumber,
          grade: _student.grade,
          status: _student.status,
        );
      });
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _deleteStudent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar estudiante'),
        content: Text(
          'Se eliminarán la ficha, su cuenta y sus registros. ¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.api.deleteStudent(widget.session.token, _student.id);
      if (mounted) Navigator.pop(context, true);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ficha del estudiante'),
        leading: const BackButton(),
        actions: [
          if (_isDirector)
            IconButton(
              tooltip: 'Cambiar nombre',
              onPressed: _editStudentName,
              icon: const Icon(Icons.edit_outlined),
            ),
          if (_isDirector)
            IconButton(
              tooltip: 'Eliminar estudiante',
              onPressed: _deleteStudent,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      floatingActionButton: _canWrite
          ? FloatingActionButton.extended(
              onPressed: _addRecord,
              backgroundColor: CampusColors.indigo,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Registrar'),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
                children: [
                  _StudentHeader(student: _student),
                  const SizedBox(height: 16),
                  _RecordSection(
                    title: 'Asistencia',
                    icon: Icons.fact_check_outlined,
                    records: _attendance,
                    titleFor: (record) => (record['present'] as bool? ?? false)
                        ? 'Presente'
                        : 'Ausente',
                    detailsFor: (record) => [
                      'Fecha: ${record['attendance_date'] ?? '-'}',
                      if ((record['justification'] as String?)?.isNotEmpty ??
                          false)
                        record['justification'] as String,
                    ],
                  ),
                  _RecordSection(
                    title: 'Notas',
                    icon: Icons.grade_outlined,
                    records: _grades,
                    titleFor: (record) =>
                        record['subject'] as String? ?? 'Asignatura',
                    detailsFor: (record) => [
                      'Periodo: ${record['period'] ?? '-'}',
                      'Calificación: ${record['value'] ?? '-'}',
                    ],
                  ),
                  _RecordSection(
                    title: 'Observaciones',
                    icon: Icons.notes_rounded,
                    records: _observations,
                    titleFor: (record) =>
                        record['category'] as String? ?? 'Observación',
                    detailsFor: (record) => [
                      record['description'] as String? ?? '',
                      'Severidad: ${record['severity'] ?? 'MEDIUM'}',
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class _StudentHeader extends StatelessWidget {
  const _StudentHeader({required this.student});

  final SchoolStudent student;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            student.fullName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Documento ${student.documentNumber} · Grado ${student.grade}',
            style: const TextStyle(color: CampusColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _RecordSection extends StatelessWidget {
  const _RecordSection({
    required this.title,
    required this.icon,
    required this.records,
    required this.titleFor,
    required this.detailsFor,
  });

  final String title;
  final IconData icon;
  final List<Map<String, dynamic>> records;
  final String Function(Map<String, dynamic>) titleFor;
  final List<String> Function(Map<String, dynamic>) detailsFor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: CampusColors.indigo),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (records.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Sin registros',
                style: TextStyle(color: CampusColors.muted, fontSize: 13),
              ),
            )
          else
            ...records.map(
              (record) => Card(
                color: Colors.white,
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  dense: true,
                  title: Text(
                    titleFor(record),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    detailsFor(record)
                        .where((line) => line.isNotEmpty)
                        .join('\n'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RecordEntryDialog extends StatefulWidget {
  const _RecordEntryDialog({required this.type, required this.studentId});

  final String type;
  final String studentId;

  @override
  State<_RecordEntryDialog> createState() => _RecordEntryDialogState();
}

class _RecordEntryDialogState extends State<_RecordEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _period = TextEditingController(text: 'Corte 1');
  final _value = TextEditingController();
  final _description = TextEditingController();
  final _justification = TextEditingController();
  bool _present = true;
  String _category = 'Académica';
  String _severity = 'MEDIUM';

  @override
  void dispose() {
    _subject.dispose();
    _period.dispose();
    _value.dispose();
    _description.dispose();
    _justification.dispose();
    super.dispose();
  }

  String get _title => switch (widget.type) {
    'attendance' => 'Registrar asistencia',
    'grades' => 'Registrar nota',
    _ => 'Agregar observación',
  };

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final Map<String, dynamic> data;
    switch (widget.type) {
      case 'attendance':
        data = {
          'student_id': widget.studentId,
          'attendance_date': DateTime.now().toIso8601String().substring(0, 10),
          'present': _present,
          'justification': _justification.text.trim().isEmpty
              ? null
              : _justification.text.trim(),
        };
      case 'grades':
        data = {
          'student_id': widget.studentId,
          'subject': _subject.text.trim(),
          'period': _period.text.trim(),
          'value': double.parse(_value.text.trim()),
        };
      default:
        data = {
          'student_id': widget.studentId,
          'category': _category,
          'description': _description.text.trim(),
          'severity': _severity,
        };
    }
    Navigator.pop(context, data);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_title),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.type == 'attendance') ...[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_present ? 'Presente' : 'Ausente'),
                  value: _present,
                  onChanged: (value) => setState(() => _present = value),
                ),
                TextFormField(
                  controller: _justification,
                  decoration: const InputDecoration(
                    labelText: 'Justificación (opcional)',
                  ),
                ),
              ] else if (widget.type == 'grades') ...[
                _requiredField(_subject, 'Asignatura'),
                _requiredField(_period, 'Periodo'),
                TextFormField(
                  controller: _value,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Nota (0 a 5)'),
                  validator: (value) {
                    final number = double.tryParse(value ?? '');
                    if (number == null || number < 0 || number > 5) {
                      return 'Ingresa una nota entre 0 y 5';
                    }
                    return null;
                  },
                ),
              ] else ...[
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  items:
                      const [
                            'Convivencial',
                            'Académica',
                            'Familiar/Entorno',
                            'Grave',
                          ]
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                  onChanged: (value) =>
                      setState(() => _category = value ?? _category),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _severity,
                  decoration: const InputDecoration(labelText: 'Severidad'),
                  items: const ['LOW', 'MEDIUM', 'HIGH']
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _severity = value ?? _severity),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _description,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Campo obligatorio'
                      : null,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Guardar')),
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
