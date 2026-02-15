import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ManageAdminsScreen extends StatefulWidget {
  const ManageAdminsScreen({super.key});

  @override
  State<ManageAdminsScreen> createState() => _ManageAdminsScreenState();
}

class _ManageAdminsScreenState extends State<ManageAdminsScreen> {
  final _api = ApiService();
  late Future<List<dynamic>> _adminsFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _adminsFuture = _api.getAdmins();
    });
  }

  Future<void> _showAdminDialog({Map<String, dynamic>? admin}) async {
    final isEditing = admin != null;
    final usernameController = TextEditingController(text: admin?['username'] ?? '');
    final nameController = TextEditingController(text: admin?['full_name'] ?? '');
    final facultyIdController = TextEditingController(text: admin?['faculty_id'] ?? '');
    final emailController = TextEditingController(text: admin?['email'] ?? '');
    final passwordController = TextEditingController();

    String roleSource = 'Faculty'; // 'Faculty' or 'Manual'
    String? facultyName;

    // Permissions
    Map<String, bool> permissions = {
      'can_manage_students': false,
      'can_manage_faculty': false,
      'can_manage_courses': false,
      'can_manage_attendance': false,
      'can_manage_academic': false,
    };

    if (isEditing) {
      // In edit mode, we don't change source, just edit fields
      roleSource = 'Manual'; 
      try {
        final perms = await _api.getAdminPermissions(admin!['id']);
        permissions.forEach((key, _) {
          if (perms.containsKey(key)) {
            permissions[key] = perms[key];
          }
        });
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading permissions: $e')));
      }
    }

    if (!mounted) return;

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => Container(),
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: anim1,
            child: StatefulBuilder(
              builder: (context, setState) {
                
                Future<void> lookupFaculty(String id) async {
                  if (id.isEmpty) return;
                  try {
                    final faculty = await _api.getFacultyByFacultyId(id);
                    if (faculty != null) {
                      setState(() {
                        nameController.text = faculty['name'];
                        emailController.text = faculty['email'];
                        usernameController.text = faculty['faculty_id'] ?? id; // Use ID as username by default
                        facultyName = faculty['name'];
                      });
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Found: ${faculty['name']}')));
                    } else {
                       setState(() {
                        nameController.clear();
                        emailController.clear();
                        usernameController.clear();
                        facultyName = null;
                      });
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Faculty ID not found')));
                    }
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }

                return AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: Row(
                    children: [
                      Icon(isEditing ? Icons.edit : Icons.person_add, color: Colors.blueAccent),
                      const SizedBox(width: 12),
                      Text(isEditing ? 'Edit Administrator' : 'Add Administrator',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                    ],
                  ),
                  content: SizedBox(
                    width: 500,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isEditing) ...[
                             Row(
                              children: [
                                const Text("Role Source: ", style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(width: 10),
                                DropdownButton<String>(
                                  value: roleSource,
                                  items: ['Faculty', 'Manual'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      roleSource = val!;
                                      // Clear fields on switch
                                      if (roleSource == 'Faculty') {
                                        usernameController.clear();
                                        nameController.clear();
                                        emailController.clear();
                                      }
                                    });
                                  }
                                ),
                              ],
                             ),
                             const SizedBox(height: 16),
                          ],

                          if (roleSource == 'Faculty' && !isEditing) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: facultyIdController,
                                    decoration: InputDecoration(
                                      labelText: 'Faculty ID (e.g. FAC001)',
                                      prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      isDense: true,
                                      suffixIcon: IconButton(
                                        icon: const Icon(Icons.search),
                                        onPressed: () => lookupFaculty(facultyIdController.text),
                                      )
                                    ),
                                    onSubmitted: (val) => lookupFaculty(val),
                                  ),
                                ),
                              ],
                            ),
                             const SizedBox(height: 8),
                             if (facultyName != null) 
                               Text("Verified: $facultyName", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                             const SizedBox(height: 16),
                          ],

                          const Text('Personal Information',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const Divider(),
                          const SizedBox(height: 8),
                          
                          // Username (Auto-filled or Manual)
                          _buildTextField(usernameController, 'Username', Icons.alternate_email, 
                            enabled: roleSource == 'Manual' || isEditing), // Editable mainly in manual/edit
                          
                          const SizedBox(height: 12),
                          
                          // Full Name & Faculty ID Display
                          _buildTextField(nameController, 'Full Name', Icons.person_outline, 
                            enabled: roleSource == 'Manual' || isEditing),
                          
                          if (roleSource == 'Manual' || isEditing) ...[
                             const SizedBox(height: 12),
                             _buildTextField(facultyIdController, 'Faculty ID (Optional)', Icons.badge_outlined),
                          ],

                          const SizedBox(height: 12),
                          _buildTextField(emailController, 'Email Address', Icons.email_outlined,
                             enabled: roleSource == 'Manual' || isEditing),
                            
                          const SizedBox(height: 12),
                          _buildTextField(
                            passwordController,
                            isEditing ? 'Password (leave blank to keep)' : 'Password',
                            Icons.lock_outline,
                            isPassword: true,
                          ),
                          const SizedBox(height: 24),
                          const Text('System Permissions',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const Divider(),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: permissions.keys.map((key) {
                              final label = key.replaceAll('can_manage_', '').replaceAll('_', ' ').toUpperCase();
                              final isSelected = permissions[key]!;
                              return FilterChip(
                                label: Text(label, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.black87)),
                                selected: isSelected,
                                onSelected: (val) => setState(() => permissions[key] = val),
                                selectedColor: Colors.blueAccent,
                                showCheckmark: false,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        try {
                          final data = {
                            'username': usernameController.text,
                            'full_name': nameController.text,
                            'faculty_id': facultyIdController.text,
                            'email': emailController.text,
                            if (passwordController.text.isNotEmpty) 'password': passwordController.text,
                            'is_active': true,
                          };

                          final permData = Map<String, bool>.from(permissions);

                          if (isEditing) {
                            await _api.updateAdmin(admin!['id'], {'user_in': data, 'permissions': permData});
                          } else {
                            await _api.createAdmin({'user_in': data, 'permissions': permData});
                          }
                          if (mounted) {
                            Navigator.pop(context);
                            _refresh();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Administrator saved successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                      child: const Text('Save Admin'),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPassword = false, bool enabled = true}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        isDense: true,
        filled: !enabled,
        fillColor: !enabled ? Colors.grey.shade200 : null,
      ),
    );
  }

  Future<void> _deleteAdmin(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Administrator'),
        content: const Text('Are you sure you want to remove this administrator? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _api.deleteAdmin(id);
        _refresh();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admin deleted')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  const Text('System Administrators', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
                  Text('Manage admin accounts and their system permissions', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () => _showAdminDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add Administrator', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: FutureBuilder<List<dynamic>>(
                  future: _adminsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                    if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('No admins found.'));

                    final admins = snapshot.data!;
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
                          columnSpacing: 60,
                          columns: const [
                            DataColumn(label: Text('USERNAME', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('FULL NAME', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('FACULTY ID', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('ROLE', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('ACTIONS', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: admins.map((admin) {
                            return DataRow(
                              cells: [
                                DataCell(Text(admin['username'], style: const TextStyle(fontWeight: FontWeight.w500))),
                                DataCell(Text(admin['full_name'] ?? '-')),
                                DataCell(Text(admin['faculty_id'] ?? '-')),
                                DataCell(Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: admin['is_super_admin'] ? Colors.purple[50] : Colors.blue[50],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    admin['is_super_admin'] ? 'Super Admin' : 'Admin',
                                    style: TextStyle(color: admin['is_super_admin'] ? Colors.purple : Colors.blue, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                )),
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        tooltip: 'Edit',
                                        icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                                        onPressed: () => _showAdminDialog(admin: admin),
                                      ),
                                      IconButton(
                                        tooltip: 'Delete',
                                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                        onPressed: admin['is_super_admin'] ? null : () => _deleteAdmin(admin['id']),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
