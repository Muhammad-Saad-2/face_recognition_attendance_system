import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';
import '../models/attendance_model.dart';

class ApiService {
  static const String baseUrl = "https://saad-muhammad-attendance-backend.hf.space"; 
  static String? _token;

  static void setToken(String token) {
    _token = token;
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
    required List<XFile> images,
  }) async {
    var uri = Uri.parse('$baseUrl/api/v1/students/register');
    var request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_headers);

    request.fields['name'] = name;
    request.fields['student_id'] = studentId;
    request.fields['program'] = program;
    request.fields['major'] = major;

    for (var image in images) {
      if (image.path.startsWith('http')) {
        // Handle web images if needed
        final bytes = await image.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes('images', bytes, filename: 'image.jpg'));
      } else {
        request.files.add(await http.MultipartFile.fromPath('images', image.path));
      }
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

  Future<List<Attendance>> getDailyReport() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/reports/daily'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      Iterable l = jsonDecode(response.body);
      return List<Attendance>.from(l.map((model) => Attendance.fromJson(model)));
    } else {
      throw Exception('Failed to load report');
    }
  }
}
