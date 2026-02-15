import 'package:flutter/material.dart';
import '../services/api_service.dart';

class FacultyManagementScreen extends StatefulWidget {
  const FacultyManagementScreen({super.key});

  @override
  State<FacultyManagementScreen> createState() => _FacultyManagementScreenState();
}

class _FacultyManagementScreenState extends State<FacultyManagementScreen> {
  final _api = ApiService();
  late Future<List<dynamic>> _facultyFuture;

  @override
  void initState() {
    super.initState();
    _facultyFuture = _api.getFaculties();
  }

  void _refresh() {
    setState(() {
      _facultyFuture = _api.getFaculties();
    });
  }

  Future<void> _deleteFaculty(int id) async {
    if (!await _showConfirmationDialog('Delete Faculty', 'Are you sure you want to delete this faculty member?')) return;

    try {
      await _api.deleteFaculty(id);
      _refresh();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Faculty deleted successfully')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _showFacultyDialog({Map<String, dynamic>? faculty}) async {
    final nameController = TextEditingController(text: faculty != null ? faculty['name'] : '');
    final emailController = TextEditingController(text: faculty != null ? faculty['email'] : '');
    final deptIdController = TextEditingController(text: faculty != null ? faculty['department_id'].toString() : '');
    final isEditing = faculty != null;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Faculty' : 'Add Faculty'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 8),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 8),
            TextField(controller: deptIdController, decoration: const InputDecoration(labelText: 'Department ID'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                final deptId = int.tryParse(deptIdController.text);
                if (deptId == null) throw Exception('Invalid Department ID');

                if (isEditing) {
                  final data = {
                    'name': nameController.text,
                    'email': emailController.text,
                    'department_id': deptId,
                  };
                  await _api.updateFaculty(faculty['id'], data);
                } else {
                  await _api.createFaculty(nameController.text, emailController.text, deptId);
                }
                
                if (mounted) {
                  Navigator.pop(context);
                  _refresh();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEditing ? 'Faculty updated' : 'Faculty added')));
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Faculty Management',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: ApiService.hasPermission('can_manage_faculty') ? () => _showFacultyDialog() : null,
                icon: const Icon(Icons.add),
                label: const Text('Add Faculty Member'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _facultyFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No faculty members found.'));
                }

                final faculties = snapshot.data!;
                return Card(
                  child: SingleChildScrollView(
                    child: SizedBox(
                      width: double.infinity,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Faculty ID')),
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Email')),
                          DataColumn(label: Text('Department ID')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: faculties.map((f) => DataRow(
                          cells: [
                            DataCell(Text(f['faculty_id'] ?? '-')),
                            DataCell(Text(f['name'])),
                            DataCell(Text(f['email'])),
                            DataCell(Text(f['department_id']?.toString() ?? 'N/A')),
                            DataCell(Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, size: 20, color: ApiService.hasPermission('can_manage_faculty') ? Colors.blue : Colors.grey),
                                  onPressed: ApiService.hasPermission('can_manage_faculty') ? () => _showFacultyDialog(faculty: f) : null,
                                  tooltip: ApiService.hasPermission('can_manage_faculty') ? 'Edit' : 'No Permission',
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, size: 20, color: ApiService.hasPermission('can_manage_faculty') ? Colors.red : Colors.grey),
                                  onPressed: ApiService.hasPermission('can_manage_faculty') ? () => _deleteFaculty(f['id']) : null,
                                  tooltip: ApiService.hasPermission('can_manage_faculty') ? 'Delete' : 'No Permission',
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
