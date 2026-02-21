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

  Future<void> _deleteStudent(String id) async {
    if (!await _showConfirmationDialog('Delete Student', 'Are you sure you want to delete this student?')) return;

    try {
      await _api.deleteStudent(id);
      _refresh();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student deleted successfully')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  /// Calculates semester from enrolled year — same logic as Android app.
  int _calculateSemester(int enrolledYear) {
    final now = DateTime.now();
    final yearsElapsed = now.year - enrolledYear;
    int semester = yearsElapsed * 2;
    if (now.month >= 8) semester += 1;
    return semester.clamp(1, 8);
  }

  Future<void> _showStudentDialog({Map<String, dynamic>? student}) async {
    final nameController = TextEditingController(text: student?['name'] ?? '');
    final rollNoController = TextEditingController(text: ''); // sequence part

    // Load programs & departments
    List<dynamic> programs = [];
    List<dynamic> departments = [];
    bool dataLoading = true;

    // Dialog-local state (managed via StatefulBuilder)
    String? selectedProgramId;
    String? selectedDepartmentUniqueId;
    String? selectedYear;
    int calculatedSemester = student?['current_semester'] ?? 1;
    String rollNoPrefix = '';

    // Pre-populate edit mode
    if (student != null) {
      selectedYear = _extractYearFromBatch(student['batch']);
      if (selectedYear != null) {
        calculatedSemester = _calculateSemester(int.parse(selectedYear));
      }
    }

    final isEditing = student != null;
    final List<String> years = List.generate(10, (i) => (2021 + i).toString());

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Kick off data load once
          if (dataLoading && programs.isEmpty) {
            Future.wait([_api.getPrograms(), _api.getDepartments()]).then((results) {
              final allDepts = results[1];
              final seenIds = <String>{};
              final uniqueDepts = <dynamic>[];
              for (var d in allDepts) {
                final uid = d['unique_id']?.toString();
                if (uid != null && seenIds.add(uid)) uniqueDepts.add(d);
              }
              setDialogState(() {
                programs = results[0];
                departments = uniqueDepts;
                dataLoading = false;

                // Pre-select program in edit mode
                if (isEditing) {
                  final match = programs.where((p) => p['name'] == student['program']).toList();
                  if (match.isNotEmpty) {
                    selectedProgramId = match.first['id'].toString();
                    _updateProgramSelection(
                      selectedProgramId!, programs, departments,
                      (deptId) => selectedDepartmentUniqueId = deptId,
                      (prefix) => rollNoPrefix = prefix,
                      selectedYear,
                    );
                  }
                }
              });
            }).catchError((Object _) {
              setDialogState(() => dataLoading = false);
              return null;
            });
          }

          void onYearChanged(String? year) {
            setDialogState(() {
              selectedYear = year;
              if (year != null) {
                calculatedSemester = _calculateSemester(int.parse(year));
              }
              if (selectedProgramId != null && programs.isNotEmpty) {
                _updateProgramSelection(
                  selectedProgramId!, programs, departments,
                  (deptId) => selectedDepartmentUniqueId = deptId,
                  (prefix) => rollNoPrefix = prefix,
                  year,
                );
              }
            });
          }

          void onProgramChanged(String? id) {
            setDialogState(() {
              selectedProgramId = id;
              _updateProgramSelection(
                id!, programs, departments,
                (deptId) => selectedDepartmentUniqueId = deptId,
                (prefix) => rollNoPrefix = prefix,
                selectedYear,
              );
            });
          }

          return AlertDialog(
            title: Text(isEditing ? 'Edit Student' : 'Add Student'),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: dataLoading
                    ? const SizedBox(
                        height: 100,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Name
                          TextField(
                            controller: nameController,
                            decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                          ),
                          const SizedBox(height: 12),

                          // Program dropdown
                          DropdownButtonFormField<String>(
                            value: selectedProgramId,
                            decoration: const InputDecoration(labelText: 'Program', border: OutlineInputBorder()),
                            isExpanded: true,
                            items: programs.map<DropdownMenuItem<String>>((p) => DropdownMenuItem(
                              value: p['id'].toString(),
                              child: Text('${p['code']} – ${p['name']}', style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                            )).toList(),
                            onChanged: onProgramChanged,
                          ),
                          const SizedBox(height: 12),

                          // Enrolled Year
                          DropdownButtonFormField<String>(
                            value: selectedYear,
                            decoration: const InputDecoration(labelText: 'Enrolled Year', border: OutlineInputBorder()),
                            items: years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                            onChanged: onYearChanged,
                          ),
                          const SizedBox(height: 12),

                          // Department (auto, read-only)
                          DropdownButtonFormField<String>(
                            value: selectedDepartmentUniqueId,
                            decoration: const InputDecoration(
                              labelText: 'Department (Auto)',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Color(0x1A000000),
                            ),
                            items: departments.map<DropdownMenuItem<String>>((d) => DropdownMenuItem(
                              value: d['unique_id'].toString(),
                              child: Text(d['name']),
                            )).toList(),
                            onChanged: null, // read-only
                          ),
                          const SizedBox(height: 12),

                          // Semester (auto-calculated, read-only)
                          InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Current Semester (Auto)',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Color(0x1A000000),
                            ),
                            child: Text(
                              selectedYear == null ? '—' : 'Semester $calculatedSemester',
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Batch (derived from year)
                          InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Batch (Auto)',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Color(0x1A000000),
                            ),
                            child: Text(
                              selectedYear == null ? '—' : 'Fall-$selectedYear',
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),

                          // Roll No section — only shown for new adds
                          if (!isEditing) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(4)),
                                    color: Colors.grey.shade200,
                                  ),
                                  child: Text(rollNoPrefix.isEmpty ? 'YYYY-PROG-' : rollNoPrefix,
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: rollNoController,
                                    decoration: const InputDecoration(
                                      labelText: 'Seq No (e.g. 055)',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.horizontal(right: Radius.circular(4))),
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '⚠ Adding a new student here does not register their face. Use the Register Student screen on the Android app for full registration with face images.',
                              style: TextStyle(fontSize: 11, color: Colors.orange),
                            ),
                          ],
                        ],
                      ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final data = {
                      'name': nameController.text.trim(),
                      if (selectedProgramId != null && programs.isNotEmpty)
                        'program': programs.firstWhere((p) => p['id'].toString() == selectedProgramId)['name'],
                      if (selectedYear != null) 'batch': 'Fall-$selectedYear',
                      'current_semester': calculatedSemester,
                    };

                    if (isEditing) {
                      await _api.updateStudent(student!['student_id'], data);
                    } else {
                      // No face registration via MIS — show info
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please use the Android app to register new students with face images.'),
                            duration: Duration(seconds: 4),
                          ),
                        );
                        return;
                      }
                    }

                    if (mounted) {
                      Navigator.pop(context);
                      _refresh();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(isEditing ? 'Student updated' : 'Student added')),
                      );
                    }
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Updates department selection and roll-number prefix when program changes.
  void _updateProgramSelection(
    String programId,
    List<dynamic> programs,
    List<dynamic> departments,
    void Function(String?) setDept,
    void Function(String) setPrefix,
    String? year,
  ) {
    final program = programs.firstWhere((p) => p['id'].toString() == programId, orElse: () => null);
    if (program == null) return;

    final deptUniqueId = program['department_id']?.toString();
    if (deptUniqueId != null && departments.any((d) => d['unique_id'].toString() == deptUniqueId)) {
      setDept(deptUniqueId);
    }

    final prefix = year != null ? '$year-${program['code']}-' : '';
    setPrefix(prefix);
  }

  /// Attempts to extract the year from a batch string like "Fall-2023" → "2023".
  String? _extractYearFromBatch(dynamic batch) {
    if (batch == null || batch == 'Unknown') return null;
    final parts = batch.toString().split('-');
    if (parts.length >= 2) return parts.last;
    return null;
  }

  Future<bool> _showConfirmationDialog(String title, String content) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Confirm', style: TextStyle(color: Colors.red))),
            ],
          ),
        ) ??
        false;
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
              const Text('Student Management', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              if (ApiService.hasPermission('can_manage_students'))
                ElevatedButton.icon(
                  onPressed: () => _showStudentDialog(),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add Student'),
                ),
            ],
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
                          DataColumn(label: Text('Batch')),
                          DataColumn(label: Text('Sem')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: students.map((s) => DataRow(
                          cells: [
                            DataCell(Text(s['student_id'])),
                            DataCell(Text(s['name'])),
                            DataCell(Text(s['program'])),
                            DataCell(Text(s['batch'] ?? 'Unknown')),
                            DataCell(Text(s['current_semester']?.toString() ?? '1')),
                            DataCell(Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, size: 20, color: ApiService.hasPermission('can_manage_students') ? Colors.blue : Colors.grey),
                                  onPressed: ApiService.hasPermission('can_manage_students') ? () => _showStudentDialog(student: s) : null,
                                  tooltip: 'Edit',
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, size: 20, color: ApiService.hasPermission('can_manage_students') ? Colors.red : Colors.grey),
                                  onPressed: ApiService.hasPermission('can_manage_students') ? () => _deleteStudent(s['student_id']) : null,
                                  tooltip: 'Delete',
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
