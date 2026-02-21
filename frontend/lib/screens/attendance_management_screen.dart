import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/attendance_model.dart';
import 'dart:convert';

class AttendanceManagementScreen extends StatefulWidget {
  const AttendanceManagementScreen({super.key});

  @override
  State<AttendanceManagementScreen> createState() => _AttendanceManagementScreenState();
}

class _AttendanceManagementScreenState extends State<AttendanceManagementScreen> {
  final _api = ApiService();
  List<Attendance> _attendanceList = [];
  List<Attendance> _filteredList = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _fetchAttendance();
  }

  Future<void> _fetchAttendance() async {
    setState(() => _isLoading = true);
    try {
      final reports = await _api.getAllAttendanceReports();
      
      setState(() {
        _attendanceList = reports;
        _filteredList = reports;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _filterAttendance(String query) {
    setState(() {
      _filteredList = _attendanceList.where((a) {
        final matchesId = a.studentId.toLowerCase().contains(query.toLowerCase());
        final matchesName = a.name.toLowerCase().contains(query.toLowerCase());
        return matchesId || matchesName;
      }).toList();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      // TODO: Implement fetching by date API logic if available, currently getDailyReport is hardcoded to today in ApiService unless modified
      // api_service.dart: getDailyReport() calls /api/v1/reports/daily which usually takes ?report_date=...
      // I should update ApiService.getDailyReport to accept an optional date.
    }
  }

  Future<void> _deleteAttendance(int id) async {
    try {
      await _api.deleteAttendance(id);
      _fetchAttendance();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Record deleted')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _showAddDialog() async {
    final idController = TextEditingController();
    final dateController = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
    final timeController = TextEditingController(text: DateFormat('HH:mm:ss').format(DateTime.now()));
    String status = 'Present';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manual Attendance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             TextField(controller: idController, decoration: const InputDecoration(labelText: 'Student ID')),
             const SizedBox(height: 8),
             TextField(controller: dateController, decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)')),
             const SizedBox(height: 8),
             TextField(controller: timeController, decoration: const InputDecoration(labelText: 'Time (HH:MM:SS)')),
             const SizedBox(height: 8),
             DropdownButtonFormField<String>(
               value: status,
               items: ['Present', 'Absent', 'Late'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
               onChanged: (v) => status = v!,
               decoration: const InputDecoration(labelText: 'Status'),
             ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                final data = {
                  'student_id': idController.text,
                  'date': dateController.text,
                  'time': timeController.text,
                  'status': status,
                };
                await _api.createAttendance(data);
                if (mounted) {
                  Navigator.pop(context);
                  _fetchAttendance();
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
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
              const Text('Attendance Management', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: ApiService.hasPermission('can_manage_attendance') ? _showAddDialog : null,
                icon: const Icon(Icons.add),
                label: const Text('Manual Entry'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    labelText: 'Search by Name or ID',
                  ),
                  onChanged: _filterAttendance,
                ),
              ),
              const SizedBox(width: 16),
              IconButton(onPressed: () => _selectDate(context), icon: const Icon(Icons.calendar_today)),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Card(
                    child: SingleChildScrollView(
                      child: SizedBox(
                        width: double.infinity,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Date')),
                            DataColumn(label: Text('Name')),
                            DataColumn(label: Text('ID')),
                            DataColumn(label: Text('Time')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: _filteredList.map((a) => DataRow(
                            cells: [
                              DataCell(Text(a.date)),
                              DataCell(Text(a.name)),
                              DataCell(Text(a.studentId)),
                              DataCell(Text(a.time)),
                              DataCell(Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: a.status == 'Present' ? Colors.green.shade100 : Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(a.status, style: TextStyle(color: a.status == 'Present' ? Colors.green : Colors.red)),
                              )),
                              DataCell(IconButton(
                                icon: Icon(Icons.delete, color: ApiService.hasPermission('can_manage_attendance') ? Colors.red : Colors.grey),
                                onPressed: ApiService.hasPermission('can_manage_attendance') ? () => _deleteAttendance(a.id) : null,
                                tooltip: ApiService.hasPermission('can_manage_attendance') ? 'Delete' : 'No Permission',
                              )),
                            ],
                          )).toList(),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
