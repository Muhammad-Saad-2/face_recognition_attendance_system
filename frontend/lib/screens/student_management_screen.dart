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

  Future<void> _deleteStudent(String studentId) async {
    if (!await _showConfirmationDialog('Delete Student', 'Are you sure you want to delete this student?')) return;

    try {
      await _api.deleteStudent(studentId);
      setState(() {
        _studentFuture = _api.getStudents();
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student deleted successfully')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _editStudent(Map<String, dynamic> student) async {
    final nameController = TextEditingController(text: student['name']);
    final programController = TextEditingController(text: student['program']);
    final majorController = TextEditingController(text: student['major']);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Student'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 8),
            TextField(controller: programController, decoration: const InputDecoration(labelText: 'Program')),
            const SizedBox(height: 8),
            TextField(controller: majorController, decoration: const InputDecoration(labelText: 'Major')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                final data = {
                  'name': nameController.text,
                  'program': programController.text,
                  'major': majorController.text,
                };
                await _api.updateStudent(student['student_id'], data);
                setState(() {
                  _studentFuture = _api.getStudents();
                });
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student updated successfully')));
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showConfirmationDialog(String title, String content) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm', style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;
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
                    child: SizedBox(
                      width: double.infinity,
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
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                                  onPressed: () => _editStudent(s),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                  onPressed: () => _deleteStudent(s['student_id']),
                                ),
                              ],
                            )),
                          ],
                        )).toList(),
                      ),
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
