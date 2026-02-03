import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  final List<String> _pageTitles = [
    'Dashboard',
    'Manage Colleges',
    'Manage Students',
    'System Settings',
  ];

  @override
  Widget build(BuildContext context) {
    final supabaseService = Provider.of<SupabaseService>(context);
    final currentUser = supabaseService.getCurrentUser();

    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitles[_selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: _showNotifications,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _logout(context);
              } else if (value == 'profile') {
                _showProfile(currentUser);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Profile'),
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Logout', style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
        ],
      ),
      drawer: _buildDrawer(currentUser),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const DashboardHome(),
          CollegesManagement(),
          StudentsManagement(),
          const SettingsPage(),
        ],
      ),
      floatingActionButton: _getFloatingActionButton(),
    );
  }

  Widget _buildDrawer(User? user) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 30,
                  child: Text(
                    user?.email?.substring(0, 1).toUpperCase() ?? 'A',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  user?.email ?? 'Admin',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const Text(
                  'Administrator',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          _buildDrawerItem(Icons.dashboard, 'Dashboard', 0),
          _buildDrawerItem(Icons.school, 'Colleges', 1),
          _buildDrawerItem(Icons.people, 'Students', 2),
          _buildDrawerItem(Icons.settings, 'Settings', 3),
          const Divider(),
          _buildDrawerItem(Icons.help, 'Help', 4),
          _buildDrawerItem(Icons.info, 'About', 5),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: _selectedIndex == index,
      onTap: () {
        setState(() => _selectedIndex = index);
        Navigator.pop(context);
      },
    );
  }

  Widget? _getFloatingActionButton() {
    switch (_selectedIndex) {
      case 1: // Colleges
        return FloatingActionButton(
          onPressed: () => _showAddCollegeDialog(),
          child: const Icon(Icons.add),
        );
      case 2: // Students
        return FloatingActionButton(
          onPressed: () => _showAddStudentDialog(),
          child: const Icon(Icons.person_add),
        );
      default:
        return null;
    }
  }

  void _showAddCollegeDialog() {
    showDialog(
      context: context,
      builder: (context) => CollegeFormDialog(
        onSave: (collegeData) async {
          try {
            final supabaseService = Provider.of<SupabaseService>(
              context,
              listen: false,
            );
            await supabaseService.addCollege(collegeData);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('College added successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            setState(() {});
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
            );
          }
        },
      ),
    );
  }

  void _showAddStudentDialog() {
    showDialog(
      context: context,
      builder: (context) => StudentFormDialog(
        onSave: (studentData) async {
          try {
            final supabaseService = Provider.of<SupabaseService>(
              context,
              listen: false,
            );
            await supabaseService.addStudent(studentData);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Student added successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            setState(() {});
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
            );
          }
        },
      ),
    );
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.person_add, color: Colors.blue),
              title: Text('New Student Registered'),
              subtitle: Text('John Doe registered today'),
            ),
            ListTile(
              leading: Icon(Icons.school, color: Colors.green),
              title: Text('College Added'),
              subtitle: Text('MIT added to system'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showProfile(User? user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Admin Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${user?.email ?? 'Not available'}'),
            Text('User ID: ${user?.id ?? 'Not available'}'),
            Text(
              'Last Login: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      final supabaseService = Provider.of<SupabaseService>(
        context,
        listen: false,
      );
      await supabaseService.adminLogout();
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/admin-login',
        (route) => false,
      );
    }
  }
}

