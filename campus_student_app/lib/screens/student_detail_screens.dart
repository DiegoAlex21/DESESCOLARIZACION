import 'package:flutter/material.dart';

import '../models/student_portal.dart';
import '../theme/app_theme.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key, required this.schedule});

  final StudentSchedule schedule;

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late String _selectedDay = widget.schedule.selectedDay;

  @override
  Widget build(BuildContext context) {
    final dayClasses = widget.schedule.classes
        .where((item) => item.weekday == _selectedDay)
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Horario de Clases'),
        leading: const BackButton(),
      ),
      body: Column(
        children: [
          Material(
            color: CampusColors.indigo,
            child: Row(
              children: widget.schedule.days.map((day) {
                final selected = day == _selectedDay;
                return Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedDay = day),
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: selected ? Colors.white : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        day,
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : const Color(0xFFBBC5F1),
                          fontSize: 12,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: dayClasses.isNotEmpty
                ? ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
                    itemCount: dayClasses.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) =>
                        _ScheduleCard(item: dayClasses[index]),
                  )
                : Center(
                    child: Text(
                      widget.schedule.classes.isEmpty
                          ? 'El horario de este curso aún no está generado.'
                          : 'No hay clases publicadas para $_selectedDay.',
                      style: const TextStyle(
                        color: CampusColors.muted,
                        fontSize: 14,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.item});

  final ScheduleItem item;

  @override
  Widget build(BuildContext context) {
    final foreground = item.isBreak ? CampusColors.orange : CampusColors.indigo;
    return Material(
      color: item.isBreak ? const Color(0xFFFFE1B5) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Icon(
              item.isBreak ? Icons.restaurant : Icons.book_rounded,
              color: foreground,
              size: 21,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.subject,
                    style: TextStyle(
                      color: item.isBreak
                          ? CampusColors.orange
                          : CampusColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${item.start} - ${item.end}',
                    style: const TextStyle(
                      color: CampusColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key, required this.tasks});

  final List<StudentTask> tasks;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tareas Próxima Semana'),
        leading: const BackButton(),
      ),
      body: tasks.isEmpty
          ? const Center(
              child: Text(
                'No hay tareas asignadas para tu curso.',
                style: TextStyle(color: CampusColors.muted),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
              itemCount: tasks.length,
              separatorBuilder: (_, _) => const SizedBox(height: 9),
              itemBuilder: (context, index) => _TaskCard(task: tasks[index]),
            ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task});

  final StudentTask task;

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      leading: const Icon(
        Icons.check_circle_outline_rounded,
        color: CampusColors.green,
        size: 25,
      ),
      title: task.subject,
      lines: [
        task.title,
        task.description,
        'Entrega: ${_shortDate(task.dueDate)}',
      ],
    );
  }
}

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key, required this.events});

  final StudentEvents events;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventos y Exámenes'),
        leading: const BackButton(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0xFFF7EAF9),
              border: Border.all(color: CampusColors.purple),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: CampusColors.purple,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    events.notice,
                    style: const TextStyle(
                      color: CampusColors.purple,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (events.items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Text(
                'No hay eventos ni exámenes programados.',
                textAlign: TextAlign.center,
                style: TextStyle(color: CampusColors.muted),
              ),
            )
          else
            ...events.items.map(
              (event) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _DetailCard(
                  leading: const Icon(
                    Icons.event_note_rounded,
                    color: CampusColors.purple,
                    size: 28,
                  ),
                  title: event.subject,
                  lines: [
                    event.title,
                    event.description,
                    _longDate(event.date),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.leading,
    required this.title,
    required this.lines,
  });

  final Widget leading;
  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 12),
              child: leading,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: CampusColors.text,
                    ),
                  ),
                  const SizedBox(height: 3),
                  for (var index = 0; index < lines.length; index++) ...[
                    if (index > 0) const SizedBox(height: 3),
                    Text(
                      lines[index],
                      style: TextStyle(
                        color: index == lines.length - 1
                            ? CampusColors.muted
                            : const Color(0xFF55555D),
                        fontSize: index == lines.length - 1 ? 12 : 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _shortDate(DateTime date) => '${date.day} de ${_monthName(date.month)}';

String _longDate(DateTime date) =>
    '${_weekdayName(date.weekday)}, ${date.day} de ${_monthName(date.month)}, ${date.year}';

String _monthName(int month) => const [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
][month - 1];

String _weekdayName(int weekday) => const [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
][weekday - 1];
