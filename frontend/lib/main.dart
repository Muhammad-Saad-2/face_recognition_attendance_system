import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('Error fetching cameras: $e');
    cameras = [];
  }
  runApp(const VerifaceApp());
}

class VerifaceApp extends StatelessWidget {
  const VerifaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Veriface',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.cyanAccent,
        scaffoldBackgroundColor: const Color(0xFF050510),
        colorScheme: const ColorScheme.dark(
          primary: Colors.cyanAccent,
          secondary: Colors.purpleAccent,
          surface: Color(0xFF101020),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto', // Default, can be changed if fonts are added
      ),
      home: const HomeScreen(),
    );
  }
}

// --- Custom Widgets ---

class BackgroundScaffold extends StatelessWidget {
  final Widget body;
  final AppBar? appBar;

  const BackgroundScaffold({super.key, required this.body, this.appBar});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: appBar != null
          ? AppBar(
              title: appBar!.title,
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: const TextStyle(
                color: Colors.cyanAccent,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(blurRadius: 10, color: Colors.cyan, offset: Offset(0, 0))
                ],
              ),
              iconTheme: const IconThemeData(color: Colors.white),
            )
          : null,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF050510),
              Color(0xFF100520),
              Color(0xFF001020),
            ],
          ),
        ),
        child: Stack(
          children: [
            // "Sparking" effect (simple glowing orbs)
            Positioned(
              top: -50,
              left: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.purpleAccent.withOpacity(0.2),
                  boxShadow: [
                    BoxShadow(blurRadius: 100, color: Colors.purpleAccent.withOpacity(0.3))
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.cyanAccent.withOpacity(0.2),
                  boxShadow: [
                    BoxShadow(blurRadius: 100, color: Colors.cyanAccent.withOpacity(0.3))
                  ],
                ),
              ),
            ),
            SafeArea(child: body),
          ],
        ),
      ),
    );
  }
}

class GlowButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final IconData? icon;
  final Color color;

  const GlowButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.icon,
    this.color = Colors.cyanAccent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black.withOpacity(0.6),
          foregroundColor: color,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: BorderSide(color: color.withOpacity(0.8), width: 2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon), const SizedBox(width: 10)],
            Text(
              text,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(blurRadius: 10, color: color, offset: const Offset(0, 0))
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;

  const GlassTextField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.cyanAccent),
          ),
        ),
        validator: validator,
      ),
    );
  }
}

