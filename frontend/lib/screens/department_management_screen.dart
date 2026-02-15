import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DepartmentManagementScreen extends StatefulWidget {
  const DepartmentManagementScreen({super.key});

  @override
  State<DepartmentManagementScreen> createState() => _DepartmentManagementScreenState();
}

class _DepartmentManagementScreenState extends State<DepartmentManagementScreen> {
  final _api = ApiService();
  late Future<List<dynamic>> _departmentsFuture;

  @override
  void initState() {
    super.initState();
    _departmentsFuture = _api.getDepartments();
  }

  Future<void> _refresh() async {
    setState(() {
      _departmentsFuture = _api.getDepartments();
    });
  }

  Future<void> _deleteDepartment(int id) async {
    if (!await _showConfirmationDialog('Delete Department', 'Are you sure?')) return;
    try {
      await _api.deleteDepartment(id);
      _refresh();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Department deleted')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _showDepartmentDialog({Map<String, dynamic>? department}) async {
    final nameController = TextEditingController(text: department != null ? department['name'] : '');
    final codeController = TextEditingController(text: department != null ? department['code'] : '');
    final isEditing = department != null;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Department' : 'Add Department'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 8),
            TextField(controller: codeController, decoration: const InputDecoration(labelText: 'Code')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                final data = {'name': nameController.text, 'code': codeController.text};
                if (isEditing) {
                  await _api.updateDepartment(department['id'], data);
                } else {
                  await _api.createDepartment(data);
                }
                if (mounted) {
                  Navigator.pop(context);
                  _refresh();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEditing ? 'Department updated' : 'Department added')));
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
                'Department Management',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: ApiService.hasPermission('can_manage_academic') ? () => _showDepartmentDialog() : null,
                icon: const Icon(Icons.add),
                label: const Text('Add Department'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _departmentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No departments found.'));
                }

                final departments = snapshot.data!;
                return Card(
                  child: SingleChildScrollView(
                    child: SizedBox(
                      width: double.infinity,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Dept ID')),
                          DataColumn(label: Text('Code')),
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: departments.map((d) => DataRow(
                          cells: [
                            DataCell(Text(d['unique_id'] ?? '-')),
                            DataCell(Text(d['code'])),
                            DataCell(Text(d['name'])),
                            DataCell(Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, size: 20, color: ApiService.hasPermission('can_manage_academic') ? Colors.blue : Colors.grey),
                                  onPressed: ApiService.hasPermission('can_manage_academic') ? () => _showDepartmentDialog(department: d) : null,
                                  tooltip: ApiService.hasPermission('can_manage_academic') ? 'Edit' : 'No Permission',
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, size: 20, color: ApiService.hasPermission('can_manage_academic') ? Colors.red : Colors.grey),
                                  onPressed: ApiService.hasPermission('can_manage_academic') ? () => _deleteDepartment(d['id']) : null,
                                  tooltip: ApiService.hasPermission('can_manage_academic') ? 'Delete' : 'No Permission',
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
