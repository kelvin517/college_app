import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class CollegeDashboard extends StatefulWidget {
  const CollegeDashboard({super.key});

  @override
  State<CollegeDashboard> createState() => _CollegeDashboardState();
}

class _CollegeDashboardState extends State<CollegeDashboard> {
  final supabase = Supabase.instance.client;
  late Future<Map<String, dynamic>> _dashboardData;
  int _currentIndex = 0;
  Map<String, dynamic>? _collegeProfile;
  bool _isLoading = false;

  // Data lists
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _attendance = [];
  List<Map<String, dynamic>> _applications = [];
  List<Map<String, dynamic>> _events = [];
  List<Map<String, dynamic>> _applicants = [];

  // Controllers for forms
  final TextEditingController _studentNameController = TextEditingController();
  final TextEditingController _studentEmailController = TextEditingController();
  final TextEditingController _studentRollController = TextEditingController();
  final TextEditingController _studentCourseController =
      TextEditingController();
  final TextEditingController _studentPhoneController = TextEditingController();

  final TextEditingController _courseNameController = TextEditingController();
  final TextEditingController _courseCodeController = TextEditingController();
  final TextEditingController _courseDurationController =
      TextEditingController();

  final TextEditingController _eventTitleController = TextEditingController();
  final TextEditingController _eventDescriptionController =
      TextEditingController();
  DateTime _selectedEventDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadCollegeProfile();
    _loadAllData();
  }

  @override
  void dispose() {
    // Dispose all controllers
    _studentNameController.dispose();
    _studentEmailController.dispose();
    _studentRollController.dispose();
    _studentCourseController.dispose();
    _studentPhoneController.dispose();
    _courseNameController.dispose();
    _courseCodeController.dispose();
    _courseDurationController.dispose();
    _eventTitleController.dispose();
    _eventDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadStudents(),
        _loadCourses(),
        _loadAttendance(),
        _loadApplications(),
        _loadEvents(),
        _loadApplicants(),
      ]);
      _dashboardData = _loadDashboardData();
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCollegeProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase
          .from('college_profiles')
          .select('*')
          .eq('admin_id', user.id)
          .maybeSingle();

      setState(() {
        _collegeProfile = response;
      });
    } catch (e) {
      print('Error loading college profile: $e');
    }
  }

  Future<Map<String, dynamic>> _loadDashboardData() async {
    try {
      final results = await Future.wait([
        _getTotalStudents(),
        _getTotalCourses(),
        _getTodayAttendance(),
        _getRecentApplications(),
        _getUpcomingEvents(),
      ]);

      return {
        'totalStudents': results[0],
        'totalCourses': results[1],
        'todayAttendance': results[2],
        'recentApplications': results[3],
        'upcomingEvents': results[4],
      };
    } catch (e) {
      print('Error loading dashboard data: $e');
      return {
        'totalStudents': _students.length,
        'totalCourses': _courses.length,
        'todayAttendance': _attendance,
        'recentApplications': _applications
            .where((a) => a['status'] == 'pending')
            .toList(),
        'upcomingEvents': _events,
      };
    }
  }

  Future<int> _getTotalStudents() async {
    return _students.length;
  }

  Future<int> _getTotalCourses() async {
    return _courses.length;
  }

  Future<List<dynamic>> _getTodayAttendance() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _attendance.where((a) => a['date'] == today).toList();
  }

  Future<List<dynamic>> _getRecentApplications() async {
    return _applications
        .where((a) => a['status'] == 'pending')
        .take(5)
        .toList();
  }

  Future<List<dynamic>> _getUpcomingEvents() async {
    final today = DateTime.now();
    return _events
        .where((e) {
          final eventDate = DateTime.parse(e['date']);
          return eventDate.isAfter(today) || eventDate.isAtSameMomentAs(today);
        })
        .take(5)
        .toList();
  }

  Future<void> _loadStudents() async {
    try {
      final response = await supabase
          .from('students')
          .select('*')
          .order('created_at', ascending: false);

      setState(() {
        _students = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('Error loading students: $e');
      // Mock data for testing
      setState(() {
        _students = [
          {
            'id': '1',
            'name': 'John Doe',
            'email': 'john@example.com',
            'roll_number': 'CS001',
            'course': 'Computer Science',
            'phone': '+1 234 567 890',
            'created_at': DateTime.now().toIso8601String(),
          },
          {
            'id': '2',
            'name': 'Jane Smith',
            'email': 'jane@example.com',
            'roll_number': 'CS002',
            'course': 'Computer Science',
            'phone': '+1 234 567 891',
            'created_at': DateTime.now().toIso8601String(),
          },
        ];
      });
    }
  }

  Future<void> _loadCourses() async {
    try {
      final response = await supabase
          .from('courses')
          .select('*')
          .order('created_at', ascending: false);

      setState(() {
        _courses = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('Error loading courses: $e');
      // Mock data for testing
      setState(() {
        _courses = [
          {
            'id': '1',
            'name': 'Computer Science',
            'code': 'CS101',
            'duration': '48',
            'created_at': DateTime.now().toIso8601String(),
          },
          {
            'id': '2',
            'name': 'Business Administration',
            'code': 'BA101',
            'duration': '36',
            'created_at': DateTime.now().toIso8601String(),
          },
        ];
      });
    }
  }

  Future<void> _loadAttendance() async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final response = await supabase
          .from('attendance')
          .select('*, student:students(name, roll_number)')
          .order('created_at', ascending: false);

      setState(() {
        _attendance = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('Error loading attendance: $e');
      // Mock data for testing
      setState(() {
        _attendance = [
          {
            'id': '1',
            'student_id': '1',
            'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
            'status': 'present',
            'student': {'name': 'John Doe', 'roll_number': 'CS001'},
          },
          {
            'id': '2',
            'student_id': '2',
            'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
            'status': 'absent',
            'student': {'name': 'Jane Smith', 'roll_number': 'CS002'},
          },
        ];
      });
    }
  }

  Future<void> _loadApplications() async {
    try {
      final response = await supabase
          .from('admission_applications')
          .select('*, applicant:applicants(name, email, phone)')
          .order('created_at', ascending: false);

      setState(() {
        _applications = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('Error loading applications: $e');
      // Mock data for testing
      setState(() {
        _applications = [
          {
            'id': '1',
            'applicant_id': '1',
            'course_id': '1',
            'status': 'pending',
            'created_at': DateTime.now().toIso8601String(),
            'applicant': {
              'name': 'Alice Johnson',
              'email': 'alice@example.com',
              'phone': '+1 234 567 892',
            },
          },
          {
            'id': '2',
            'applicant_id': '2',
            'course_id': '2',
            'status': 'pending',
            'created_at': DateTime.now()
                .subtract(const Duration(days: 1))
                .toIso8601String(),
            'applicant': {
              'name': 'Bob Williams',
              'email': 'bob@example.com',
              'phone': '+1 234 567 893',
            },
          },
        ];
      });
    }
  }

  Future<void> _loadEvents() async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final response = await supabase
          .from('events')
          .select('*')
          .gte('date', today)
          .order('date', ascending: true);

      setState(() {
        _events = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('Error loading events: $e');
      // Mock data for testing
      setState(() {
        _events = [
          {
            'id': '1',
            'title': 'Orientation Day',
            'description': 'Welcome new students',
            'date': DateTime.now()
                .add(const Duration(days: 7))
                .toIso8601String(),
          },
          {
            'id': '2',
            'title': 'Career Fair',
            'description': 'Meet potential employers',
            'date': DateTime.now()
                .add(const Duration(days: 14))
                .toIso8601String(),
          },
        ];
      });
    }
  }

  Future<void> _loadApplicants() async {
    try {
      final response = await supabase
          .from('applicants')
          .select('*')
          .order('created_at', ascending: false);

      setState(() {
        _applicants = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('Error loading applicants: $e');
    }
  }

  Future<void> logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await supabase.auth.signOut();
      if (!context.mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          _getAppBarTitle(),
          style: TextStyle(
            fontSize: isSmallScreen ? 18 : 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue.shade700,
        elevation: 2,
        centerTitle: false,
        actions: _buildAppBarActions(),
      ),
      drawer: _buildDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _currentIndex,
              children: [
                _buildDashboardView(),
                _buildStudentsView(),
                _buildCoursesView(),
                _buildAttendanceView(),
                _buildProfileView(),
              ],
            ),
      floatingActionButton: _getFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Students (${_students.length})';
      case 2:
        return 'Courses (${_courses.length})';
      case 3:
        return 'Attendance';
      case 4:
        return 'Profile';
      default:
        return 'College Dashboard';
    }
  }

  List<Widget> _buildAppBarActions() {
    return [
      IconButton(
        icon: Stack(
          children: [
            const Icon(Icons.notifications_outlined, color: Colors.white),
            if (_applications.where((a) => a['status'] == 'pending').isNotEmpty)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                ),
              ),
          ],
        ),
        onPressed: _showNotifications,
        tooltip: 'Notifications',
      ),
      IconButton(
        icon: const Icon(Icons.refresh, color: Colors.white),
        onPressed: () {
          setState(() {
            _loadAllData();
          });
        },
        tooltip: 'Refresh',
      ),
      IconButton(
        icon: const Icon(Icons.logout_outlined, color: Colors.white),
        onPressed: () => logout(context),
        tooltip: 'Logout',
      ),
    ];
  }

  Widget _buildDrawer() {
    final user = supabase.auth.currentUser;

    return Drawer(
      elevation: 4,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildDrawerHeader(user),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerMenuItem(
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                  index: 0,
                ),
                _buildDrawerMenuItem(
                  icon: Icons.people_outlined,
                  label: 'Students (${_students.length})',
                  index: 1,
                ),
                _buildDrawerMenuItem(
                  icon: Icons.book_outlined,
                  label: 'Courses (${_courses.length})',
                  index: 2,
                ),
                _buildDrawerMenuItem(
                  icon: Icons.checklist_outlined,
                  label: 'Attendance',
                  index: 3,
                ),
                _buildDrawerMenuItem(
                  icon: Icons.person_outlined,
                  label: 'Profile',
                  index: 4,
                ),
                const Divider(height: 24, thickness: 1),
                _buildDrawerMenuItem(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  onTap: _showSettings,
                ),
                _buildDrawerMenuItem(
                  icon: Icons.help_outlined,
                  label: 'Help & Support',
                  onTap: _showHelp,
                ),
              ],
            ),
          ),
          _buildDrawerFooter(user),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(User? user) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade700, Colors.blue.shade900],
        ),
        borderRadius: const BorderRadius.only(bottomRight: Radius.circular(20)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 30,
                  child: Text(
                    _collegeProfile?['name']
                            ?.toString()
                            .substring(0, 1)
                            .toUpperCase() ??
                        user?.email?.substring(0, 1).toUpperCase() ??
                        'C',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _collegeProfile?['name']?.toString() ?? 'College Name',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                user?.email ?? 'admin@college.edu',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerMenuItem({
    required IconData icon,
    required String label,
    int? index,
    VoidCallback? onTap,
  }) {
    final isSelected = index != null && _currentIndex == index;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.blue : Colors.grey.shade600,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.blue : Colors.grey.shade800,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 15,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onTap:
          onTap ??
          () {
            setState(() => _currentIndex = index!);
            Navigator.pop(context);
          },
    );
  }

  Widget _buildDrawerFooter(User? user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        color: Colors.white,
      ),
      child: SafeArea(
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            setState(() => _currentIndex = 4);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    user?.email?.substring(0, 1).toUpperCase() ?? 'C',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _collegeProfile?['name']?.toString() ?? 'College Admin',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'View Profile',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget? _getFloatingActionButton() {
    switch (_currentIndex) {
      case 1: // Students
        return FloatingActionButton.extended(
          onPressed: _showAddStudentDialog,
          icon: const Icon(Icons.person_add),
          label: const Text('Add Student'),
          backgroundColor: Colors.blue.shade700,
        );
      case 2: // Courses
        return FloatingActionButton.extended(
          onPressed: _showAddCourseDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add Course'),
          backgroundColor: Colors.green.shade700,
        );
      case 3: // Attendance
        return FloatingActionButton.extended(
          onPressed: _showMarkAttendanceDialog,
          icon: const Icon(Icons.check_circle),
          label: const Text('Mark Attendance'),
          backgroundColor: Colors.orange.shade700,
        );
      default:
        return null;
    }
  }

  // ============ DIALOGS ============
  void _showAddStudentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Student'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _studentNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _studentEmailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _studentRollController,
                decoration: const InputDecoration(
                  labelText: 'Roll Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Course',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.book),
                ),
                value: _courses.isNotEmpty
                    ? _courses[0]['id']?.toString()
                    : null,
                items: _courses.map<DropdownMenuItem<String>>((course) {
                  return DropdownMenuItem<String>(
                    value: course['id']?.toString(),
                    child: Text(course['name']?.toString() ?? 'Unknown'),
                  );
                }).toList(),
                onChanged: (String? value) {
                  _studentCourseController.text = value ?? '';
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _studentPhoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _clearStudentControllers();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(onPressed: _addStudent, child: const Text('Add')),
        ],
      ),
    );
  }

  void _clearStudentControllers() {
    _studentNameController.clear();
    _studentEmailController.clear();
    _studentRollController.clear();
    _studentCourseController.clear();
    _studentPhoneController.clear();
  }

  void _addStudent() {
    // Add student logic here
    final newStudent = {
      'id': DateTime.now().toString(),
      'name': _studentNameController.text,
      'email': _studentEmailController.text,
      'roll_number': _studentRollController.text,
      'course': _studentCourseController.text,
      'phone': _studentPhoneController.text,
      'created_at': DateTime.now().toIso8601String(),
    };

    setState(() {
      _students.insert(0, newStudent);
    });

    _clearStudentControllers();
    Navigator.pop(context);
    _showSnackBar('Student added successfully', Colors.green);
  }

  void _showAddCourseDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Course'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _courseNameController,
                decoration: const InputDecoration(
                  labelText: 'Course Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.book),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _courseCodeController,
                decoration: const InputDecoration(
                  labelText: 'Course Code',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.code),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _courseDurationController,
                decoration: const InputDecoration(
                  labelText: 'Duration (months)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.timer),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _courseNameController.clear();
              _courseCodeController.clear();
              _courseDurationController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(onPressed: _addCourse, child: const Text('Add')),
        ],
      ),
    );
  }

  void _addCourse() {
    final newCourse = {
      'id': DateTime.now().toString(),
      'name': _courseNameController.text,
      'code': _courseCodeController.text,
      'duration': _courseDurationController.text,
      'created_at': DateTime.now().toIso8601String(),
    };

    setState(() {
      _courses.insert(0, newCourse);
    });

    _courseNameController.clear();
    _courseCodeController.clear();
    _courseDurationController.clear();
    Navigator.pop(context);
    _showSnackBar('Course added successfully', Colors.green);
  }

  void _showMarkAttendanceDialog() {
    String? selectedCourse;
    DateTime selectedDate = DateTime.now();
    Map<String, String> attendanceStatus = {};

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Mark Attendance'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Select Course',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedCourse,
                  items: _courses.map<DropdownMenuItem<String>>((course) {
                    return DropdownMenuItem<String>(
                      value: course['id']?.toString() ?? '',
                      child: Text(course['name']?.toString() ?? 'Unknown'),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      selectedCourse = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                  onTap: () async {
                    final DateTime? date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 30),
                      ),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        selectedDate = date;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Students',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    itemCount: _students.length,
                    itemBuilder: (context, index) {
                      final student = _students[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            student['name']
                                    ?.toString()
                                    .substring(0, 1)
                                    .toUpperCase() ??
                                '?',
                          ),
                        ),
                        title: Text(student['name']?.toString() ?? 'Unknown'),
                        subtitle: Text(
                          student['roll_number']?.toString() ?? '',
                        ),
                        trailing: DropdownButton<String>(
                          value:
                              attendanceStatus[student['id']?.toString()] ??
                              'present',
                          items: const [
                            DropdownMenuItem(
                              value: 'present',
                              child: Text('Present'),
                            ),
                            DropdownMenuItem(
                              value: 'absent',
                              child: Text('Absent'),
                            ),
                            DropdownMenuItem(
                              value: 'late',
                              child: Text('Late'),
                            ),
                          ],
                          onChanged: (String? value) {
                            setState(() {
                              attendanceStatus[student['id']?.toString() ??
                                      ''] =
                                  value!;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _saveAttendance(selectedDate, attendanceStatus);
              },
              child: const Text('Save Attendance'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveAttendance(DateTime date, Map<String, String> attendanceStatus) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);

    attendanceStatus.forEach((studentId, status) {
      // Check if attendance already exists for this student on this date
      final existingIndex = _attendance.indexWhere(
        (a) => a['student_id'] == studentId && a['date'] == dateStr,
      );

      final newAttendance = {
        'id': existingIndex >= 0
            ? _attendance[existingIndex]['id']
            : DateTime.now().toString() + studentId,
        'student_id': studentId,
        'date': dateStr,
        'status': status,
        'created_at': DateTime.now().toIso8601String(),
        'student': _students.firstWhere(
          (s) => s['id'] == studentId,
          orElse: () => {'name': 'Unknown', 'roll_number': ''},
        ),
      };

      setState(() {
        if (existingIndex >= 0) {
          _attendance[existingIndex] = newAttendance;
        } else {
          _attendance.add(newAttendance);
        }
      });
    });

    _showSnackBar('Attendance marked successfully', Colors.green);
  }

  void _showNotifications() {
    final pendingApplications = _applications
        .where((a) => a['status'] == 'pending')
        .toList();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notifications',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: pendingApplications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No new notifications',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: pendingApplications.length,
                      itemBuilder: (context, index) {
                        final app = pendingApplications[index];
                        final applicant = app['applicant'] ?? {};
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child: const Icon(Icons.person, color: Colors.blue),
                          ),
                          title: Text(
                            'New application from ${applicant['name']?.toString() ?? 'Unknown'}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            'Applied for ${_getCourseName(app['course_id']?.toString())}',
                          ),
                          trailing: Text(
                            DateFormat('MMM d').format(
                              DateTime.parse(
                                app['created_at']?.toString() ??
                                    DateTime.now().toIso8601String(),
                              ),
                            ),
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _showApplicationDetails(app);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCourseName(String? courseId) {
    final course = _courses.firstWhere(
      (c) => c['id'] == courseId,
      orElse: () => {},
    );
    return course['name']?.toString() ?? 'Unknown course';
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.notifications, color: Colors.blue),
              title: const Text('Notification Preferences'),
              trailing: Switch(value: true, onChanged: (bool? value) {}),
            ),
            ListTile(
              leading: const Icon(Icons.color_lens, color: Colors.purple),
              title: const Text('Theme'),
              trailing: DropdownButton<String>(
                value: 'Light',
                items: ['Light', 'Dark', 'System']
                    .map<DropdownMenuItem<String>>((String theme) {
                      return DropdownMenuItem<String>(
                        value: theme,
                        child: Text(theme),
                      );
                    })
                    .toList(),
                onChanged: (String? value) {},
              ),
            ),
            ListTile(
              leading: const Icon(Icons.language, color: Colors.green),
              title: const Text('Language'),
              trailing: const Text('English'),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelp() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Help & Support',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.email, color: Colors.blue),
              title: const Text('Email Support'),
              subtitle: const Text('support@collegeportal.com'),
              onTap: () => _showSnackBar(
                'Email: support@collegeportal.com',
                Colors.blue,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.green),
              title: const Text('Phone Support'),
              subtitle: const Text('+1 (800) 123-4567'),
              onTap: () =>
                  _showSnackBar('Phone: +1 (800) 123-4567', Colors.green),
            ),
            ListTile(
              leading: const Icon(Icons.chat, color: Colors.orange),
              title: const Text('Live Chat'),
              subtitle: const Text('Available 24/7'),
              onTap: () => _showSnackBar('Live chat opened', Colors.orange),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ============ DASHBOARD VIEW ============
  Widget _buildDashboardView() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dashboardData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading dashboard',
                  style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _loadAllData();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data!;

        return RefreshIndicator(
          onRefresh: () async {
            await _loadAllData();
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildWelcomeCard(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Quick Stats', Icons.analytics),
                    const SizedBox(height: 16),
                    _buildStatsGrid(data),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Quick Actions', Icons.flash_on),
                    const SizedBox(height: 16),
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    _buildRecentApplications(data),
                    const SizedBox(height: 24),
                    _buildUpcomingEvents(data),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWelcomeCard() {
    final pendingCount = _applications
        .where((a) => a['status'] == 'pending')
        .length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade600, Colors.blue.shade800],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade200.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _collegeProfile?['name']?.toString().split(' ').first ??
                          'Admin',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.school, size: 32, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (pendingCount > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade700,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.notifications_active,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You have $pendingCount pending application(s)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: Colors.blue.shade700),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> data) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildStatsCard(
          icon: Icons.people,
          title: 'Students',
          value: _students.length.toString(),
          color: Colors.blue,
          onTap: () => setState(() => _currentIndex = 1),
        ),
        _buildStatsCard(
          icon: Icons.book,
          title: 'Courses',
          value: _courses.length.toString(),
          color: Colors.green,
          onTap: () => setState(() => _currentIndex = 2),
        ),
        _buildStatsCard(
          icon: Icons.check_circle,
          title: "Today's Attendance",
          value: _attendance
              .where(
                (a) =>
                    a['date'] ==
                        DateFormat('yyyy-MM-dd').format(DateTime.now()) &&
                    a['status'] == 'present',
              )
              .length
              .toString(),
          color: Colors.orange,
          onTap: () => setState(() => _currentIndex = 3),
        ),
        _buildStatsCard(
          icon: Icons.pending_actions,
          title: 'Pending Applications',
          value: _applications
              .where((a) => a['status'] == 'pending')
              .length
              .toString(),
          color: Colors.purple,
          onTap: _showApplications,
        ),
      ],
    );
  }

  Widget _buildStatsCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final List<Map<String, dynamic>> actions = [
      {
        'icon': Icons.person_add,
        'label': 'Add Student',
        'gradient': [Colors.blue.shade400, Colors.blue.shade700],
        'onTap': _showAddStudentDialog,
      },
      {
        'icon': Icons.check_circle,
        'label': 'Mark Attendance',
        'gradient': [Colors.green.shade400, Colors.green.shade700],
        'onTap': _showMarkAttendanceDialog,
      },
      {
        'icon': Icons.add_circle,
        'label': 'Create Course',
        'gradient': [Colors.purple.shade400, Colors.purple.shade700],
        'onTap': _showAddCourseDialog,
      },
      {
        'icon': Icons.event,
        'label': 'Add Event',
        'gradient': [Colors.orange.shade400, Colors.orange.shade700],
        'onTap': _showAddEventDialog,
      },
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 0.9,
      children: actions.map((action) {
        return _buildQuickActionButton(
          icon: action['icon'] as IconData,
          label: action['label'] as String,
          gradient: action['gradient'] as List<Color>,
          onTap: action['onTap'] as VoidCallback,
        );
      }).toList(),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: gradient.last.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentApplications(Map<String, dynamic> data) {
    final applications = data['recentApplications'] as List;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Applications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: _showApplications,
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (applications.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 48,
                  color: Colors.green.shade300,
                ),
                const SizedBox(height: 12),
                const Text(
                  'No Pending Applications',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: applications.map((app) {
                final applicant = app['applicant'] ?? {};
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      (applicant['name']?.toString().substring(0, 1) ?? '?')
                          .toUpperCase(),
                      style: TextStyle(color: Colors.blue.shade700),
                    ),
                  ),
                  title: Text(
                    applicant['name']?.toString() ?? 'Unknown Applicant',
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_getCourseName(app['course_id']?.toString())),
                      Text(
                        applicant['email']?.toString() ?? 'No email',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Text(
                      'PENDING',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                  onTap: () => _showApplicationDetails(app),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildUpcomingEvents(Map<String, dynamic> data) {
    final events = data['upcomingEvents'] as List;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Upcoming Events',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: _showAllEvents,
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (events.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.event_busy, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                const Text(
                  'No Upcoming Events',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: events.map((event) {
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.event, color: Colors.blue),
                  ),
                  title: Text(event['title']?.toString() ?? 'Untitled Event'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (event['description'] != null)
                        Text(
                          event['description'].toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat(
                              'MMM d, yyyy',
                            ).format(DateTime.parse(event['date'].toString())),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  onTap: () => _showEventDetails(event),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  void _showAddEventDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Event'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _eventTitleController,
                decoration: const InputDecoration(
                  labelText: 'Event Title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _eventDescriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(
                  DateFormat('yyyy-MM-dd').format(_selectedEventDate),
                ),
                onTap: () async {
                  final DateTime? date = await showDatePicker(
                    context: context,
                    initialDate: _selectedEventDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() {
                      _selectedEventDate = date;
                    });
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _eventTitleController.clear();
              _eventDescriptionController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(onPressed: _addEvent, child: const Text('Add Event')),
        ],
      ),
    );
  }

  void _addEvent() {
    final newEvent = {
      'id': DateTime.now().toString(),
      'title': _eventTitleController.text,
      'description': _eventDescriptionController.text,
      'date': _selectedEventDate.toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
    };

    setState(() {
      _events.add(newEvent);
      _events.sort(
        (a, b) => DateTime.parse(
          a['date'].toString(),
        ).compareTo(DateTime.parse(b['date'].toString())),
      );
    });

    _eventTitleController.clear();
    _eventDescriptionController.clear();
    _selectedEventDate = DateTime.now();
    Navigator.pop(context);
    _showSnackBar('Event added successfully', Colors.green);
  }

  void _showApplicationDetails(Map<String, dynamic> application) {
    final applicant = application['applicant'] ?? {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Application Details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _buildDetailCard(
                    icon: Icons.person,
                    title: 'Applicant Information',
                    child: Column(
                      children: [
                        _buildDetailRow(
                          'Name',
                          applicant['name']?.toString() ?? 'N/A',
                        ),
                        _buildDetailRow(
                          'Email',
                          applicant['email']?.toString() ?? 'N/A',
                        ),
                        _buildDetailRow(
                          'Phone',
                          applicant['phone']?.toString() ?? 'N/A',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailCard(
                    icon: Icons.school,
                    title: 'Applied Course',
                    child: Column(
                      children: [
                        _buildDetailRow(
                          'Course',
                          _getCourseName(application['course_id']?.toString()),
                        ),
                        _buildDetailRow(
                          'Applied Date',
                          DateFormat('yyyy-MM-dd').format(
                            DateTime.parse(
                              application['created_at']?.toString() ??
                                  DateTime.now().toIso8601String(),
                            ),
                          ),
                        ),
                        _buildDetailRow(
                          'Status',
                          application['status']?.toString() ?? 'pending',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        application['status'] = 'approved';
                      });
                      Navigator.pop(context);
                      _showSnackBar('Application approved', Colors.green);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEventDetails(Map<String, dynamic> event) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.event, color: Colors.blue),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event['title']?.toString() ?? 'Event',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat(
                          'EEEE, MMMM d, yyyy',
                        ).format(DateTime.parse(event['date'].toString())),
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            const Text(
              'Description',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              event['description']?.toString() ?? 'No description available',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _showAllEvents() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'All Events',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _events.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_busy,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No events',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _events.length,
                      itemBuilder: (context, index) {
                        final event = _events[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.event,
                                color: Colors.blue,
                              ),
                            ),
                            title: Text(
                              event['title']?.toString() ?? 'Untitled Event',
                            ),
                            subtitle: Text(
                              DateFormat('MMM d, yyyy').format(
                                DateTime.parse(event['date'].toString()),
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              _showEventDetails(event);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showApplications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'All Applications',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _applications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No applications yet',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _applications.length,
                      itemBuilder: (context, index) {
                        final app = _applications[index];
                        final applicant = app['applicant'] ?? {};
                        final status = app['status']?.toString() ?? 'pending';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              child: Text(
                                (applicant['name']?.toString().substring(
                                          0,
                                          1,
                                        ) ??
                                        '?')
                                    .toUpperCase(),
                              ),
                            ),
                            title: Text(
                              applicant['name']?.toString() ?? 'Unknown',
                            ),
                            subtitle: Text(
                              applicant['email']?.toString() ?? '',
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: status == 'pending'
                                    ? Colors.orange.shade100
                                    : Colors.green.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: status == 'pending'
                                      ? Colors.orange.shade700
                                      : Colors.green.shade700,
                                ),
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              _showApplicationDetails(app);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ STUDENTS VIEW ============
  Widget _buildStudentsView() {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: _students.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No students yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _showAddStudentDialog,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add Your First Student'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _students.length,
              itemBuilder: (context, index) {
                final student = _students[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      radius: 28,
                      child: Text(
                        (student['name']?.toString().substring(0, 1) ?? '?')
                            .toUpperCase(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                    title: Text(
                      student['name']?.toString() ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Roll: ${student['roll_number']?.toString() ?? 'N/A'}',
                        ),
                        Text(
                          'Course: ${student['course']?.toString() ?? 'N/A'}',
                        ),
                        Text('Email: ${student['email']?.toString() ?? 'N/A'}'),
                        Text('Phone: ${student['phone']?.toString() ?? 'N/A'}'),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'attendance',
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 18,
                                color: Colors.green,
                              ),
                              SizedBox(width: 8),
                              Text('View Attendance'),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (String value) {
                        if (value == 'edit') {
                          _showEditStudentDialog(student);
                        } else if (value == 'delete') {
                          _showDeleteConfirmation(student);
                        } else if (value == 'attendance') {
                          _showStudentAttendance(student);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showEditStudentDialog(Map<String, dynamic> student) {
    _studentNameController.text = student['name']?.toString() ?? '';
    _studentEmailController.text = student['email']?.toString() ?? '';
    _studentRollController.text = student['roll_number']?.toString() ?? '';
    _studentCourseController.text = student['course']?.toString() ?? '';
    _studentPhoneController.text = student['phone']?.toString() ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Student'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _studentNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _studentEmailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _studentRollController,
                decoration: const InputDecoration(
                  labelText: 'Roll Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _studentCourseController,
                decoration: const InputDecoration(
                  labelText: 'Course',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _studentPhoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _clearStudentControllers();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                student['name'] = _studentNameController.text;
                student['email'] = _studentEmailController.text;
                student['roll_number'] = _studentRollController.text;
                student['course'] = _studentCourseController.text;
                student['phone'] = _studentPhoneController.text;
              });
              _clearStudentControllers();
              Navigator.pop(context);
              _showSnackBar('Student updated successfully', Colors.green);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text(
          'Are you sure you want to delete ${student['name']?.toString()}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _students.removeWhere((s) => s['id'] == student['id']);
              });
              Navigator.pop(context);
              _showSnackBar('Student deleted successfully', Colors.red);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showStudentAttendance(Map<String, dynamic> student) {
    final studentAttendance = _attendance
        .where((a) => a['student_id'] == student['id'])
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    (student['name']?.toString().substring(0, 1) ?? '?')
                        .toUpperCase(),
                    style: TextStyle(fontSize: 24, color: Colors.blue.shade700),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student['name']?.toString() ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Roll: ${student['roll_number']?.toString() ?? 'N/A'}',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              'Attendance Record (${studentAttendance.length} days)',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: studentAttendance.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No attendance records',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: studentAttendance.length,
                      itemBuilder: (context, index) {
                        final record = studentAttendance[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(
                              record['status'] == 'present'
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: record['status'] == 'present'
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            title: Text(record['date']?.toString() ?? ''),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: record['status'] == 'present'
                                    ? Colors.green.shade50
                                    : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                (record['status']?.toString() ?? '')
                                    .toUpperCase(),
                                style: TextStyle(
                                  color: record['status'] == 'present'
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ COURSES VIEW ============
  Widget _buildCoursesView() {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: _courses.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.book_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No courses yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _showAddCourseDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Create Your First Course'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _courses.length,
              itemBuilder: (context, index) {
                final course = _courses[index];
                final studentsInCourse = _students
                    .where((s) => s['course'] == course['id'])
                    .length;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.book, color: Colors.green.shade700),
                    ),
                    title: Text(
                      course['name']?.toString() ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('Code: ${course['code']?.toString() ?? 'N/A'}'),
                        Text(
                          'Duration: ${course['duration']?.toString() ?? 'N/A'} months',
                        ),
                        Text('Students: $studentsInCourse enrolled'),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (String value) {
                        if (value == 'edit') {
                          _showEditCourseDialog(course);
                        } else if (value == 'delete') {
                          _showDeleteCourseConfirmation(course);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showEditCourseDialog(Map<String, dynamic> course) {
    _courseNameController.text = course['name']?.toString() ?? '';
    _courseCodeController.text = course['code']?.toString() ?? '';
    _courseDurationController.text = course['duration']?.toString() ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Course'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _courseNameController,
                decoration: const InputDecoration(
                  labelText: 'Course Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _courseCodeController,
                decoration: const InputDecoration(
                  labelText: 'Course Code',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _courseDurationController,
                decoration: const InputDecoration(
                  labelText: 'Duration (months)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _courseNameController.clear();
              _courseCodeController.clear();
              _courseDurationController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                course['name'] = _courseNameController.text;
                course['code'] = _courseCodeController.text;
                course['duration'] = _courseDurationController.text;
              });
              _courseNameController.clear();
              _courseCodeController.clear();
              _courseDurationController.clear();
              Navigator.pop(context);
              _showSnackBar('Course updated successfully', Colors.green);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteCourseConfirmation(Map<String, dynamic> course) {
    final studentsInCourse = _students
        .where((s) => s['course'] == course['id'])
        .length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Course'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete ${course['name']?.toString()}?',
            ),
            if (studentsInCourse > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Warning: $studentsInCourse student(s) are enrolled in this course.',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _courses.removeWhere((c) => c['id'] == course['id']);
              });
              Navigator.pop(context);
              _showSnackBar('Course deleted successfully', Colors.red);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ============ ATTENDANCE VIEW ============
  Widget _buildAttendanceView() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayAttendance = _attendance
        .where((a) => a['date'] == today)
        .toList();
    final presentCount = todayAttendance
        .where((a) => a['status'] == 'present')
        .length;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: _attendance.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.checklist_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No attendance records for today',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _showMarkAttendanceDialog,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Mark Attendance'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Date: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Present: $presentCount/${_students.length}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: todayAttendance.length,
                    itemBuilder: (context, index) {
                      final record = todayAttendance[index];
                      final student = record['student'] ?? {};
                      final status = record['status']?.toString() ?? 'absent';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: status == 'present'
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            child: Icon(
                              status == 'present'
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: status == 'present'
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                          title: Text(student['name']?.toString() ?? 'Unknown'),
                          subtitle: Text(
                            'Roll: ${student['roll_number']?.toString() ?? 'N/A'}',
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: status == 'present'
                                  ? Colors.green.shade50
                                  : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: status == 'present'
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  // ============ PROFILE VIEW ============
  Widget _buildProfileView() {
    final user = supabase.auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue.shade700, Colors.blue.shade900],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -60),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 56,
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        _collegeProfile?['name']
                                ?.toString()
                                .substring(0, 1)
                                .toUpperCase() ??
                            user?.email?.substring(0, 1).toUpperCase() ??
                            'C',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _collegeProfile?['name']?.toString() ?? 'College Name',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? 'admin@college.edu',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildProfileCard(
                  title: 'College Information',
                  icon: Icons.school,
                  children: [
                    _buildProfileRow(
                      'Name',
                      _collegeProfile?['name']?.toString() ?? 'Not set',
                    ),
                    _buildProfileRow('Email', user?.email ?? 'Not set'),
                    _buildProfileRow(
                      'Phone',
                      _collegeProfile?['phone']?.toString() ?? 'Not set',
                    ),
                    _buildProfileRow(
                      'Address',
                      _collegeProfile?['address']?.toString() ?? 'Not set',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildProfileCard(
                  title: 'Statistics',
                  icon: Icons.analytics,
                  children: [
                    _buildProfileRow(
                      'Total Students',
                      _students.length.toString(),
                    ),
                    _buildProfileRow(
                      'Total Courses',
                      _courses.length.toString(),
                    ),
                    _buildProfileRow(
                      'Pending Applications',
                      _applications
                          .where((a) => a['status'] == 'pending')
                          .length
                          .toString(),
                    ),
                    _buildProfileRow(
                      'Upcoming Events',
                      _events
                          .where(
                            (e) => DateTime.parse(
                              e['date'].toString(),
                            ).isAfter(DateTime.now()),
                          )
                          .length
                          .toString(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildProfileCard(
                  title: 'System Information',
                  icon: Icons.info,
                  children: [
                    _buildProfileRow('Version', '1.0.0'),
                    _buildProfileRow(
                      'Last Login',
                      DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
                    ),
                    _buildProfileRow('Account Type', 'College Administrator'),
                  ],
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