// --- Screens ---

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BackgroundScaffold(
      body: Stack(
        children: [
          // Show Attendance Button (Top Right)
          Positioned(
            top: 20,
            right: 20,
            child: GlowButton(
              onPressed: () async {
                try {
                  final api = ApiService();
                  await api.downloadAttendance();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Attendance Report Downloaded!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              text: 'Show Attendance',
              icon: Icons.table_chart,
              color: Colors.purpleAccent,
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyanAccent.withOpacity(0.5),
                        blurRadius: 50,
                        spreadRadius: 10,
                      )
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/app_Logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (c, o, s) => const Icon(Icons.face, size: 80, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // Title
                const Text(
                  'VERIFACE',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 5,
                    shadows: [
                      Shadow(blurRadius: 20, color: Colors.cyanAccent, offset: Offset(0, 0)),
                      Shadow(blurRadius: 40, color: Colors.blueAccent, offset: Offset(0, 0)),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
                // Buttons
                GlowButton(
                  onPressed: () {
                    if (cameras.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegistrationScreen()),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No camera available')),
                      );
                    }
                  },
                  text: 'Register Student',
                  icon: Icons.person_add,
                ),
                const SizedBox(height: 30),
                GlowButton(
                  onPressed: () {
                    if (cameras.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AttendanceScreen()),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No camera available')),
                      );
                    }
                  },
                  text: 'Mark Attendance',
                  icon: Icons.camera_alt,
                  color: Colors.greenAccent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _programController = TextEditingController();
  final _majorController = TextEditingController();
  
  List<XFile> _capturedImages = [];
  late CameraController _cameraController;
  bool _isCameraInitialized = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await _cameraController.initialize();
    if (mounted) {
      setState(() {
        _isCameraInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _nameController.dispose();
    _idController.dispose();
    _programController.dispose();
    _majorController.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    if (!_isCameraInitialized) return;
    try {
      final image = await _cameraController.takePicture();
      setState(() {
        _capturedImages.add(image);
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;
    if (_capturedImages.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please capture at least 3 photos')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final api = ApiService();
      final response = await api.registerStudent(
        name: _nameController.text,
        studentId: _idController.text,
        program: _programController.text,
        major: _majorController.text,
        images: _capturedImages,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Registration successful')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundScaffold(
      appBar: AppBar(title: const Text('Register Student')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlassTextField(
                controller: _nameController,
                label: 'Full Name',
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              GlassTextField(
                controller: _idController,
                label: 'Student ID',
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              GlassTextField(
                controller: _programController,
                label: 'Program',
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              GlassTextField(
                controller: _majorController,
                label: 'Major',
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              const Text('Capture Photos (Min 3)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
              const SizedBox(height: 10),
              if (_isCameraInitialized)
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.cyanAccent, width: 2),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.2), blurRadius: 10)],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CameraPreview(_cameraController),
                  ),
                )
              else
                const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 10),
              Center(
                child: GlowButton(
                  onPressed: _captureImage,
                  text: 'Capture Photo',
                  icon: Icons.camera,
                  color: Colors.purpleAccent,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _capturedImages.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white54),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(File(_capturedImages[index].path), width: 100, height: 100, fit: BoxFit.cover),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _capturedImages.removeAt(index);
                                });
                              },
                              child: Container(
                                color: Colors.black54,
                                child: const Icon(Icons.close, color: Colors.red),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),
              _isSubmitting
                  ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
                  : GlowButton(
                      onPressed: _submitRegistration,
                      text: 'Register',
                      icon: Icons.check_circle,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late CameraController _cameraController;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  XFile? _capturedImage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );
    await _cameraController.initialize();
    if (mounted) {
      setState(() {
        _isCameraInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> _captureAndMarkAttendance() async {
    if (!_isCameraInitialized) return;
    
    try {
      final image = await _cameraController.takePicture();
      setState(() {
        _capturedImage = image;
        _isProcessing = true;
      });

      final api = ApiService();
      final response = await api.markAttendance(image);

      if (mounted) {
        _showResultDialog(response);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showResultDialog(Map<String, dynamic> response) {
    final recognizedCount = response['recognized_count'];
    final students = response['students'] as List<dynamic>;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF101020),
        title: Text('Attendance Marked ($recognizedCount)', style: const TextStyle(color: Colors.cyanAccent)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: students.length,
            itemBuilder: (context, index) {
              final s = students[index];
              return ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.greenAccent),
                title: Text(s['name'], style: const TextStyle(color: Colors.white)),
                subtitle: Text('${s['student_id']} - ${s['program']}', style: const TextStyle(color: Colors.white70)),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _capturedImage = null;
              });
            },
            child: const Text('OK', style: TextStyle(color: Colors.cyanAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundScaffold(
      appBar: AppBar(title: const Text('Mark Attendance')),
      body: Column(
        children: [
          if (_isCameraInitialized)
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.cyanAccent, width: 2),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.2), blurRadius: 20)],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: _capturedImage == null
                      ? CameraPreview(_cameraController)
                      : Image.file(File(_capturedImage!.path), fit: BoxFit.cover),
                ),
              ),
            )
          else
            const Expanded(child: Center(child: CircularProgressIndicator())),
          
          Padding(
            padding: const EdgeInsets.all(30),
            child: SizedBox(
              width: double.infinity,
              child: _isProcessing
                  ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
                  : GlowButton(
                      onPressed: _captureAndMarkAttendance,
                      text: 'Capture & Mark',
                      icon: Icons.camera_enhance,
                      color: Colors.greenAccent,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
