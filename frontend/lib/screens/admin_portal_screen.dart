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
import 'registration_screen.dart';
import 'login_screen.dart';

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

    if (ApiService.hasPermission('can_manage_students')) {
       _screens.add(const RegistrationScreen());
       _destinations.add(const NavigationRailDestination(
         icon: Icon(Icons.person_add_outlined), 
         selectedIcon: Icon(Icons.person_add), 
         label: Text('Register')
       ));
    }

    if (ApiService.isSuperAdmin) {
      _screens.add(const ManageAdminsScreen());
      _destinations.add(const NavigationRailDestination(
        icon: Icon(Icons.admin_panel_settings_outlined), 
        selectedIcon: Icon(Icons.admin_panel_settings), 
        label: Text('Admins')
      ));
    }
  }

  void _logout() {
    ApiService.setToken(''); // Clear token (mock)
    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(builder: (_) => const LoginScreen())
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiService.currentUser;
    final userName = user?['full_name'] ?? user?['username'] ?? 'Admin';

    return Scaffold(
      body: Column(
        children: [
          // Header - Light theme with user info on right
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // User info on the right
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.blueAccent.shade100,
                        child: Icon(Icons.person, color: Colors.blueAccent.shade700, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        userName,
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        height: 24,
                        width: 1,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: _logout,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text('Logout', style: TextStyle(fontSize: 14)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Main Content
          Expanded(
            child: Row(
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
          ),
        ],
      ),
    );
  }
}
