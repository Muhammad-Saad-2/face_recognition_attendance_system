import 'package:flutter/material.dart';
import '../services/api_service.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  final _api = ApiService();
  late Future<List<dynamic>> _studentsFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _studentsFuture = _api.getStudents();
    });
  }

  Future<void> _deleteStudent(int id) async {
    if (!await _showConfirmationDialog('Delete Student', 'Are you sure you want to delete this student?')) return;

    try {
      await _api.deleteStudent(id.toString());
      _refresh();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student deleted successfully')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _showStudentDialog({Map<String, dynamic>? student}) async {
    final nameController = TextEditingController(text: student != null ? student['name'] : '');
    final idController = TextEditingController(text: student != null ? student['student_id'] : '');
    final programController = TextEditingController(text: student != null ? student['program'] : '');
    final majorController = TextEditingController(text: student != null ? student['major'] : '');
    int currentSemester = student != null && student['current_semester'] != null ? student['current_semester'] : 1;
    final isEditing = student != null;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? 'Edit Student' : 'Add Student'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
                const SizedBox(height: 8),
                TextField(controller: idController, decoration: const InputDecoration(labelText: 'Student ID')),
                const SizedBox(height: 8),
                TextField(controller: programController, decoration: const InputDecoration(labelText: 'Program')),
                const SizedBox(height: 8),
                TextField(controller: majorController, decoration: const InputDecoration(labelText: 'Major')),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: currentSemester,
                  items: List.generate(8, (index) => index + 1).map((s) {
                    return DropdownMenuItem<int>(
                      value: s,
                      child: Text('Semester $s'),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => currentSemester = val!),
                  decoration: const InputDecoration(labelText: 'Current Semester'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                try {
                  final data = {
                    'name': nameController.text,
                    'student_id': idController.text,
                    'program': programController.text,
                    'major': majorController.text,
                    'current_semester': currentSemester,
                  };
                  if (isEditing) {
                    await _api.updateStudent(student!['id'], data);
                  } else {
                    // Note: Registration usually happens via specific flow with images, but for admin edit/add simple:
                    // Only update is fully supported via this dialog in current API structure for "full" student.
                    // Registration requires images.
                    // Letting update handle it for now.
                    // Actually, let's use the register endpoint if adding, but it needs images.
                    // For now, let's assume this dialog is primarily for EDIT or simple add without face.
                    // But wait, the backend register requires images.
                    // Let's stick to update for now or handle add if simplified.
                    // Given the constraint, I'll only support Update here fully, or use a simplified create if backend allows.
                    // The backend `register_student` requires images.
                    // So for "Add", we should redirect to registration screen or show warning.
                    if (!isEditing) {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please use Registration Screen to add new students with File/Images.')));
                       return;
                    }
                     await _api.updateStudent(student!['id'], data);
                  }
                  if (mounted) {
                    Navigator.pop(context);
                    _refresh();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEditing ? 'Student updated' : 'Student added')));
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
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
              future: _studentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No students found.'));
                }

                final students = snapshot.data!;
                return Card(
                  child: SingleChildScrollView(
                    child: SizedBox(
                      width: double.infinity,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Program')),
                          DataColumn(label: Text('Major')),
                          DataColumn(label: Text('Sem')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: students.map((s) => DataRow(
                          cells: [
                            DataCell(Text(s['student_id'])),
                            DataCell(Text(s['name'])),
                            DataCell(Text(s['program'])),
                            DataCell(Text(s['major'])),
                            DataCell(Text(s['current_semester']?.toString() ?? '1')),
                            DataCell(Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, size: 20, color: ApiService.hasPermission('can_manage_students') ? Colors.blue : Colors.grey),
                                  onPressed: ApiService.hasPermission('can_manage_students') ? () => _showStudentDialog(student: s) : null,
                                  tooltip: ApiService.hasPermission('can_manage_students') ? 'Edit' : 'No Permission',
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, size: 20, color: ApiService.hasPermission('can_manage_students') ? Colors.red : Colors.grey),
                                  onPressed: ApiService.hasPermission('can_manage_students') ? () => _deleteStudent(s['id']) : null,
                                  tooltip: ApiService.hasPermission('can_manage_students') ? 'Delete' : 'No Permission',
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
