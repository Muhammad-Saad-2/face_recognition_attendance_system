import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../models/attendance_model.dart';
import 'dart:math';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _api = ApiService();
  late Future<List<Attendance>> _reportFuture;

  // Filters State
  String? _selectedBatch;
  String? _selectedProgram;

  // Cached Filter Options
  Set<String> _availableBatches = {};
  Set<String> _availablePrograms = {};

  @override
  void initState() {
    super.initState();
    _reportFuture = _api.getAllAttendanceReports();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MIS Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'All Attendance Overview',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: FutureBuilder<List<Attendance>>(
                future: _reportFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No attendance records found.'));
                  }

                  final allReports = snapshot.data!;

                  // Extract available filters dynamically
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final batches = allReports.map((e) => e.batch).toSet();
                    final programs = allReports.map((e) => e.program).toSet();
                    if (batches.length != _availableBatches.length || programs.length != _availablePrograms.length) {
                       setState(() {
                         _availableBatches = batches;
                         _availablePrograms = programs;
                       });
                    }
                  });

                  // Apply filters
                  final filteredReports = allReports.where((r) {
                    final batchMatch = _selectedBatch == null || _selectedBatch == 'All' || r.batch == _selectedBatch;
                    final programMatch = _selectedProgram == null || _selectedProgram == 'All' || r.program == _selectedProgram;
                    return batchMatch && programMatch;
                  }).toList();

                  // Calculate stats for chart
                  Map<String, int> programCounts = {};
                  for (var r in filteredReports) {
                     programCounts[r.program] = (programCounts[r.program] ?? 0) + 1;
                  }

                  return Column(
                     crossAxisAlignment: CrossAxisAlignment.stretch,
                     children: [
                       _buildFilterBar(),
                       const SizedBox(height: 24),
                       // Chart Container
                       if (filteredReports.isNotEmpty)
                         Container(
                           height: 250,
                           padding: const EdgeInsets.all(16),
                           decoration: BoxDecoration(
                             color: Colors.white,
                             borderRadius: BorderRadius.circular(12),
                             boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                           ),
                           child: Row(
                             children: [
                               Expanded(child: _buildPieChart(programCounts)),
                               const SizedBox(width: 24),
                               Expanded(child: _buildChartLegend(programCounts)),
                             ],
                           )
                         ),
                       const SizedBox(height: 24),
                       const Text('Recent Records', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                       const SizedBox(height: 12),
                       Expanded(
                         child: Card(
                           child: SingleChildScrollView(
                             scrollDirection: Axis.horizontal,
                             child: DataTable(
                               columns: const [
                                 DataColumn(label: Text('Name')),
                                 DataColumn(label: Text('ID')),
                                 DataColumn(label: Text('Program')),
                                 DataColumn(label: Text('Batch')),
                                 DataColumn(label: Text('Time')),
                                 DataColumn(label: Text('Status')),
                               ],
                               rows: filteredReports.map((a) => DataRow(
                                 cells: [
                                   DataCell(Text(a.name)),
                                   DataCell(Text(a.studentId)),
                                   DataCell(Text(a.program)),
                                   DataCell(Text(a.batch)),
                                   DataCell(Text(a.time.split('.').first)),
                                   DataCell(
                                     Container(
                                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                       decoration: BoxDecoration(
                                         color: Colors.green.shade100,
                                         borderRadius: BorderRadius.circular(4),
                                       ),
                                       child: Text(a.status, style: const TextStyle(color: Colors.green)),
                                     ),
                                   ),
                                 ],
                               )).toList(),
                             ),
                           ),
                         ),
                       ),
                     ]
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Filter by Batch', border: OutlineInputBorder()),
            value: _selectedBatch,
            items: ['All', ..._availableBatches].map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
            onChanged: (val) {
              setState(() {
                _selectedBatch = val;
              });
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Filter by Program', border: OutlineInputBorder()),
            value: _selectedProgram,
            items: ['All', ..._availablePrograms].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
            onChanged: (val) {
              setState(() {
                _selectedProgram = val;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPieChart(Map<String, int> data) {
    if (data.isEmpty) return const Center(child: Text("No data to chart"));
    List<PieChartSectionData> sections = [];
    int i = 0;
    data.forEach((program, count) {
      final color = Colors.primaries[i % Colors.primaries.length];
      sections.add(
        PieChartSectionData(
          color: color,
          value: count.toDouble(),
          title: '$count',
          radius: 80,
          titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        )
      );
      i++;
    });

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 10,
        sections: sections,
      ),
    );
  }

  Widget _buildChartLegend(Map<String, int> data) {
    List<Widget> legends = [];
    int i = 0;
    data.forEach((program, count) {
      final color = Colors.primaries[i % Colors.primaries.length];
      legends.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(width: 16, height: 16, color: color),
              const SizedBox(width: 8),
              Expanded(child: Text(program, overflow: TextOverflow.ellipsis)),
              Text('($count)'),
            ],
          ),
        )
      );
      i++;
    });
    
    return SingleChildScrollView(
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         mainAxisAlignment: MainAxisAlignment.center,
         children: legends,
       )
    );
  }
}
