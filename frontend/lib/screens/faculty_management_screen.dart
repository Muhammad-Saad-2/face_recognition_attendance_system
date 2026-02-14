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
                onPressed: () {
                  // TODO: Implement add faculty dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Add Faculty feature coming soon')),
                  );
                },
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
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('ID')),
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Email')),
                        DataColumn(label: Text('Department ID')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: faculties.map((f) => DataRow(
                        cells: [
                          DataCell(Text(f['id'].toString())),
                          DataCell(Text(f['name'])),
                          DataCell(Text(f['email'])),
                          DataCell(Text(f['department_id']?.toString() ?? 'N/A')),
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
