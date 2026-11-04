class StudentSession {
  const StudentSession({
    required this.token,
    required this.email,
    required this.fullName,
    required this.role,
  });

  final String token;
  final String email;
  final String fullName;
  final String role;
}

class SchoolStudent {
  const SchoolStudent({
    required this.id,
    required this.fullName,
    required this.documentNumber,
    required this.grade,
    required this.status,
  });

  final String id;
  final String fullName;
  final String documentNumber;
  final String grade;
  final String status;

  factory SchoolStudent.fromJson(Map<String, dynamic> json) {
    return SchoolStudent(
      id: json['student_id'] as String,
      fullName: json['full_name'] as String,
      documentNumber: json['document_number'] as String,
      grade: (json['grade'] as String?) ?? '',
      status: json['status'] as String,
    );
  }
}

class StudentPortal {
  const StudentPortal({
    required this.student,
    required this.dashboardDate,
    required this.schedule,
    required this.tasks,
    required this.events,
  });

  final StudentProfile student;
  final String dashboardDate;
  final StudentSchedule schedule;
  final List<StudentTask> tasks;
  final StudentEvents events;

  factory StudentPortal.fromJson(Map<String, dynamic> json) {
    return StudentPortal(
      student: StudentProfile.fromJson(json['student'] as Map<String, dynamic>),
      dashboardDate:
          (json['dashboard'] as Map<String, dynamic>)['date'] as String,
      schedule: StudentSchedule.fromJson(
        json['schedule'] as Map<String, dynamic>,
      ),
      tasks: (json['tasks'] as List<dynamic>)
          .map((item) => StudentTask.fromJson(item as Map<String, dynamic>))
          .toList(),
      events: StudentEvents.fromJson(json['events'] as Map<String, dynamic>),
    );
  }
}

class StudentProfile {
  const StudentProfile({
    required this.id,
    required this.fullName,
    required this.documentNumber,
    required this.grade,
  });

  final String id;
  final String fullName;
  final String documentNumber;
  final String grade;

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      documentNumber: json['document_number'] as String,
      grade: json['grade'] as String,
    );
  }
}

class StudentSchedule {
  const StudentSchedule({
    required this.days,
    required this.selectedDay,
    required this.classes,
  });

  final List<String> days;
  final String selectedDay;
  final List<ScheduleItem> classes;

  factory StudentSchedule.fromJson(Map<String, dynamic> json) {
    return StudentSchedule(
      days: (json['days'] as List<dynamic>).cast<String>(),
      selectedDay: json['selected_day'] as String,
      classes: (json['classes'] as List<dynamic>)
          .map((item) => ScheduleItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ScheduleItem {
  const ScheduleItem({
    required this.subject,
    required this.start,
    required this.end,
    required this.isBreak,
    required this.weekday,
  });

  final String subject;
  final String start;
  final String end;
  final bool isBreak;
  final String weekday;

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      subject: json['subject'] as String,
      start: json['start'] as String,
      end: json['end'] as String,
      isBreak: json['kind'] == 'break',
      weekday: json['weekday'] as String? ?? '',
    );
  }
}

class StudentTask {
  const StudentTask({
    required this.subject,
    required this.title,
    required this.description,
    required this.dueDate,
  });

  final String subject;
  final String title;
  final String description;
  final DateTime dueDate;

  factory StudentTask.fromJson(Map<String, dynamic> json) {
    return StudentTask(
      subject: json['subject'] as String,
      title: json['title'] as String? ?? 'Tarea',
      description: json['description'] as String,
      dueDate: DateTime.parse(json['due_date'] as String),
    );
  }
}

class StudentEvents {
  const StudentEvents({required this.notice, required this.items});

  final String notice;
  final List<StudentEvent> items;

  factory StudentEvents.fromJson(Map<String, dynamic> json) {
    return StudentEvents(
      notice: json['notice'] as String,
      items: (json['items'] as List<dynamic>)
          .map((item) => StudentEvent.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class StudentEvent {
  const StudentEvent({
    required this.subject,
    required this.title,
    required this.description,
    required this.date,
  });

  final String subject;
  final String title;
  final String description;
  final DateTime date;

  factory StudentEvent.fromJson(Map<String, dynamic> json) {
    return StudentEvent(
      subject: json['subject'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String,
      date: DateTime.parse(json['date'] as String),
    );
  }
}
