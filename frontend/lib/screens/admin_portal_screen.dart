import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/api_service.dart';
import 'dashboard_screen.dart';
import 'faculty_management_screen.dart';
import 'student_management_screen.dart';
import 'attendance_management_screen.dart';
import 'department_management_screen.dart';
import 'program_management_screen.dart';
import 'course_management_screen.dart';
import 'manage_admins_screen.dart';

class AdminPortalScreen extends StatefulWidget {
  const AdminPortalScreen({super.key});

  @override
  State<AdminPortalScreen> createState() => _AdminPortalScreenState();
}

class _AdminPortalScreenState extends State<AdminPortalScreen> {
  int _selectedIndex = 0;
  
  // Define screens and destinations dynamically based on permissions
  late List<Widget> _screens;
  late List<NavigationRailDestination> _destinations;

  @override
  void initState() {
    super.initState();
    _buildMenu();
  }

  void _buildMenu() {
    _screens = [
      const DashboardScreen(),
      const AttendanceManagementScreen(), // Everyone accesses, but actions restricted
      const StudentManagementScreen(),
      const FacultyManagementScreen(),
      const DepartmentManagementScreen(),
      const ProgramManagementScreen(),
      const CourseManagementScreen(),
    ];

    _destinations = [
      const NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Dashboard')),
      const NavigationRailDestination(icon: Icon(Icons.access_time_outlined), selectedIcon: Icon(Icons.access_time_filled), label: Text('Attendance')),
      const NavigationRailDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: Text('Students')),
      const NavigationRailDestination(icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school), label: Text('Faculty')),
      const NavigationRailDestination(icon: Icon(Icons.business_outlined), selectedIcon: Icon(Icons.business), label: Text('Depts')),
      const NavigationRailDestination(icon: Icon(Icons.layers_outlined), selectedIcon: Icon(Icons.layers), label: Text('Programs')),
      const NavigationRailDestination(icon: Icon(Icons.book_outlined), selectedIcon: Icon(Icons.book), label: Text('Courses')),
    ];

    if (ApiService.isSuperAdmin) {
      _screens.add(const ManageAdminsScreen());
      _destinations.add(const NavigationRailDestination(
        icon: Icon(Icons.admin_panel_settings_outlined), 
        selectedIcon: Icon(Icons.admin_panel_settings), 
        label: Text('Admins')
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: MediaQuery.of(context).size.width > 900,
            destinations: _destinations,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (idx) {
              setState(() {
                _selectedIndex = idx;
              });
            },
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
    );
  }
}
