import 'package:flutter/material.dart';
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
  int _mobileSelectedIndex = 0;

  // Desktop screens include the Dashboard tab; mobile does not.
  late List<Widget> _desktopScreens;
  late List<_NavItem> _desktopNavItems;
  late List<Widget> _mobileScreens;
  late List<_NavItem> _mobileNavItems;

  @override
  void initState() {
    super.initState();
    _buildMenu();
  }

  void _buildMenu() {
    // ── Desktop (web MIS) — includes Dashboard ──
    _desktopScreens = [
      const DashboardScreen(),
      const AttendanceManagementScreen(),
      const StudentManagementScreen(),
      const FacultyManagementScreen(),
      const DepartmentManagementScreen(),
      const ProgramManagementScreen(),
      const CourseManagementScreen(),
    ];
    _desktopNavItems = [
      _NavItem(icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard, label: 'Dashboard'),
      _NavItem(icon: Icons.access_time_outlined, selectedIcon: Icons.access_time_filled, label: 'Attendance'),
      _NavItem(icon: Icons.people_outline, selectedIcon: Icons.people, label: 'Students'),
      _NavItem(icon: Icons.school_outlined, selectedIcon: Icons.school, label: 'Faculty'),
      _NavItem(icon: Icons.business_outlined, selectedIcon: Icons.business, label: 'Depts'),
      _NavItem(icon: Icons.layers_outlined, selectedIcon: Icons.layers, label: 'Programs'),
      _NavItem(icon: Icons.book_outlined, selectedIcon: Icons.book, label: 'Courses'),
    ];

    // ── Mobile (Android) — NO Dashboard tab ──
    _mobileScreens = [
      const AttendanceManagementScreen(),
      const StudentManagementScreen(),
      const FacultyManagementScreen(),
      const DepartmentManagementScreen(),
      const ProgramManagementScreen(),
      const CourseManagementScreen(),
    ];
    _mobileNavItems = [
      _NavItem(icon: Icons.access_time_outlined, selectedIcon: Icons.access_time_filled, label: 'Attendance'),
      _NavItem(icon: Icons.people_outline, selectedIcon: Icons.people, label: 'Students'),
      _NavItem(icon: Icons.school_outlined, selectedIcon: Icons.school, label: 'Faculty'),
      _NavItem(icon: Icons.business_outlined, selectedIcon: Icons.business, label: 'Depts'),
      _NavItem(icon: Icons.layers_outlined, selectedIcon: Icons.layers, label: 'Programs'),
      _NavItem(icon: Icons.book_outlined, selectedIcon: Icons.book, label: 'Courses'),
    ];

    if (ApiService.hasPermission('can_manage_students')) {
      final screen = const RegistrationScreen();
      final item = _NavItem(icon: Icons.person_add_outlined, selectedIcon: Icons.person_add, label: 'Register');
      _desktopScreens.add(screen);
      _desktopNavItems.add(item);
      _mobileScreens.add(screen);
      _mobileNavItems.add(item);
    }

    if (ApiService.isSuperAdmin) {
      final screen = const ManageAdminsScreen();
      final item = _NavItem(icon: Icons.admin_panel_settings_outlined, selectedIcon: Icons.admin_panel_settings, label: 'Admins');
      _desktopScreens.add(screen);
      _desktopNavItems.add(item);
      _mobileScreens.add(screen);
      _mobileNavItems.add(item);
    }
  }

  void _logout() {
    ApiService.setToken('');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Widget _buildHeader(bool isMobile) {
    final user = ApiService.currentUser;
    final userName = user?['full_name'] ?? user?['username'] ?? 'Admin';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: isMobile ? 10 : 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: isMobile ? 14 : 16,
                    backgroundColor: Colors.blueAccent.shade100,
                    child: Icon(Icons.person, color: Colors.blueAccent.shade700, size: isMobile ? 16 : 18),
                  ),
                  if (!isMobile) ...[
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        userName,
                        style: TextStyle(color: Colors.grey.shade800, fontSize: 15, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(height: 24, width: 1, color: Colors.grey.shade300),
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
                  ] else ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _logout,
                      icon: Icon(Icons.logout, color: Colors.red.shade700, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;

        if (isMobile) {
          // ── Mobile layout: BottomNavigationBar (no Dashboard tab) ──
          return Scaffold(
            body: Column(
              children: [
                _buildHeader(true),
                Expanded(child: _mobileScreens[_mobileSelectedIndex]),
              ],
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _mobileSelectedIndex,
              onTap: (idx) => setState(() => _mobileSelectedIndex = idx),
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Colors.indigo,
              unselectedItemColor: Colors.grey,
              selectedFontSize: 10,
              unselectedFontSize: 10,
              iconSize: 22,
              items: _mobileNavItems.map((item) => BottomNavigationBarItem(
                icon: Icon(item.icon),
                activeIcon: Icon(item.selectedIcon),
                label: item.label,
              )).toList(),
            ),
          );
        }

        // ── Desktop/Tablet layout: NavigationRail (with Dashboard tab) ──
        return Scaffold(
          body: Column(
            children: [
              _buildHeader(false),
              Expanded(
                child: Row(
                  children: [
                    NavigationRail(
                      extended: constraints.maxWidth > 1100,
                      destinations: _desktopNavItems.map((item) => NavigationRailDestination(
                        icon: Icon(item.icon),
                        selectedIcon: Icon(item.selectedIcon),
                        label: Text(item.label),
                      )).toList(),
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
                    ),
                    const VerticalDivider(thickness: 1, width: 1),
                    Expanded(child: _desktopScreens[_selectedIndex]),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _NavItem({required this.icon, required this.selectedIcon, required this.label});
}
