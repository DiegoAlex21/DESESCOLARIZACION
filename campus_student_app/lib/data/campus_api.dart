import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../models/student_portal.dart';

class CampusApi {
  CampusApi({http.Client? client}) : _client = client ?? http.Client();

  static const tokenStorageKey = 'campus_student_access_token';
  static const baseUrl = String.fromEnvironment(
    'CAMPUS_API_URL',
    defaultValue: 'http://192.168.10.15:8000',
  );

  final http.Client _client;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<StudentSession> login(String email, String password) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/v1/auth/login'),
      headers: const {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': email, 'password': password},
    );

    if (response.statusCode != 200) {
      throw Exception(_errorMessage(response));
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final user = body['user'] as Map<String, dynamic>;
    return StudentSession(
      token: body['access_token'] as String,
      email: user['email'] as String,
      fullName: user['full_name'] as String,
      role: user['role'] as String,
    );
  }

  Future<StudentSession> currentSession(String token) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/v1/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) throw Exception(_errorMessage(response));
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return StudentSession(
      token: token,
      email: body['email'] as String,
      fullName: body['full_name'] as String,
      role: body['role'] as String,
    );
  }

  Future<StudentPortal> fetchStudentPortal(String token) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/v1/student/portal'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception(_errorMessage(response));
    }

    return StudentPortal.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<SchoolStudent>> fetchStudents(String token) async {
    final body = await _getJson('/api/v1/students', token) as List<dynamic>;
    return body
        .map((item) => SchoolStudent.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> fetchDashboard(String token) async {
    return await _getJson('/api/v1/dashboard', token) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> fetchCourses(String token) async {
    final result = await _getJson('/api/v1/courses', token) as List<dynamic>;
    return result.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchTeachers(String token) async {
    final result =
        await _getJson('/api/v1/courses/teachers', token) as List<dynamic>;
    return result.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchMyCourses(String token) async {
    final result =
        await _getJson('/api/v1/courses/mine', token) as List<dynamic>;
    return result.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchCourseSchedule(
    String token,
    String grade,
  ) async {
    final result = await _getJson(
      '/api/v1/courses/$grade/schedule',
      token,
    ) as List<dynamic>;
    return result.cast<Map<String, dynamic>>();
  }

  Future<void> assignCourseTeacher(
    String token,
    String grade,
    String subject,
    String email,
  ) => _postJson('/api/v1/courses/$grade/assignments', token, {
    'subject': subject,
    'teacher_email': email,
  });

  Future<void> replaceCourseTeacher(
    String token,
    String grade,
    String subject,
    String email,
  ) => _putJson(
    '/api/v1/courses/$grade/assignments/${Uri.encodeComponent(subject)}',
    token,
    {'teacher_email': email},
  );

  Future<void> generateCourseSchedules(String token) =>
      _postJson('/api/v1/courses/schedule/generate', token, {});

  Future<void> publishCourseItem(
    String token,
    String grade,
    Map<String, dynamic> data,
  ) => _postJson('/api/v1/courses/$grade/items', token, data);

  Future<List<Map<String, dynamic>>> fetchStudentRecords(
    String token,
    String studentId,
    String recordType,
  ) async {
    final path = switch (recordType) {
      'attendance' => 'attendance',
      'grades' => 'grades',
      'observations' => 'observations',
      _ => throw ArgumentError.value(recordType, 'recordType'),
    };
    final body =
        await _getJson('/api/v1/$path/$studentId', token) as List<dynamic>;
    return body.cast<Map<String, dynamic>>();
  }

  Future<void> registerAttendance(String token, Map<String, dynamic> data) =>
      _postJson('/api/v1/attendance', token, data);

  Future<void> registerGrade(String token, Map<String, dynamic> data) =>
      _postJson('/api/v1/grades', token, data);

  Future<void> registerObservation(String token, Map<String, dynamic> data) =>
      _postJson('/api/v1/observations', token, data);

  Future<void> createStudent(String token, Map<String, dynamic> data) =>
      _postJson('/api/v1/students', token, data);

  Future<void> updateStudent(
    String token,
    String studentId,
    Map<String, dynamic> data,
  ) => _patchJson('/api/v1/students/$studentId', token, data);

  Future<void> deleteStudent(String token, String studentId) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/api/v1/students/$studentId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 204) throw Exception(_errorMessage(response));
  }

  Future<void> updateMyName(String token, String fullName) =>
      _patchJson('/api/v1/auth/me', token, {'full_name': fullName});

  Future<void> createAccount(String token, Map<String, dynamic> data) =>
      _postJson('/api/v1/accounts', token, data);

  Future<void> assignStudent(String token, String email, String studentId) =>
      _postJson('/api/v1/assignments', token, {
        'email': email,
        'student_id': studentId,
      });

  Future<void> saveToken(String token) =>
      _storage.write(key: tokenStorageKey, value: token);

  Future<String?> readToken() => _storage.read(key: tokenStorageKey);

  Future<void> clearToken() => _storage.delete(key: tokenStorageKey);

  Future<dynamic> _getJson(String path, String token) async {
    final response = await _client.get(
      Uri.parse('$baseUrl$path'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) throw Exception(_errorMessage(response));
    return jsonDecode(response.body);
  }

  Future<void> _postJson(
    String path,
    String token,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.post(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_errorMessage(response));
    }
  }

  Future<void> _patchJson(
    String path,
    String token,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.patch(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_errorMessage(response));
    }
  }

  Future<void> _putJson(
    String path,
    String token,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.put(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_errorMessage(response));
    }
  }

  String _errorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic> && body['detail'] is String) {
        return body['detail'] as String;
      }
    } on FormatException {
      return 'No se pudo interpretar la respuesta del servidor.';
    }
    if (response.statusCode == 401) {
      return 'Correo o contraseña incorrectos.';
    }
    return 'No se pudo conectar con Campus Connect (${response.statusCode}).';
  }
}
