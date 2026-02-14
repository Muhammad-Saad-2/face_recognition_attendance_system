import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'registration_screen.dart';
import 'attendance_screen.dart';
import 'dashboard_screen.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Veriface Attendance'),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            ),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.face_retouching_natural, size: 64, color: Colors.indigo),
              ),
              const SizedBox(height: 32),
              const Text(
                'Veriface',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Attendance Capture System',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 48),
              _buildButton(
                context, 
                'Mark Attendance', 
                Icons.camera_alt_rounded, 
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AttendanceScreen())),
                isPrimary: true,
              ),
              const SizedBox(height: 16),
              _buildButton(
                context, 
                'Register Student', 
                Icons.person_add_rounded, 
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegistrationScreen())),
              ),
              const SizedBox(height: 16),
              _buildButton(
                context, 
                'Recent Activity', 
                Icons.history_rounded, 
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DashboardScreen())),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, String title, IconData icon, VoidCallback onPressed, {bool isPrimary = false}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: isPrimary ? Colors.white : Colors.indigo),
      label: Text(title),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 20),
        backgroundColor: isPrimary ? Colors.indigo : Colors.white,
        foregroundColor: isPrimary ? Colors.white : Colors.indigo,
        side: isPrimary ? BorderSide.none : const BorderSide(color: Colors.indigo, width: 1.5),
        elevation: isPrimary ? 4 : 0,
      ),
    );
  }
}
