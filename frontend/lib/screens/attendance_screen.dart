import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    // Use front camera for attendance
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    _cameraController = CameraController(frontCamera, ResolutionPreset.high);
    await _cameraController!.initialize();
    if (mounted) setState(() => _isCameraInitialized = true);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _captureAndMarkAttendance() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final image = await _cameraController!.takePicture();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Processing attendance...')));

      final result = await ApiService().markAttendance(image);

      if (!mounted) return;
      
      // Show Success Dialog
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(children: [Icon(Icons.check_circle, color: Colors.green), SizedBox(width: 8), Text('Attendance Marked')]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Name: ${result['student_name'] ?? 'Unknown'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              Text('ID: ${result['student_id'] ?? '-'}'),
              Text('Time: ${result['timestamp'] ?? '-'}'),
              const SizedBox(height: 8),
              if (result['status'] != null)
                Text('Status: ${result['status']}', style: TextStyle(color: result['status'] == 'Present' ? Colors.green : Colors.orange, fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );

    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
           builder: (context) => AlertDialog(
            title: const Row(children: [Icon(Icons.error, color: Colors.red), SizedBox(width: 8), Text('Attendance Failed')]),
            content: Text(e.toString().replaceAll('Exception: ', '')),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mark Attendance')),
      body: Stack(
        children: [
          if (_isCameraInitialized) 
            SizedBox.expand(child: CameraPreview(_cameraController!))
          else 
            const Center(child: CircularProgressIndicator()),
          
          if (_isProcessing)
             Container(
               color: Colors.black54,
               child: const Center(child: CircularProgressIndicator(color: Colors.white)),
             ),

          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton.extended(
                onPressed: _isProcessing ? null : _captureAndMarkAttendance,
                label: const Text('Mark Attendance', style: TextStyle(fontSize: 16)),
                icon: const Icon(Icons.camera_alt),
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
