import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CourseManagementScreen extends StatefulWidget {
  const CourseManagementScreen({super.key});

  @override
  State<CourseManagementScreen> createState() => _CourseManagementScreenState();
}

class _CourseManagementScreenState extends State<CourseManagementScreen> {
  final _api = ApiService();
  late Future<List<dynamic>> _coursesFuture;

  List<dynamic> _departments = [];

  @override
  void initState() {
    super.initState();
    _refresh();
    _fetchDepartments();
  }

  Future<void> _refresh() async {
    setState(() {
      _coursesFuture = _api.getCourses();
    });
  }

  Future<void> _fetchDepartments() async {
    try {
      final depts = await _api.getDepartments();
      setState(() => _departments = depts);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _deleteCourse(int id) async {
    if (!await _showConfirmationDialog('Delete Course', 'Are you sure?')) return;
    try {
      await _api.deleteCourse(id);
      _refresh();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Course deleted')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _showCourseDialog({Map<String, dynamic>? course}) async {
    final nameController = TextEditingController(text: course != null ? course['name'] : '');
    final codeController = TextEditingController(text: course != null ? course['code'] : '');
    String? selectedDeptId = course != null ? course['department_id']?.toString() : null;
    final isEditing = course != null;

    if (_departments.isEmpty) await _fetchDepartments();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? 'Edit Course' : 'Add Course'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 8),
              TextField(controller: codeController, decoration: const InputDecoration(labelText: 'Code')),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedDeptId,
                items: _departments.map<DropdownMenuItem<String>>((d) {
                  return DropdownMenuItem<String>(
                    value: d['unique_id'].toString(),
                    child: Text('${d['code']} - ${d['name']}'),
                  );
                }).toList(),
                onChanged: (val) => setState(() => selectedDeptId = val),
                decoration: const InputDecoration(labelText: 'Department'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                try {
                  if (selectedDeptId == null) throw Exception('Select a department');
                  final data = {
                    'name': nameController.text,
                    'code': codeController.text,
                    'department_id': selectedDeptId,
                  };
                  if (isEditing) {
                    await _api.updateCourse(course['id'], data);
                  } else {
                    await _api.createCourse(data);
                  }
                  if (mounted) {
                    Navigator.pop(context);
                    _refresh();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEditing ? 'Course updated' : 'Course added')));
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Course Management',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: ApiService.hasPermission('can_manage_courses') ? () => _showCourseDialog() : null,
                icon: const Icon(Icons.add),
                label: const Text('Add Course'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _coursesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No courses found.'));
                }

                final courses = snapshot.data!;
                return Card(
                  child: SingleChildScrollView(
                    child: SizedBox(
                      width: double.infinity,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('Code')),
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Dept ID')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: courses.map((c) => DataRow(
                          cells: [
                            DataCell(Text(c['id'].toString())),
                            DataCell(Text(c['code'])),
                            DataCell(Text(c['name'])),
                            DataCell(Text(c['department_id']?.toString() ?? 'N/A')),
                            DataCell(Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, size: 20, color: ApiService.hasPermission('can_manage_courses') ? Colors.blue : Colors.grey),
                                  onPressed: ApiService.hasPermission('can_manage_courses') ? () => _showCourseDialog(course: c) : null,
                                  tooltip: ApiService.hasPermission('can_manage_courses') ? 'Edit' : 'No Permission',
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, size: 20, color: ApiService.hasPermission('can_manage_courses') ? Colors.red : Colors.grey),
                                  onPressed: ApiService.hasPermission('can_manage_courses') ? () => _deleteCourse(c['id']) : null,
                                  tooltip: ApiService.hasPermission('can_manage_courses') ? 'Delete' : 'No Permission',
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
