import 'package:flutter/material.dart';
import '../services/api_service.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  final _api = ApiService();
  late Future<List<dynamic>> _studentFuture;

  @override
  void initState() {
    super.initState();
    _studentFuture = _api.getStudents();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Student Management',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _studentFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No students registered.'));
                }

                final students = snapshot.data!;
                return Card(
                  child: SingleChildScrollView(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Student ID')),
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Program')),
                        DataColumn(label: Text('Major')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: students.map((s) => DataRow(
                        cells: [
                          DataCell(Text(s['student_id'] ?? 'N/A')),
                          DataCell(Text(s['name'] ?? 'N/A')),
                          DataCell(Text(s['program'] ?? 'N/A')),
                          DataCell(Text(s['major'] ?? 'N/A')),
                          DataCell(Row(
                            children: [
                              IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () {}),
                              IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () {}),
                            ],
                          )),
                        ],
                      )).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