// ========== Dashboard Home ==========
class DashboardHome extends StatelessWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: Provider.of<SupabaseService>(
        context,
        listen: false,
      ).getStatistics(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final stats = snapshot.data ?? {'users': 0, 'colleges': 0, 'tests': 0};

        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'System Overview',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                'Today: ${DateFormat('EEEE, MMMM d').format(DateTime.now())}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 30),

              // Statistics Cards
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.5,
                children: [
                  _buildStatCard(
                    'Total Users',
                    '${stats['users']}',
                    Colors.blue,
                    Icons.people,
                  ),
                  _buildStatCard(
                    'Colleges',
                    '${stats['colleges']}',
                    Colors.green,
                    Icons.school,
                  ),
                  _buildStatCard(
                    'Tests Created',
                    '${stats['tests']}',
                    Colors.orange,
                    Icons.assignment,
                  ),
                  _buildStatCard(
                    'Revenue',
                    '\$12,450',
                    Colors.purple,
                    Icons.attach_money,
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Quick Actions
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildActionButton(
                    icon: Icons.school,
                    label: 'Add College',
                    onTap: () {
                      final adminState = context
                          .findAncestorStateOfType<_AdminDashboardState>();
                      adminState?._showAddCollegeDialog();
                    },
                    color: Colors.blue,
                  ),
                  _buildActionButton(
                    icon: Icons.person_add,
                    label: 'Add Student',
                    onTap: () {
                      final adminState = context
                          .findAncestorStateOfType<_AdminDashboardState>();
                      adminState?._showAddStudentDialog();
                    },
                    color: Colors.green,
                  ),
                  _buildActionButton(
                    icon: Icons.bar_chart,
                    label: 'View Reports',
                    onTap: () {},
                    color: Colors.purple,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildStatCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ========== Colleges Management ==========
class CollegesManagement extends StatefulWidget {
  @override
  State<CollegesManagement> createState() => _CollegesManagementState();
}

class _CollegesManagementState extends State<CollegesManagement> {
  List<Map<String, dynamic>> _colleges = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadColleges();
  }

  Future<void> _loadColleges() async {
    try {
      final supabaseService = Provider.of<SupabaseService>(
        context,
        listen: false,
      );
      final colleges = await supabaseService.getColleges();
      setState(() {
        _colleges = colleges;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading colleges: $e')));
    }
  }

  Future<void> _deleteCollege(String id, String name) async {
    final shouldDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete College'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        final supabaseService = Provider.of<SupabaseService>(
          context,
          listen: false,
        );
        await supabaseService.deleteCollege(id);
        await _loadColleges();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('College deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting college: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Manage Colleges',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search colleges...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: (value) {
              // Implement search
            },
          ),
          const SizedBox(height: 20),

          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_colleges.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'No colleges found. Add your first college!',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _colleges.length,
                itemBuilder: (context, index) {
                  final college = _colleges[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 15),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: const Icon(Icons.school, color: Colors.blue),
                      ),
                      title: Text(college['name'] ?? 'Unknown'),
                      subtitle: Text(college['location'] ?? 'No location'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editCollege(college),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteCollege(
                              college['id'].toString(),
                              college['name'] ?? 'College',
                            ),
                          ),
                        ],
                      ),
                      onTap: () => _viewCollegeDetails(college),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _viewCollegeDetails(Map<String, dynamic> college) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(college['name'] ?? 'College Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailItem('Name', college['name']),
              _buildDetailItem('Location', college['location']),
              _buildDetailItem('Email', college['email']),
              _buildDetailItem('Phone', college['phone']),
              _buildDetailItem('Description', college['description']),
              _buildDetailItem(
                'Created',
                college['created_at'] != null
                    ? DateFormat(
                        'yyyy-MM-dd',
                      ).format(DateTime.parse(college['created_at']))
                    : 'Unknown',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () => _editCollege(college),
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value ?? 'Not specified')),
        ],
      ),
    );
  }

  void _editCollege(Map<String, dynamic> college) {
    showDialog(
      context: context,
      builder: (context) => CollegeFormDialog(
        college: college,
        onSave: (updatedData) async {
          try {
            final supabaseService = Provider.of<SupabaseService>(
              context,
              listen: false,
            );
            await supabaseService.updateCollege(
              college['id'].toString(),
              updatedData,
            );
            Navigator.pop(context);
            await _loadColleges();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('College updated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error updating college: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }
}

// ========== Students Management ==========
class StudentsManagement extends StatefulWidget {
  @override
  State<StudentsManagement> createState() => _StudentsManagementState();
}

class _StudentsManagementState extends State<StudentsManagement> {
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    try {
      final supabaseService = Provider.of<SupabaseService>(
        context,
        listen: false,
      );
      final students = await supabaseService.getStudents();
      setState(() {
        _students = students;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading students: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Manage Students',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search students...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),

          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_students.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'No students found. Add your first student!',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _students.length,
                itemBuilder: (context, index) {
                  final student = _students[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 15),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green.shade100,
                        child: const Icon(Icons.person, color: Colors.green),
                      ),
                      title: Text(student['full_name'] ?? 'Unknown'),
                      subtitle: Text(student['email'] ?? 'No email'),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editStudent(student),
                      ),
                      onTap: () => _viewStudentDetails(student),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _viewStudentDetails(Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(student['full_name'] ?? 'Student Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailItem('Full Name', student['full_name']),
              _buildDetailItem('Email', student['email']),
              _buildDetailItem('Phone', student['phone']),
              _buildDetailItem('Address', student['address']),
              _buildDetailItem('Date of Birth', student['date_of_birth']),
              _buildDetailItem('Gender', student['gender']),
              _buildDetailItem('Education', student['education']),
              _buildDetailItem(
                'Created',
                student['created_at'] != null
                    ? DateFormat(
                        'yyyy-MM-dd',
                      ).format(DateTime.parse(student['created_at']))
                    : 'Unknown',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value ?? 'Not specified')),
        ],
      ),
    );
  }

  void _editStudent(Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (context) => StudentFormDialog(
        student: student,
        onSave: (updatedData) async {
          try {
            final supabaseService = Provider.of<SupabaseService>(
              context,
              listen: false,
            );
            await supabaseService.updateStudent(
              student['id'].toString(),
              updatedData,
            );
            Navigator.pop(context);
            await _loadStudents();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Student updated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error updating student: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }
}

// ========== Settings Page ==========
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: ListView(
        children: [
          const Text(
            'System Settings',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('Notification Settings'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.security),
                  title: const Text('Security Settings'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.email),
                  title: const Text('Email Configuration'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.backup),
                  title: const Text('Backup & Restore'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('About System'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ========== FORM DIALOGS ==========

// College Form Dialog
class CollegeFormDialog extends StatefulWidget {
  final Map<String, dynamic>? college;
  final Function(Map<String, dynamic>) onSave;

  const CollegeFormDialog({super.key, this.college, required this.onSave});

  @override
  State<CollegeFormDialog> createState() => _CollegeFormDialogState();
}

class _CollegeFormDialogState extends State<CollegeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.college != null) {
      _nameController.text = widget.college!['name'] ?? '';
      _locationController.text = widget.college!['location'] ?? '';
      _emailController.text = widget.college!['email'] ?? '';
      _phoneController.text = widget.college!['phone'] ?? '';
      _descriptionController.text = widget.college!['description'] ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.college == null ? 'Add College' : 'Edit College'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'College Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'College name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Location is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email is required';
                  }
                  if (!value.contains('@')) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _saveCollege, child: const Text('Save')),
      ],
    );
  }

  void _saveCollege() {
    if (_formKey.currentState!.validate()) {
      final collegeData = {
        'name': _nameController.text.trim(),
        'location': _locationController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'description': _descriptionController.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
      };

      widget.onSave(collegeData);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

// Student Form Dialog
class StudentFormDialog extends StatefulWidget {
  final Map<String, dynamic>? student;
  final Function(Map<String, dynamic>) onSave;

  const StudentFormDialog({super.key, this.student, required this.onSave});

  @override
  State<StudentFormDialog> createState() => _StudentFormDialogState();
}

class _StudentFormDialogState extends State<StudentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _dobController = TextEditingController();
  String _gender = 'Male';
  final _educationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.student != null) {
      _nameController.text = widget.student!['full_name'] ?? '';
      _emailController.text = widget.student!['email'] ?? '';
      _phoneController.text = widget.student!['phone'] ?? '';
      _addressController.text = widget.student!['address'] ?? '';
      _dobController.text = widget.student!['date_of_birth'] ?? '';
      _gender = widget.student!['gender'] ?? 'Male';
      _educationController.text = widget.student!['education'] ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.student == null ? 'Add Student' : 'Edit Student'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email is required';
                  }
                  if (!value.contains('@')) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _dobController,
                decoration: const InputDecoration(
                  labelText: 'Date of Birth (YYYY-MM-DD)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(),
                ),
                items: ['Male', 'Female', 'Other']
                    .map(
                      (gender) =>
                          DropdownMenuItem(value: gender, child: Text(gender)),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _gender = value!;
                  });
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _educationController,
                decoration: const InputDecoration(
                  labelText: 'Education',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _saveStudent, child: const Text('Save')),
      ],
    );
  }

  void _saveStudent() {
    if (_formKey.currentState!.validate()) {
      final studentData = {
        'full_name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'date_of_birth': _dobController.text.trim(),
        'gender': _gender,
        'education': _educationController.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
      };

      widget.onSave(studentData);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _dobController.dispose();
    _educationController.dispose();
    super.dispose();
  }
}
