// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:campus_student_app/data/campus_api.dart';
import 'package:campus_student_app/models/student_portal.dart';
import 'package:campus_student_app/screens/course_management_screen.dart';
import 'package:campus_student_app/screens/login_screen.dart';
import 'package:campus_student_app/screens/name_edit_dialog.dart';
import 'package:campus_student_app/screens/role_dashboard_screen.dart';

void main() {
  testWidgets('student login screen is displayed', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(onLogin: (_, _) async {})),
    );

    expect(find.text('Campus Connect'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });

  testWidgets('name dialog safely saves after closing', (
    WidgetTester tester,
  ) async {
    String? savedName;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              savedName = await showDialog<String>(
                context: context,
                builder: (_) => const NameEditDialog(
                  title: 'Cambiar mi nombre',
                  initialName: 'Nombre anterior',
                ),
              );
            },
            child: const Text('Abrir'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Nombre nuevo');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(savedName, 'Nombre nuevo');
    expect(tester.takeException(), isNull);
  });

  testWidgets('selecting a demo role fills its credentials', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(onLogin: (_, _) async {})),
    );

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Docente').last);
    await tester.pumpAndSettle();

    final fields = tester
        .widgetList<TextFormField>(find.byType(TextFormField))
        .toList();
    expect(fields[0].controller?.text, 'teacher@campus.com');
    expect(fields[1].controller?.text, 'teacher123');
  });

  testWidgets('director account dialog fits long student names on mobile', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = CampusApi(
      client: MockClient((request) async {
        if (request.url.path == '/api/v1/students') {
          return http.Response(
            jsonEncode([
              {
                'student_id': 'stu-long-name',
                'full_name': 'Diego Alexander López Arevalo',
                'document_number': '1028481631',
                'grade': '11',
                'status': 'ACTIVE',
              },
            ]),
            200,
          );
        }
        return http.Response(
          jsonEncode({
            'total_students': 1,
            'attendance_records': 0,
            'grades_records': 0,
          }),
          200,
        );
      }),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: RoleDashboardScreen(
          session: const StudentSession(
            token: 'test-token',
            email: 'director@campus.com',
            fullName: 'Directivo Campus',
            role: 'DIRECTIVO',
          ),
          api: api,
          onLogout: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Crear cuenta docente o acudiente'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Diego Alexander López Arevalo').last);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('director assigns a course teacher from a list on mobile', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = CampusApi(
      client: MockClient((request) async {
        if (request.url.path == '/api/v1/courses') {
          return http.Response(
            jsonEncode([
              for (var grade = 6; grade <= 11; grade++)
                {
                  'grade': '$grade',
                  'subjects': ['Matemáticas'],
                  'assignments': [],
                  'students': [],
                },
            ]),
            200,
          );
        }
        if (request.url.path == '/api/v1/courses/teachers') {
          return http.Response(
            jsonEncode([
              {
                'id': 'teacher-id',
                'email': 'teacher@campus.com',
                'full_name': 'Docente Demo',
              },
            ]),
            200,
          );
        }
        if (request.url.path == '/api/v1/students') {
          return http.Response('[]', 200);
        }
        return http.Response('[]', 200);
      }),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CourseManagementScreen(api: api, token: 'test-token'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Elegir docente para Matemáticas'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Docente Demo').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Asignar').last);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
