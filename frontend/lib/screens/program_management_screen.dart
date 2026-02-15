import 'package:flutter/material.dart'; // Forced Rebuild
import '../services/api_service.dart';

class ProgramManagementScreen extends StatefulWidget {
  const ProgramManagementScreen({super.key});

  @override
  State<ProgramManagementScreen> createState() => _ProgramManagementScreenState();
}

class _ProgramManagementScreenState extends State<ProgramManagementScreen> {
  final _api = ApiService();
  late Future<List<dynamic>> _programsFuture;

  List<dynamic> _departments = [];

  @override
  void initState() {
    super.initState();
    _refresh();
    _fetchDepartments();
  }

  Future<void> _refresh() async {
    setState(() {
      _programsFuture = _api.getPrograms();
    });
  }

  Future<void> _fetchDepartments() async {
    try {
      final depts = await _api.getDepartments();
      setState(() => _departments = depts);
    } catch (e) {
      // Handle error cleanly or ignore if just for dropdown
    }
  }

  Future<void> _deleteProgram(int id) async {
    if (!await _showConfirmationDialog('Delete Program', 'Are you sure?')) return;
    try {
      await _api.deleteProgram(id);
      _refresh();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Program deleted')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _showProgramDialog({Map<String, dynamic>? program}) async {
    final nameController = TextEditingController(text: program != null ? program['name'] : '');
    final codeController = TextEditingController(text: program != null ? program['code'] : '');
    int? selectedDeptId = program != null ? program['department_id'] : null;
    final isEditing = program != null;

    if (_departments.isEmpty) await _fetchDepartments();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? 'Edit Program' : 'Add Program'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 8),
              TextField(controller: codeController, decoration: const InputDecoration(labelText: 'Code')),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: selectedDeptId,
                items: _departments.map<DropdownMenuItem<int>>((d) {
                  return DropdownMenuItem<int>(
                    value: d['id'],
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
                    'department_id': selectedDeptId
                  };
                  if (isEditing) {
                    await _api.updateProgram(program['id'], data);
                  } else {
                    await _api.createProgram(data);
                  }
                  if (mounted) {
                    Navigator.pop(context);
                    _refresh();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEditing ? 'Program updated' : 'Program added')));
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
                'Program Management',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: ApiService.hasPermission('can_manage_academic') ? () => _showProgramDialog() : null,
                icon: const Icon(Icons.add),
                label: const Text('Add Program'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _programsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No programs found.'));
                }

                final programs = snapshot.data!;
                return Card(
                  child: SingleChildScrollView(
                    child: SizedBox(
                      width: double.infinity,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Prog ID')),
                          DataColumn(label: Text('Code')),
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Dept ID')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: programs.map((p) => DataRow(
                          cells: [
                            DataCell(Text(p['unique_id'] ?? '-')),
                            DataCell(Text(p['code'])),
                            DataCell(Text(p['name'])),
                            DataCell(Text(p['department_id']?.toString() ?? 'N/A')),
                            DataCell(Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, size: 20, color: ApiService.hasPermission('can_manage_academic') ? Colors.blue : Colors.grey),
                                  onPressed: ApiService.hasPermission('can_manage_academic') ? () => _showProgramDialog(program: p) : null,
                                  tooltip: ApiService.hasPermission('can_manage_academic') ? 'Edit' : 'No Permission',
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, size: 20, color: ApiService.hasPermission('can_manage_academic') ? Colors.red : Colors.grey),
                                  onPressed: ApiService.hasPermission('can_manage_academic') ? () => _deleteProgram(p['id']) : null,
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
