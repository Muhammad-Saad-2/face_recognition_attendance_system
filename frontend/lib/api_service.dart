import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';

class ApiService {
  // Use 10.0.2.2 for Android emulator to access localhost of the host machine
  // Use localhost or 127.0.0.1 for iOS simulator or web
  // For physical device, use your machine's local IP address (e.g., 192.168.1.x)
  static const String baseUrl = 'https://saad-muhammad-test-on-new-branch.hf.space'; 

  Future<Map<String, dynamic>> registerStudent({
    required String name,
    required String studentId,
    required String program,
    required String major,
    required List<XFile> images,
  }) async {
    var uri = Uri.parse('$baseUrl/register_student');
    var request = http.MultipartRequest('POST', uri);

    request.fields['name'] = name;
    request.fields['student_id'] = studentId;
    request.fields['program'] = program;
    request.fields['major'] = major;

    for (var image in images) {
      request.files.add(await http.MultipartFile.fromPath(
        'images',
        image.path,
      ));
    }

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to register: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error connecting to server: $e');
    }
  }

  Future<Map<String, dynamic>> markAttendance(XFile image) async {
    var uri = Uri.parse('$baseUrl/mark_attendance');
    var request = http.MultipartRequest('POST', uri);

    request.files.add(await http.MultipartFile.fromPath(
      'image',
      image.path,
    ));

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to mark attendance: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error connecting to server: $e');
    }
  }
}
