import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../models/attendance_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _api = ApiService();
  List<Attendance> _records = [];
  bool _isLoading = true;
  String? _error;

  // Filters (used on web MIS view)
  String? _selectedBatch;
  String? _selectedProgram;
  Set<String> _availableBatches = {};
  Set<String> _availablePrograms = {};

  @override
  void initState() {
    super.initState();
    _fetchRecords();
  }

  Future<void> _fetchRecords() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final records = await _api.getAllAttendanceReports();
      setState(() {
        _records = records;
        _availableBatches = records.map((e) => e.batch).toSet();
        _availablePrograms = records.map((e) => e.program).toSet();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Shared chart dashboard for both web (MIS) and Android (Recent Activity)
    // Web: embedded in NavigationRail layout (no Scaffold needed)
    // Android: wrapped in Scaffold with AppBar
    final content = _buildDashboardContent();
    if (kIsWeb) {
      return content;
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Attendance Dashboard'),
          actions: [
            IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _fetchRecords,
                tooltip: 'Refresh'),
          ],
        ),
        body: content,
      );
    }
  }

  // ──────────────────────────────────────────────
  // SHARED DASHBOARD — Charts + Filters + DataTable
  // ──────────────────────────────────────────────
  Widget _buildDashboardContent() {
    return Container(
      color: Colors.grey[50],
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Attendance Dashboard',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                  Text('Overview of all attendance records',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
                onPressed: _fetchRecords,
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            Expanded(child: _buildError())
          else if (_records.isEmpty)
            const Expanded(
                child: Center(child: Text('No attendance records yet.')))
          else
            Expanded(child: _buildWebContent()),
        ],
      ),
    );
  }

  Widget _buildWebContent() {
    // Apply filters
    final filtered = _records.where((r) {
      final batchOk =
          _selectedBatch == null || _selectedBatch == 'All' || r.batch == _selectedBatch;
      final progOk = _selectedProgram == null ||
          _selectedProgram == 'All' ||
          r.program == _selectedProgram;
      return batchOk && progOk;
    }).toList();

    // Stats for charts
    Map<String, int> programCounts = {};
    Map<String, int> statusCounts = {'Present': 0, 'Absent': 0};
    for (var r in filtered) {
      programCounts[r.program] = (programCounts[r.program] ?? 0) + 1;
      if (r.status.toLowerCase() == 'present') {
        statusCounts['Present'] = (statusCounts['Present'] ?? 0) + 1;
      } else {
        statusCounts['Absent'] = (statusCounts['Absent'] ?? 0) + 1;
      }
    }

    final total = filtered.length;
    final presentCount = statusCounts['Present'] ?? 0;
    final absentCount = statusCounts['Absent'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Stats Cards Row ──
        Row(
          children: [
            _statCard('Total Records', '$total', Icons.list_alt, Colors.blueAccent),
            const SizedBox(width: 16),
            _statCard('Present', '$presentCount', Icons.check_circle_outline, Colors.green),
            const SizedBox(width: 16),
            _statCard('Absent', '$absentCount', Icons.cancel_outlined, Colors.red),
          ],
        ),
        const SizedBox(height: 24),

        // ── Filter Bar ──
        _buildFilterBar(),
        const SizedBox(height: 24),

        // ── Charts Row ──
        if (filtered.isNotEmpty)
          SizedBox(
            height: 260,
            child: Row(
              children: [
                // Pie chart by program
                Expanded(
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('By Program',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(child: _buildPieChart(programCounts)),
                                const SizedBox(width: 16),
                                Expanded(child: _buildChartLegend(programCounts)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Pie chart present vs absent
                Expanded(
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Present vs Absent',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                    child: _buildPieChart({
                                  'Present': presentCount,
                                  'Absent': absentCount,
                                }, colors: [Colors.green, Colors.red])),
                                const SizedBox(width: 16),
                                Expanded(
                                    child: _buildChartLegend({
                                  'Present': presentCount,
                                  'Absent': absentCount,
                                }, colors: [Colors.green, Colors.red])),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),

        // ── DataTable of Records ──
        Expanded(
          child: Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowColor:
                        MaterialStateProperty.all(Colors.grey[100]),
                    columnSpacing: 40,
                    columns: const [
                      DataColumn(
                          label: Text('NAME',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('ID',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('PROGRAM',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('BATCH',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('DATE',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('TIME',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('STATUS',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: filtered.map((a) {
                      final isPresent =
                          a.status.toLowerCase() == 'present';
                      return DataRow(cells: [
                        DataCell(Text(a.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w500))),
                        DataCell(Text(a.studentId)),
                        DataCell(Text(a.program)),
                        DataCell(Text(a.batch)),
                        DataCell(Text(a.date)),
                        DataCell(Text(a.time.split('.').first)),
                        DataCell(Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isPresent
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            a.status,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isPresent ? Colors.green : Colors.red,
                            ),
                          ),
                        )),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: color)),
                  Text(label,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Filter by Batch',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              isDense: true,
            ),
            value: _selectedBatch,
            items: ['All', ..._availableBatches]
                .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                .toList(),
            onChanged: (val) => setState(() => _selectedBatch = val),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Filter by Program',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              isDense: true,
            ),
            value: _selectedProgram,
            items: ['All', ..._availablePrograms]
                .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                .toList(),
            onChanged: (val) => setState(() => _selectedProgram = val),
          ),
        ),
      ],
    );
  }

  Widget _buildPieChart(Map<String, int> data, {List<Color>? colors}) {
    if (data.isEmpty || data.values.every((v) => v == 0)) {
      return const Center(child: Text('No data', style: TextStyle(color: Colors.grey)));
    }
    final List<PieChartSectionData> sections = [];
    int i = 0;
    data.forEach((label, count) {
      if (count == 0) { i++; return; }
      final color = colors != null
          ? colors[i % colors.length]
          : Colors.primaries[i % Colors.primaries.length];
      sections.add(PieChartSectionData(
        color: color,
        value: count.toDouble(),
        title: '$count',
        radius: 70,
        titleStyle: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
      ));
      i++;
    });
    return PieChart(
      PieChartData(sectionsSpace: 2, centerSpaceRadius: 8, sections: sections),
    );
  }

  Widget _buildChartLegend(Map<String, int> data, {List<Color>? colors}) {
    final List<Widget> items = [];
    int i = 0;
    data.forEach((label, count) {
      final color = colors != null
          ? colors[i % colors.length]
          : Colors.primaries[i % Colors.primaries.length];
      items.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 8),
            Expanded(
                child: Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12))),
            Text('($count)', style: const TextStyle(fontSize: 12)),
          ],
        ),
      ));
      i++;
    });
    return SingleChildScrollView(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: items),
    );
  }


  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          const Text('Failed to load records'),
          const SizedBox(height: 8),
          Text(_error!,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
              onPressed: _fetchRecords,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry')),
        ],
      ),
    );
  }
}


// ── Attendance Card (mobile) ──────────────────
class _AttendanceCard extends StatelessWidget {
  final Attendance record;
  const _AttendanceCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final isPresent = record.status.toLowerCase() == 'present';
    final statusColor = isPresent ? Colors.green : Colors.red;
    final timeShort = record.time.split('.').first;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: statusColor.withOpacity(0.12),
              child: Icon(
                  isPresent ? Icons.check_circle : Icons.cancel,
                  color: statusColor,
                  size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record.name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(record.studentId,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 4),
                  Row(children: [
                    _Chip(
                        label: record.program.length > 20
                            ? '${record.program.substring(0, 20)}…'
                            : record.program,
                        color: Colors.indigo),
                    const SizedBox(width: 6),
                    _Chip(label: record.batch, color: Colors.blueGrey),
                  ]),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(record.date,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(timeShort,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(record.status,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusColor)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
