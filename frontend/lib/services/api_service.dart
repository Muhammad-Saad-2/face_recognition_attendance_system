import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';
import '../models/attendance_model.dart';

class ApiService {
  // static const String baseUrl = "http://localhost:8000"; // Local testing
  static const String baseUrl = "https://saad-muhammad-attendance-backend.hf.space"; // Production
  static String? _token;
  static Map<String, dynamic>? _currentUser;

  static void setToken(String token) {
    _token = token;
  }

  static bool get isSuperAdmin => _currentUser?['is_super_admin'] == true;
  static List<String> get permissions => List<String>.from(_currentUser?['permissions'] ?? []);
  static Map<String, dynamic>? get currentUser => _currentUser;

  static bool hasPermission(String permission) {
    if (isSuperAdmin) return true;
    return permissions.contains(permission);
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/login/access-token'),
      body: {
        'username': username,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _token = data['access_token'];
      _currentUser = data['user'];
      return data;
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> registerStudent({
    required String name,
    required String studentId,
    required String program,
    required String major,
    required String batch,
    int? departmentId,
    int currentSemester = 1,
    required List<XFile> images,
  }) async {
    var uri = Uri.parse('$baseUrl/api/v1/students/register');
    var request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_headers);

    request.fields['name'] = name;
    request.fields['student_id'] = studentId;
    request.fields['program'] = program;
    request.fields['major'] = major;
    request.fields['batch'] = batch;
    request.fields['current_semester'] = currentSemester.toString();
    if (departmentId != null) {
      request.fields['department_id'] = departmentId.toString();
    }

    for (var image in images) {
        final bytes = await image.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes('images', bytes, filename: image.name));
    }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to register: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> markAttendance(XFile image) async {
    var uri = Uri.parse('$baseUrl/api/v1/attendance/mark');
    var request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_headers);

    if (image.path.startsWith('http')) {
      final bytes = await image.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: 'image.jpg'));
    } else {
      request.files.add(await http.MultipartFile.fromPath('image', image.path));
    }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to mark attendance: ${response.body}');
    }
  }

  Future<List<Attendance>> getAllAttendanceReports() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/attendance/get_attendance_records'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      Iterable l = jsonDecode(response.body)['records'];
      return List<Attendance>.from(l.map((model) => Attendance.fromJson(model)));
    } else {
      throw Exception('Failed to load records: ${response.body}');
    }
  }


  // Management APIs (Faculties)

  Future<List<dynamic>> getFaculties() async {
    final response = await http.get(Uri.parse('$baseUrl/api/v1/faculties/'), headers: _headers);
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load faculties');
  }

  Future<Map<String, dynamic>> createFaculty(String name, String email, dynamic deptId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/faculties/'),
      headers: _headers,
      body: jsonEncode({'name': name, 'email': email, 'department_id': deptId}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to create faculty: ${response.body}');
  }

  Future<Map<String, dynamic>?> getFacultyByFacultyId(String facultyId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/faculties/?faculty_id=$facultyId'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      if (data.isNotEmpty) return data.first;
      return null;
    }
    throw Exception('Failed to search faculty: ${response.body}');
  }

  Future<List<dynamic>> getStudents() async {
    final response = await http.get(Uri.parse('$baseUrl/api/v1/students/'), headers: _headers);
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load students');
  }

  Future<Map<String, dynamic>> updateStudent(String studentId, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/v1/students/$studentId'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to update student: ${response.body}');
  }

  Future<void> deleteStudent(String studentId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/v1/students/$studentId'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete student: ${response.body}');
    }
  }

  // Attendance Management
  Future<Map<String, dynamic>> createAttendance(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/attendance/manual'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to create attendance: ${response.body}');
  }

  Future<Map<String, dynamic>> updateAttendance(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/v1/attendance/$id'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to update attendance: ${response.body}');
  }

  Future<void> deleteAttendance(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/v1/attendance/$id'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete attendance: ${response.body}');
    }
  }

  // Faculty Management
  Future<Map<String, dynamic>> updateFaculty(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/v1/faculties/$id'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to update faculty: ${response.body}');
  }

  Future<void> deleteFaculty(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/v1/faculties/$id'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete faculty: ${response.body}');
    }
  }

  // Academic Structure
  Future<List<dynamic>> getDepartments() async {
    final response = await http.get(Uri.parse('$baseUrl/api/v1/departments/'), headers: _headers);
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load departments');
  }

  Future<List<dynamic>> getPrograms() async {
    final response = await http.get(Uri.parse('$baseUrl/api/v1/programs/'), headers: _headers);
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load programs');
  }

  Future<List<dynamic>> getCourses() async {
    final response = await http.get(Uri.parse('$baseUrl/api/v1/courses/'), headers: _headers);
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load courses');
  }

  // Department Write Ops
  Future<void> createDepartment(Map<String, dynamic> data) async {
    final response = await http.post(Uri.parse('$baseUrl/api/v1/departments/'), headers: _headers, body: jsonEncode(data));
    if (response.statusCode != 200) throw Exception('Failed to create department: ${response.body}');
  }
  Future<void> updateDepartment(int id, Map<String, dynamic> data) async {
    final response = await http.put(Uri.parse('$baseUrl/api/v1/departments/$id'), headers: _headers, body: jsonEncode(data));
    if (response.statusCode != 200) throw Exception('Failed to update department: ${response.body}');
  }
  Future<void> deleteDepartment(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/api/v1/departments/$id'), headers: _headers);
    if (response.statusCode != 200) throw Exception('Failed to delete department: ${response.body}');
  }

  // Program Write Ops
  Future<void> createProgram(Map<String, dynamic> data) async {
    final response = await http.post(Uri.parse('$baseUrl/api/v1/programs/'), headers: _headers, body: jsonEncode(data));
    if (response.statusCode != 200) throw Exception('Failed to create program: ${response.body}');
  }
  Future<void> updateProgram(int id, Map<String, dynamic> data) async {
    final response = await http.put(Uri.parse('$baseUrl/api/v1/programs/$id'), headers: _headers, body: jsonEncode(data));
    if (response.statusCode != 200) throw Exception('Failed to update program: ${response.body}');
  }
  Future<void> deleteProgram(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/api/v1/programs/$id'), headers: _headers);
    if (response.statusCode != 200) throw Exception('Failed to delete program: ${response.body}');
  }

  // Course Write Ops
  Future<void> createCourse(Map<String, dynamic> data) async {
    final response = await http.post(Uri.parse('$baseUrl/api/v1/courses/'), headers: _headers, body: jsonEncode(data));
    if (response.statusCode != 200) throw Exception('Failed to create course: ${response.body}');
  }
  Future<void> updateCourse(int id, Map<String, dynamic> data) async {
    final response = await http.put(Uri.parse('$baseUrl/api/v1/courses/$id'), headers: _headers, body: jsonEncode(data));
    if (response.statusCode != 200) throw Exception('Failed to update course: ${response.body}');
  }
  Future<void> deleteCourse(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/api/v1/courses/$id'), headers: _headers);
    if (response.statusCode != 200) throw Exception('Failed to delete course: ${response.body}');
  }

  // Admin Management (Super Admin)
  Future<List<dynamic>> getAdmins() async {
    final response = await http.get(Uri.parse('$baseUrl/api/v1/users/'), headers: _headers);
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load admins: ${response.body}');
  }

  Future<void> createAdmin(Map<String, dynamic> data) async {
    final response = await http.post(Uri.parse('$baseUrl/api/v1/users/'), headers: _headers, body: jsonEncode(data));
    if (response.statusCode != 200) throw Exception('Failed to create admin: ${response.body}');
  }

  Future<void> updateAdmin(int id, Map<String, dynamic> data) async {
    final response = await http.put(Uri.parse('$baseUrl/api/v1/users/$id'), headers: _headers, body: jsonEncode(data));
    if (response.statusCode != 200) throw Exception('Failed to update admin: ${response.body}');
  }

  Future<void> deleteAdmin(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/api/v1/users/$id'), headers: _headers);
    if (response.statusCode != 200) throw Exception('Failed to delete admin: ${response.body}');
  }

  Future<Map<String, dynamic>> getAdminPermissions(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/api/v1/users/$id/permissions'), headers: _headers);
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load permissions: ${response.body}');
  }
}
