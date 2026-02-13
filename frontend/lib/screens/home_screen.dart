import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'registration_screen.dart';
import 'attendance_screen.dart';
import 'dashboard_screen.dart';
import '../services/api_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Veriface'),
        actions: [
          if (kIsWeb)
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DashboardScreen()),
                );
              },
              icon: const Icon(Icons.dashboard, color: Colors.indigo),
              label: const Text('MIS Dashboard', style: TextStyle(color: Colors.indigo)),
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
              const SizedBox(height: 48),
              _buildButton(
                context, 
                'Register Student', 
                Icons.person_add_outlined, 
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegistrationScreen())),
              ),
              const SizedBox(height: 16),
              _buildButton(
                context, 
                'Mark Attendance', 
                Icons.camera_alt_outlined, 
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AttendanceScreen())),
              ),
              const SizedBox(height: 16),
              if (!kIsWeb) // Only show report view on mobile if direct opening is supported
                _buildButton(
                  context, 
                  'View Reports', 
                  Icons.description_outlined, 
                  () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DashboardScreen())),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, String title, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(title),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18),
      ),
    );
  }
}
