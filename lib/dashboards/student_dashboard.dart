import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final supabase = Supabase.instance.client;
  int _selectedIndex = 0;
  Map<String, dynamic>? _studentProfile;

  @override
  void initState() {
    super.initState();
    _loadStudentProfile();
  }

  Future<void> _loadStudentProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase
          .from('students')
          .select('*')
          .eq('auth_id', user.id)
          .maybeSingle();

      setState(() {
        _studentProfile = response;
      });
    } catch (e) {
      print('Error loading student profile: $e');
    }
  }

  // Dashboard sections
  late final List<Widget> _dashboardSections;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize sections with context
    _dashboardSections = [
      DashboardHome(
        onTakeTest: () => setState(() => _selectedIndex = 2),
        onBrowseColleges: () => setState(() => _selectedIndex = 1),
        onViewResults: () => setState(() => _selectedIndex = 3),
        onGiveFeedback: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FeedbackForm()),
        ),
      ),
      const CollegeSelection(),
      const TestSelection(),
      TestHistory(onTakeTest: () => setState(() => _selectedIndex = 2)),
      const FeedbackSection(),
    ];
  }

  // Navigation items
  final List<Map<String, dynamic>> _navItems = [
    {'icon': Icons.home, 'label': 'Home'},
    {'icon': Icons.school, 'label': 'Colleges'},
    {'icon': Icons.quiz, 'label': 'Take Test'},
    {'icon': Icons.history, 'label': 'Test History'},
    {'icon': Icons.feedback, 'label': 'Feedback'},
  ];

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: _showNotifications,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      drawer: _buildDrawer(user),
      body: _dashboardSections[_selectedIndex],
      floatingActionButton: _selectedIndex == 2
          ? FloatingActionButton.extended(
              onPressed: _startQuickTest,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Quick Test'),
            )
          : null,
    );
  }

  Widget _buildDrawer(User? user) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue.shade700, Colors.blue.shade900],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 30,
                  child: Text(
                    user?.email?.substring(0, 1).toUpperCase() ?? 'S',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  user?.email ?? 'Student',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _studentProfile?['name'] ?? 'Student Account',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          ..._navItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return ListTile(
              leading: Icon(item['icon']),
              title: Text(item['label']),
              selected: _selectedIndex == index,
              onTap: () {
                setState(() => _selectedIndex = index);
                Navigator.pop(context);
              },
            );
          }),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.grey),
            title: const Text('Settings'),
            onTap: _showSettings,
          ),
          ListTile(
            leading: const Icon(Icons.help, color: Colors.grey),
            title: const Text('Help & Support'),
            onTap: _showHelp,
          ),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.grey),
            title: const Text('My Profile'),
            onTap: () {
              Navigator.pop(context);
              _showProfileDialog();
            },
          ),
        ],
      ),
    );
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                leading: const Icon(Icons.school, color: Colors.blue),
                title: const Text('MIT Test Result Available'),
                subtitle: const Text('Your test results have been sent to MIT'),
              ),
              ListTile(
                leading: const Icon(Icons.assignment, color: Colors.green),
                title: const Text('Test Reminder'),
                subtitle: const Text('Computer Science test available'),
              ),
              ListTile(
                leading: const Icon(Icons.email, color: Colors.orange),
                title: const Text('Application Update'),
                subtitle: const Text('Stanford has received your test results'),
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

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('Notification Settings'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notification settings opened'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.security),
                title: const Text('Privacy & Security'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Privacy settings opened')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.email),
                title: const Text('Email Preferences'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Email preferences opened')),
                  );
                },
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

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              const Text('Need assistance? Here are your options:'),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.email),
                title: const Text('Email Support'),
                subtitle: const Text('support@collegeportal.com'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Email support: support@collegeportal.com'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.phone),
                title: const Text('Call Support'),
                subtitle: const Text('+1 800-TEST-HELP'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Call support: +1 800-TEST-HELP'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat),
                title: const Text('Live Chat'),
                subtitle: const Text('Available 24/7'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Live chat opened')),
                  );
                },
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

  void _showProfileDialog() {
    final user = supabase.auth.currentUser;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('My Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blue,
              child: Text(
                user?.email?.substring(0, 1).toUpperCase() ?? 'S',
                style: const TextStyle(
                  fontSize: 32,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user?.email ?? 'Student',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _studentProfile?['name'] ?? 'Student Account',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            if (_studentProfile != null) ...[
              ListTile(
                leading: const Icon(Icons.email, size: 20),
                title: const Text('Email'),
                subtitle: Text(user?.email ?? 'Not set'),
              ),
              if (_studentProfile?['phone'] != null)
                ListTile(
                  leading: const Icon(Icons.phone, size: 20),
                  title: const Text('Phone'),
                  subtitle: Text(_studentProfile!['phone']),
                ),
              if (_studentProfile?['education'] != null)
                ListTile(
                  leading: const Icon(Icons.school, size: 20),
                  title: const Text('Education'),
                  subtitle: Text(_studentProfile!['education']),
                ),
            ],
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

  Future<void> _startQuickTest() async {
    try {
      // Get first available test
      final response = await supabase
          .from('tests')
          .select('id, name, description, subject_area')
          .eq('is_active', true)
          .limit(1)
          .single();

      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TestScreen(
            testId: response['id'].toString(),
            testData: response,
            selectedColleges: [],
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No tests available. Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
      await supabase.auth.signOut();

      if (!context.mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }
}

// ========== Dashboard Home ==========
class DashboardHome extends StatelessWidget {
  final VoidCallback onTakeTest;
  final VoidCallback onBrowseColleges;
  final VoidCallback onViewResults;
  final VoidCallback onGiveFeedback;

  const DashboardHome({
    super.key,
    required this.onTakeTest,
    required this.onBrowseColleges,
    required this.onViewResults,
    required this.onGiveFeedback,
  });

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return FutureBuilder(
      future: Future.wait([
        supabase.from('student_tests').select('score').limit(5),
        supabase.from('college_preferences').select('id').limit(5),
        supabase.from('colleges').select('id').limit(5),
      ]),
      builder: (context, snapshot) {
        int testCount = 0;
        int applicationCount = 0;
        int collegeCount = 0;
        double avgScore = 0;

        if (snapshot.hasData) {
          testCount = snapshot.data![0].length;
          applicationCount = snapshot.data![1].length;
          collegeCount = snapshot.data![2].length;

          if (snapshot.data![0].isNotEmpty) {
            final scores = List<int>.from(
              snapshot.data![0].map((t) => t['score'] ?? 0),
            );
            avgScore = scores.reduce((a, b) => a + b) / scores.length;
          }
        }

        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome to College Portal!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                'Take tests and apply to your dream colleges',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 30),

              // Quick Stats
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.5,
                children: [
                  _buildStatCard(
                    'Tests Taken',
                    testCount.toString(),
                    Colors.blue,
                    Icons.assignment,
                  ),
                  _buildStatCard(
                    'Avg Score',
                    '${avgScore.toInt()}%',
                    Colors.green,
                    Icons.leaderboard,
                  ),
                  _buildStatCard(
                    'Applications',
                    applicationCount.toString(),
                    Colors.orange,
                    Icons.school,
                  ),
                  _buildStatCard(
                    'Colleges',
                    collegeCount.toString(),
                    Colors.purple,
                    Icons.apartment,
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
                    icon: Icons.quiz,
                    label: 'Take Test',
                    onTap: onTakeTest,
                    color: Colors.blue,
                  ),
                  _buildActionButton(
                    icon: Icons.school,
                    label: 'Browse Colleges',
                    onTap: onBrowseColleges,
                    color: Colors.green,
                  ),
                  _buildActionButton(
                    icon: Icons.history,
                    label: 'View Results',
                    onTap: onViewResults,
                    color: Colors.orange,
                  ),
                  _buildActionButton(
                    icon: Icons.feedback,
                    label: 'Give Feedback',
                    onTap: onGiveFeedback,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

// ========== College Selection ==========
class CollegeSelection extends StatefulWidget {
  const CollegeSelection({super.key});

  @override
  State<CollegeSelection> createState() => _CollegeSelectionState();
}

class _CollegeSelectionState extends State<CollegeSelection> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _colleges = [];
  List<Map<String, dynamic>> _filteredColleges = [];
  String _searchQuery = '';
  Set<String> _selectedColleges = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadColleges();
  }

  Future<void> _loadColleges() async {
    try {
      final response = await supabase
          .from('colleges')
          .select('*')
          .eq('is_active', true)
          .order('name', ascending: true);

      setState(() {
        _colleges = List<Map<String, dynamic>>.from(response);
        _filteredColleges = _colleges;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading colleges: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading colleges: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _filterColleges(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredColleges = _colleges;
      } else {
        _filteredColleges = _colleges.where((college) {
          final name = college['name']?.toString().toLowerCase() ?? '';
          final location = college['location']?.toString().toLowerCase() ?? '';
          final courses = college['courses']?.toString().toLowerCase() ?? '';
          return name.contains(query.toLowerCase()) ||
              location.contains(query.toLowerCase()) ||
              courses.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _toggleCollegeSelection(String collegeId) {
    setState(() {
      if (_selectedColleges.contains(collegeId)) {
        _selectedColleges.remove(collegeId);
      } else {
        _selectedColleges.add(collegeId);
      }
    });
  }

  Future<void> _submitCollegePreferences() async {
    if (_selectedColleges.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one college')),
      );
      return;
    }

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please login first')));
        return;
      }

      // Save college preferences
      for (final collegeId in _selectedColleges) {
        await supabase.from('college_preferences').upsert({
          'student_id': user.id,
          'college_id': collegeId,
          'preference_order': _selectedColleges.toList().indexOf(collegeId) + 1,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Preferences saved for ${_selectedColleges.length} college(s)',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to test selection
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              TestSelection(selectedColleges: _selectedColleges.toList()),
        ),
      );
    } catch (e) {
      print('Error saving preferences: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            onChanged: _filterColleges,
            decoration: InputDecoration(
              hintText: 'Search colleges by name, location, or courses...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Colleges (${_selectedColleges.length} selected)',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_selectedColleges.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: _submitCollegePreferences,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Continue to Test'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredColleges.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.search_off,
                          size: 60,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No colleges available'
                              : 'No colleges found for "$_searchQuery"',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _loadColleges,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                          childAspectRatio: 0.9,
                        ),
                    itemCount: _filteredColleges.length,
                    itemBuilder: (context, index) {
                      final college = _filteredColleges[index];
                      final isSelected = _selectedColleges.contains(
                        college['id'],
                      );
                      return _buildCollegeCard(college, isSelected);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollegeCard(Map<String, dynamic> college, bool isSelected) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Colors.blue : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => _toggleCollegeSelection(college['id']),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isSelected
                        ? Colors.blue
                        : Colors.grey.shade200,
                    child: Icon(
                      Icons.school,
                      color: isSelected ? Colors.white : Colors.grey,
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: Colors.blue,
                      size: 24,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                college['name'] ?? 'Unknown College',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              Text(
                college['location'] ?? 'Location not specified',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children:
                    (college['courses']?.toString().split(',').take(2) ?? [])
                        .map(
                          (course) => Chip(
                            label: Text(
                              course.trim(),
                              style: const TextStyle(fontSize: 10),
                            ),
                            backgroundColor: Colors.blue.shade50,
                            side: BorderSide.none,
                          ),
                        )
                        .toList(),
              ),
              const Spacer(),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.info_outline, size: 18),
                    onPressed: () => _showCollegeDetails(college),
                  ),
                  const Spacer(),
                  Text(
                    'Select',
                    style: TextStyle(
                      color: isSelected ? Colors.blue : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCollegeDetails(Map<String, dynamic> college) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(college['name'] ?? 'College Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Location: ${college['location']}'),
              const SizedBox(height: 10),
              const Text('Available Courses:'),
              ...(college['courses']?.toString().split(',') ?? [])
                  .map((course) => Text('• $course'))
                  .toList(),
              const SizedBox(height: 10),
              Text(
                'Description: ${college['description'] ?? 'No description'}',
              ),
              const SizedBox(height: 10),
              if (college['email'] != null) Text('Email: ${college['email']}'),
              if (college['website'] != null)
                Text('Website: ${college['website']}'),
              if (college['phone'] != null) Text('Phone: ${college['phone']}'),
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
}

// ========== Test Selection ==========
class TestSelection extends StatefulWidget {
  final List<String>? selectedColleges;

  const TestSelection({super.key, this.selectedColleges});

  @override
  State<TestSelection> createState() => _TestSelectionState();
}

class _TestSelectionState extends State<TestSelection> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _availableTests = [];
  String? _selectedTest;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvailableTests();
  }

  Future<void> _loadAvailableTests() async {
    try {
      final response = await supabase
          .from('tests')
          .select('*')
          .eq('is_active', true)
          .order('name', ascending: true);

      setState(() {
        _availableTests = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading tests: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading tests: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startTest() {
    if (_selectedTest == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a test')));
      return;
    }

    final selectedTestData = _availableTests.firstWhere(
      (t) => t['id'] == _selectedTest,
      orElse: () => {},
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TestScreen(
          testId: _selectedTest!,
          testData: selectedTestData,
          selectedColleges: widget.selectedColleges ?? [],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.selectedColleges?.isNotEmpty ?? false) ...[
            Text(
              'Selected Colleges: ${widget.selectedColleges!.length}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
          ],
          const Text(
            'Available Tests',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Select a test to begin. Results will be sent to your selected colleges.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _availableTests.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.quiz, size: 60, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'No tests available at the moment',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _loadAvailableTests,
                          child: const Text('Refresh'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _availableTests.length,
                    itemBuilder: (context, index) {
                      final test = _availableTests[index];
                      final isSelected = _selectedTest == test['id'];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected
                                ? Colors.blue
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: isSelected
                                ? Colors.blue
                                : Colors.grey.shade200,
                            child: Icon(
                              Icons.quiz,
                              color: isSelected ? Colors.white : Colors.grey,
                            ),
                          ),
                          title: Text(
                            test['name'] ?? 'Unnamed Test',
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Duration: ${test['duration']} minutes'),
                              Text('Questions: ${test['total_questions']}'),
                              if (test['description'] != null)
                                Text(
                                  test['description']!,
                                  style: const TextStyle(fontSize: 12),
                                ),
                            ],
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.blue,
                                )
                              : null,
                          onTap: () {
                            setState(() => _selectedTest = test['id']);
                          },
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 20),
          if (_availableTests.isNotEmpty)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _startTest,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Start Selected Test',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ========== Test Screen ==========
class TestScreen extends StatefulWidget {
  final String testId;
  final Map<String, dynamic>? testData;
  final List<String> selectedColleges;

  const TestScreen({
    super.key,
    required this.testId,
    this.testData,
    this.selectedColleges = const [],
  });

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _questions = [];
  Map<int, String?> _answers = {};
  int _currentQuestionIndex = 0;
  int _timeRemaining = 0;
  bool _testSubmitted = false;
  bool _isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadTestQuestions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadTestQuestions() async {
    try {
      final response = await supabase
          .from('test_questions')
          .select('*')
          .eq('test_id', widget.testId)
          .order('question_number', ascending: true);

      setState(() {
        _questions = List<Map<String, dynamic>>.from(response);
        _timeRemaining = (widget.testData?['duration'] ?? 60) * 60;
        _isLoading = false;
      });

      _startTimer();
    } catch (e) {
      print('Error loading questions: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading questions: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0) {
        setState(() => _timeRemaining--);
      } else {
        timer.cancel();
        _submitTest();
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  void _selectAnswer(String? answer) {
    setState(() {
      _answers[_currentQuestionIndex] = answer;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() => _currentQuestionIndex++);
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() => _currentQuestionIndex--);
    }
  }

  Future<void> _submitTest() async {
    _timer?.cancel();

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to submit test')),
        );
        return;
      }

      // Calculate score
      int score = 0;
      int totalQuestions = _questions.length;

      for (int i = 0; i < _questions.length; i++) {
        if (_answers[i] == _questions[i]['correct_answer']) {
          score++;
        }
      }

      final percentage = (score / totalQuestions * 100).toInt();

      // Save test result
      final testResult = await supabase
          .from('student_tests')
          .insert({
            'student_id': user.id,
            'test_id': widget.testId,
            'score': score,
            'total_questions': totalQuestions,
            'percentage': percentage,
            'answers': _answers.map(
              (key, value) => MapEntry(key.toString(), value),
            ),
            'time_taken':
                (widget.testData?['duration'] ?? 60) * 60 - _timeRemaining,
            'submitted_at': DateTime.now().toIso8601String(),
            'status': 'completed',
          })
          .select()
          .single();

      // Send results to selected colleges
      if (widget.selectedColleges.isNotEmpty) {
        await _sendResultsToColleges(
          testResult['id'],
          score,
          totalQuestions,
          percentage,
        );
      }

      setState(() => _testSubmitted = true);

      // Show results
      _showTestResults(score, totalQuestions, percentage);
    } catch (e) {
      print('Error submitting test: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting test: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendResultsToColleges(
    String testResultId,
    int score,
    int totalQuestions,
    int percentage,
  ) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null || widget.selectedColleges.isEmpty) return;

      // Prepare email data for each college
      for (final collegeId in widget.selectedColleges) {
        await supabase.from('college_test_results').insert({
          'college_id': collegeId,
          'test_result_id': testResultId,
          'student_id': user.id,
          'score': score,
          'percentage': percentage,
          'sent_at': DateTime.now().toIso8601String(),
          'status': 'sent',
        });

        // Get college details
        final college = await supabase
            .from('colleges')
            .select('name, email')
            .eq('id', collegeId)
            .maybeSingle();

        if (college != null) {
          // Here you would typically send an email
          print('Results sent to: ${college['name']} (${college['email']})');
        }
      }
    } catch (e) {
      print('Error sending results: $e');
    }
  }

  void _showTestResults(int score, int totalQuestions, int percentage) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Test Submitted!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              percentage >= 70 ? Icons.celebration : Icons.emoji_events,
              size: 60,
              color: percentage >= 70 ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 20),
            Text(
              'Your Score: $score/$totalQuestions',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              'Percentage: $percentage%',
              style: TextStyle(fontSize: 18, color: _getScoreColor(percentage)),
            ),
            const SizedBox(height: 20),
            Text(
              widget.selectedColleges.isNotEmpty
                  ? 'Results have been sent to ${widget.selectedColleges.length} college(s)'
                  : 'Test completed successfully!',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to test selection
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int percentage) {
    if (percentage >= 85) return Colors.green;
    if (percentage >= 70) return Colors.blue;
    if (percentage >= 50) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    if (_testSubmitted || _isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.testData?['name'] ?? 'Test')),
        body: const Center(child: Text('No questions available for this test')),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];

    // Parse options
    List<String> options = [];
    try {
      final optionsData = currentQuestion['options'];
      if (optionsData is List) {
        options = optionsData.map((item) => item.toString()).toList();
      } else if (optionsData is String) {
        // Try to parse as JSON string
        try {
          final parsed = jsonDecode(optionsData);
          if (parsed is List) {
            options = parsed.map((item) => item.toString()).toList();
          }
        } catch (_) {
          // If not JSON, try comma-separated
          options = optionsData.split(',').map((opt) => opt.trim()).toList();
        }
      }
    } catch (e) {
      print('Error parsing options: $e');
      options = ['Option A', 'Option B', 'Option C', 'Option D'];
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.testData?['name'] ?? 'Test'),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer, size: 18, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  _formatTime(_timeRemaining),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / _questions.length,
              backgroundColor: Colors.grey.shade200,
              color: Colors.blue,
            ),
            const SizedBox(height: 10),
            Text(
              'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // Question
            Text(
              currentQuestion['question_text'] ?? 'No question text',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 30),

            // Options
            Expanded(
              child: ListView.builder(
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options[index];
                  final isSelected = _answers[_currentQuestionIndex] == option;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    color: isSelected ? Colors.blue.shade50 : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isSelected ? Colors.blue : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      title: Text(option),
                      leading: CircleAvatar(
                        backgroundColor: isSelected
                            ? Colors.blue
                            : Colors.grey.shade200,
                        radius: 14,
                        child: Text(
                          String.fromCharCode(65 + index), // A, B, C, D
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      onTap: () => _selectAnswer(option),
                    ),
                  );
                },
              ),
            ),

            // Navigation buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: _currentQuestionIndex > 0
                      ? _previousQuestion
                      : null,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Previous'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    foregroundColor: Colors.grey.shade800,
                  ),
                ),
                Text(
                  'Answered: ${_answers.length}/${_questions.length}',
                  style: const TextStyle(color: Colors.grey),
                ),
                if (_currentQuestionIndex < _questions.length - 1)
                  ElevatedButton.icon(
                    onPressed: _nextQuestion,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Next'),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _submitTest,
                    icon: const Icon(Icons.send),
                    label: const Text('Submit Test'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ========== Test History ==========
class TestHistory extends StatefulWidget {
  final VoidCallback onTakeTest;

  const TestHistory({super.key, required this.onTakeTest});

  @override
  State<TestHistory> createState() => _TestHistoryState();
}

class _TestHistoryState extends State<TestHistory> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _testHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTestHistory();
  }

  Future<void> _loadTestHistory() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase
          .from('student_tests')
          .select('''
            *,
            tests!inner(name, duration)
          ''')
          .eq('student_id', user.id)
          .order('submitted_at', ascending: false);

      setState(() {
        _testHistory = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading test history: $e');
      setState(() {
        _isLoading = false;
      });
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
            'Test History',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'View your test results and performance analytics',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _testHistory.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.history, size: 60, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'No test history yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: widget.onTakeTest,
                          child: const Text('Take Your First Test'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _testHistory.length,
                    itemBuilder: (context, index) {
                      final test = _testHistory[index];
                      final testData = test['tests'] ?? {};
                      final percentage = test['percentage'] ?? 0;
                      return _buildTestCard(test, testData, percentage);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestCard(
    Map<String, dynamic> test,
    Map<String, dynamic> testData,
    int percentage,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getScoreColor(percentage).withOpacity(0.2),
                  child: Icon(
                    percentage >= 70 ? Icons.emoji_events : Icons.assignment,
                    color: _getScoreColor(percentage),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        testData['name'] ?? 'Unknown Test',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Submitted: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(test['submitted_at']))}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text('${percentage}%'),
                  backgroundColor: _getScoreColor(percentage).withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: _getScoreColor(percentage),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Score: ${test['score']}/${test['total_questions']}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 5),
                      LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey.shade300,
                        color: _getScoreColor(percentage),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                OutlinedButton(
                  onPressed: () => _showTestDetails(test, testData),
                  child: const Text('View Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTestDetails(
    Map<String, dynamic> test,
    Map<String, dynamic> testData,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Test: ${testData['name']}'),
              Text('Score: ${test['score']}/${test['total_questions']}'),
              Text('Percentage: ${test['percentage']}%'),
              Text('Submitted: ${test['submitted_at']}'),
              if (test['time_taken'] != null)
                Text('Time taken: ${test['time_taken']} seconds'),
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

  Color _getScoreColor(int percentage) {
    if (percentage >= 85) return Colors.green;
    if (percentage >= 70) return Colors.blue;
    if (percentage >= 50) return Colors.orange;
    return Colors.red;
  }
}

// ========== Feedback Section ==========
class FeedbackSection extends StatefulWidget {
  const FeedbackSection({super.key});

  @override
  State<FeedbackSection> createState() => _FeedbackSectionState();
}

class _FeedbackSectionState extends State<FeedbackSection> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _feedbackController = TextEditingController();
  int _rating = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;
    if (_rating == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please provide a rating')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to submit feedback')),
        );
        return;
      }

      await Supabase.instance.client.from('student_feedback').insert({
        'student_id': user.id,
        'title': _titleController.text.trim(),
        'feedback': _feedbackController.text.trim(),
        'rating': _rating,
        'submitted_at': DateTime.now().toIso8601String(),
        'status': 'pending_review',
      });

      _formKey.currentState!.reset();
      _titleController.clear();
      _feedbackController.clear();
      setState(() => _rating = 0);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you for your feedback!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error submitting feedback: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Submit Feedback',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Help us improve the system by sharing your experience',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Feedback Title',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Rating
            const Text('Rating'),
            const SizedBox(height: 10),
            Row(
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () => setState(() => _rating = index + 1),
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),

            // Feedback
            TextFormField(
              controller: _feedbackController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Your Feedback',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.feedback),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your feedback';
                }
                if (value.length < 10) {
                  return 'Please provide more detailed feedback';
                }
                return null;
              },
            ),
            const SizedBox(height: 30),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitFeedback,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      )
                    : const Text(
                        'Submit Feedback',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // Feedback Guidelines
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Feedback Guidelines:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    const Text('• Be specific about your experience'),
                    const Text('• Mention what worked well'),
                    const Text('• Suggest improvements'),
                    const Text('• Keep feedback constructive'),
                    const SizedBox(height: 10),
                    Text(
                      'Your feedback helps us improve the system for all students.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ========== Feedback Form Popup ==========
class FeedbackForm extends StatelessWidget {
  const FeedbackForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Feedback')),
      body: const FeedbackSection(),
    );
  }
}

// Timer class
class Timer {
  final Duration period;
  final void Function(Timer) callback;
  Timer? _timer;

  Timer.periodic(this.period, this.callback) {
    _timer = Timer.periodic(period, callback);
  }

  void cancel() {
    _timer?.cancel();
  }
}
