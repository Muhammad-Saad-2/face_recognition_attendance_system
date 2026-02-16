import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:image_picker/image_picker.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _rollNoController = TextEditingController(); // Sequence number part
  
  // Data
  List<dynamic> _programs = [];
  List<dynamic> _departments = [];
  bool _isLoadingData = true;

  // Selections
  String? _selectedProgramId;
  String? _selectedDepartmentId;
  String? _selectedYear;
  
  // Computed
  String _rollNoPrefix = "";

  // Camera
  List<XFile> _capturedImages = [];
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isSubmitting = false;

  final List<String> _years = List.generate(10, (index) => (2021 + index).toString());

  @override
  void initState() {
    super.initState();
    _fetchData();
    _initializeCamera();
  }

  Future<void> _fetchData() async {
    try {
      final futures = await Future.wait([
        ApiService().getPrograms(),
        ApiService().getDepartments(),
      ]);
      setState(() {
        _programs = futures[0] as List<dynamic>;
        _departments = futures[1] as List<dynamic>;
        _isLoadingData = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
        setState(() => _isLoadingData = false);
      }
    }
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    
    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    
    try {
      await _cameraController!.initialize();
      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (e) {
      debugPrint('Camera Error: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _nameController.dispose();
    _rollNoController.dispose();
    super.dispose();
  }

  void _onProgramChanged(String? programId) {
    if (programId == null) return;
    
    final program = _programs.firstWhere((p) => p['id'].toString() == programId);
    final String? deptUniqueId = program['department_id']?.toString();
    
    String? mappedDeptId;
    if (deptUniqueId != null) {
      try {
        final dept = _departments.firstWhere((d) => d['unique_id'] == deptUniqueId);
        mappedDeptId = dept['id'].toString();
      } catch (e) {
        // Department unique_id not found in fetched departments
        debugPrint("Department with unique_id $deptUniqueId not found");
      }
    }

    setState(() {
      _selectedProgramId = programId;
      _selectedDepartmentId = mappedDeptId;
      _updateRollNoPrefix();
    });
  }

  void _onYearChanged(String? year) {
    setState(() {
      _selectedYear = year;
      _updateRollNoPrefix();
    });
  }

  void _updateRollNoPrefix() {
    if (_selectedYear != null && _selectedProgramId != null) {
      final program = _programs.firstWhere((p) => p['id'].toString() == _selectedProgramId);
      final progCode = program['code'];
      _rollNoPrefix = "$_selectedYear-$progCode-";
    } else {
      _rollNoPrefix = "";
    }
  }

  Future<void> _captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (_capturedImages.length >= 5) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Max 5 images allowed')));
       return;
    }

    try {
      final file = await _cameraController!.takePicture();
      setState(() {
        _capturedImages.add(file);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error capturing: $e')));
    }
  }

  void _removeImage(int index) {
    setState(() {
      _capturedImages.removeAt(index);
    });
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
         if (_capturedImages.length >= 5) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Max 5 images allowed')));
            return;
         }
        setState(() {
          _capturedImages.add(image);
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_capturedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please capture at least one image')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final fullRollNo = _rollNoPrefix + _rollNoController.text.trim();
      final program = _programs.firstWhere((p) => p['id'].toString() == _selectedProgramId);

      await ApiService().registerStudent(
        name: _nameController.text.trim(),
        studentId: fullRollNo,
        program: program['name'], // Backward compatibility: sending name
        major: program['name'], // Using program name as major for now
        departmentId: _selectedDepartmentId != null ? int.parse(_selectedDepartmentId!) : null,
        images: _capturedImages,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration Successful!')));
        Navigator.pop(context);
      }
    } catch (e) {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registration Failed: $e')));
        }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enhanced Student Registration')),
      body: _isLoadingData 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Personal Info
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // 2. Academic Info
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedProgramId,
                            decoration: const InputDecoration(labelText: 'Program', border: OutlineInputBorder()),
                            items: _programs.map<DropdownMenuItem<String>>((p) {
                              return DropdownMenuItem(
                                value: p['id'].toString(),
                                child: Text("${p['code']} - ${p['name']}"),
                              );
                            }).toList(),
                            onChanged: _onProgramChanged,
                            validator: (v) => v == null ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedYear,
                            decoration: const InputDecoration(labelText: 'Enrolled Year', border: OutlineInputBorder()),
                            items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                            onChanged: _onYearChanged,
                            validator: (v) => v == null ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 3. Department (Read-only)
                    DropdownButtonFormField<String>(
                      value: _selectedDepartmentId,
                      decoration: const InputDecoration(labelText: 'Department (Auto-Selected)', border: OutlineInputBorder(), filled: true, fillColor: Colors.black12),
                      items: _departments.map<DropdownMenuItem<String>>((d) {
                        return DropdownMenuItem(value: d['id'].toString(), child: Text(d['name']));
                      }).toList(),
                      onChanged: null, // Read-only
                    ),
                    const SizedBox(height: 16),

                    // 4. Roll Number (Prefix + Input)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(4)),
                            color: Colors.grey.shade200,
                          ),
                          child: Text(_rollNoPrefix.isEmpty ? 'YYYY-PROG-' : _rollNoPrefix, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: _rollNoController,
                            decoration: const InputDecoration(
                              labelText: 'Sequence No (e.g. 055)', 
                              border: OutlineInputBorder(borderRadius: BorderRadius.horizontal(right: Radius.circular(4))),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 5. Face Capture
                    const Text('Face Capture (Min 3, Max 5)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (_isCameraInitialized) 
                      SizedBox(
                        height: 300,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CameraPreview(_cameraController!),
                        ),
                      )
                    else 
                      Container(height: 300, color: Colors.black12, child: const Center(child: Text('Camera initializing...'))),
                    
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _captureImage,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Capture'),
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Upload'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Captured Images Preview
                    if (_capturedImages.isNotEmpty)
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _capturedImages.length,
                          itemBuilder: (context, index) {
                            return FutureBuilder<Uint8List>(
                              future: _capturedImages[index].readAsBytes(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                                  return Stack(
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        width: 100,
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.blueAccent),
                                          image: DecorationImage(
                                            image: MemoryImage(snapshot.data!),
                                            fit: BoxFit.cover
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: InkWell(
                                          onTap: () => _removeImage(index),
                                          child: const CircleAvatar(radius: 12, backgroundColor: Colors.red, child: Icon(Icons.close, size: 16, color: Colors.white)),
                                        ),
                                      ),
                                    ],
                                  );
                                } else {
                                  return const SizedBox(width: 100, child: Center(child: CircularProgressIndicator()));
                                }
                              },
                            );
                          },
                        ),
                      ),
                    
                    const SizedBox(height: 32),
                    
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent, 
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSubmitting 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                        : const Text('COMPLETE REGISTRATION', style: TextStyle(fontSize: 18)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
