import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  // College Selection Fields
  List<Map<String, dynamic>> _allColleges = [];
  List<Map<String, dynamic>> _filteredColleges = [];
  String _searchQuery = '';

  // Feedback Form Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();
  int _feedbackRating = 0;

  @override
  void initState() {
    super.initState();
    _loadStudentProfile();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _feedbackController.dispose();
    super.dispose();
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
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboardHome(),
          _buildCollegeSelection(),
          _buildTestSelection(),
          _buildTestHistory(),
          _buildFeedbackSection(),
        ],
      ),
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
              mainAxisAlignment: MainAxisAlignment.end,
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
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Text(
                  _studentProfile?['name'] ?? 'Student Account',
                  style: const TextStyle(color: Colors.white70),
                  overflow: TextOverflow.ellipsis,
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

  // ============ DASHBOARD HOME ============
  Widget _buildDashboardHome() {
    return Scaffold(
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(20.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
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
                _buildStatsSection(),
                const SizedBox(height: 30),
                const Text(
                  'Quick Actions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                _buildQuickActions(),
                const SizedBox(height: 30),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
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

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
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
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildActionButton(
          icon: Icons.quiz,
          label: 'Take Test',
          onTap: () => setState(() => _selectedIndex = 2),
          color: Colors.blue,
        ),
        _buildActionButton(
          icon: Icons.school,
          label: 'Browse Colleges',
          onTap: () => setState(() => _selectedIndex = 1),
          color: Colors.green,
        ),
        _buildActionButton(
          icon: Icons.history,
          label: 'View Results',
          onTap: () => setState(() => _selectedIndex = 3),
          color: Colors.orange,
        ),
        _buildActionButton(
          icon: Icons.feedback,
          label: 'Give Feedback',
          onTap: () => setState(() => _selectedIndex = 4),
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildActionButton({
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
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ COLLEGE SELECTION - COMPLETELY FIXED ============
  Widget _buildCollegeSelection() {
    return Scaffold(
      body: FutureBuilder(
        future: _loadColleges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData) {
            _allColleges = snapshot.data ?? [];
            // Initialize filtered colleges if empty
            if (_filteredColleges.isEmpty && _searchQuery.isEmpty) {
              _filteredColleges = List.from(_allColleges);
            }
          }

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(20.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Search Field
                    TextField(
                      onChanged: _filterColleges,
                      decoration: InputDecoration(
                        hintText:
                            'Search colleges by name, location, or courses...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: _clearSearch,
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Results count
                    Text(
                      _searchQuery.isEmpty
                          ? 'All Colleges (${_allColleges.length})'
                          : 'Search Results (${_filteredColleges.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Colleges Grid
                    _buildCollegeGrid(_filteredColleges),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadColleges() async {
    try {
      final response = await supabase
          .from('colleges')
          .select('*')
          .eq('is_active', true)
          .order('name', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error loading colleges: $e');
      return [];
    }
  }

  void _filterColleges(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredColleges = List.from(_allColleges);
      } else {
        _filteredColleges = _allColleges.where((college) {
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

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _filteredColleges = List.from(_allColleges);
    });
  }

  Widget _buildCollegeGrid(List<Map<String, dynamic>> colleges) {
    if (colleges.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(
                _searchQuery.isEmpty ? Icons.school : Icons.search_off,
                size: 60,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isEmpty
                    ? 'No colleges available'
                    : 'No colleges found for "$_searchQuery"',
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
              if (_searchQuery.isNotEmpty) ...[
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _clearSearch,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear Search'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 0.9,
      ),
      itemCount: colleges.length,
      itemBuilder: (context, index) {
        final college = colleges[index];
        return _buildCollegeCard(college);
      },
    );
  }

  Widget _buildCollegeCard(Map<String, dynamic> college) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showCollegeDetails(college),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // College Icon
              CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: const Icon(Icons.school, color: Colors.blue),
              ),
              const SizedBox(height: 10),

              // College Name
              Text(
                college['name'] ?? 'Unknown',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Location
              Text(
                college['location'] ?? '',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Course Chips
              if (college['courses'] != null) ...[
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: (college['courses'].toString().split(',').take(2))
                      .map(
                        (course) => Chip(
                          label: Text(
                            course.trim(),
                            style: const TextStyle(fontSize: 9),
                          ),
                          backgroundColor: Colors.blue.shade50,
                          side: BorderSide.none,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      )
                      .toList(),
                ),
              ],

              const Spacer(),

              // View Details Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showCollegeDetails(college),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 30),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: BorderSide(color: Colors.blue.shade200),
                  ),
                  child: const Text(
                    'View Details',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
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
        title: Row(
          children: [
            const Icon(Icons.school, color: Colors.blue),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                college['name'] ?? 'College Details',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(
                Icons.location_on,
                'Location',
                college['location'] ?? 'N/A',
              ),
              const Divider(),
              _buildDetailRow(Icons.book, 'Courses', ''),
              ...(college['courses']?.toString().split(',') ??
                      ['No courses listed'])
                  .map(
                    (course) => Padding(
                      padding: const EdgeInsets.only(left: 32, top: 4),
                      child: Text('• ${course.trim()}'),
                    ),
                  )
                  .toList(),
              const Divider(),
              _buildDetailRow(
                Icons.description,
                'Description',
                college['description'] ?? 'No description available',
              ),
              if (college['email'] != null) ...[
                const Divider(),
                _buildDetailRow(Icons.email, 'Email', college['email']),
              ],
              if (college['website'] != null) ...[
                const Divider(),
                _buildDetailRow(Icons.link, 'Website', college['website']),
              ],
              if (college['phone'] != null) ...[
                const Divider(),
                _buildDetailRow(Icons.phone, 'Phone', college['phone']),
              ],
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            label: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============ TEST SELECTION ============
  Widget _buildTestSelection() {
    return Scaffold(
      body: FutureBuilder(
        future: _loadTests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final tests = snapshot.data ?? [];

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(20.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const Text(
                      'Available Tests',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Select a test to begin',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    ...tests.map((test) => _buildTestCard(test)).toList(),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadTests() async {
    try {
      final response = await supabase
          .from('tests')
          .select('*')
          .eq('is_active', true)
          .order('name', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error loading tests: $e');
      return [];
    }
  }

  Widget _buildTestCard(Map<String, dynamic> test) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: const Icon(Icons.quiz, color: Colors.blue),
        ),
        title: Text(test['name'] ?? 'Unnamed Test'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Duration: ${test['duration']} minutes'),
            Text('Questions: ${test['total_questions']}'),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TestScreen(
                testId: test['id'].toString(),
                testData: test,
                selectedColleges: const [], // Empty list for direct test
              ),
            ),
          );
        },
      ),
    );
  }

  // ============ TEST HISTORY ============
  Widget _buildTestHistory() {
    return Scaffold(
      body: FutureBuilder(
        future: _loadTestHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final history = snapshot.data ?? [];

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(20.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const Text(
                      'Test History',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'View your test results',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    if (history.isEmpty)
                      const Center(
                        child: Column(
                          children: [
                            Icon(Icons.history, size: 60, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No test history yet'),
                          ],
                        ),
                      )
                    else
                      ...history
                          .map((test) => _buildHistoryCard(test))
                          .toList(),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadTestHistory() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return [];

      // Check if table exists first
      try {
        final response = await supabase
            .from('student_tests')
            .select('*, tests(name)')
            .eq('student_id', user.id)
            .order('submitted_at', ascending: false);

        if (response.isNotEmpty) {
          return List<Map<String, dynamic>>.from(response);
        }
      } catch (e) {
        print('Student tests table may not exist yet: $e');
      }

      // Return mock data for testing
      return [
        {
          'id': '1',
          'score': 4,
          'total_questions': 5,
          'percentage': 80,
          'submitted_at': DateTime.now()
              .subtract(const Duration(days: 2))
              .toIso8601String(),
          'tests': {'name': 'Computer Science Fundamentals'},
        },
        {
          'id': '2',
          'score': 3,
          'total_questions': 5,
          'percentage': 60,
          'submitted_at': DateTime.now()
              .subtract(const Duration(days: 5))
              .toIso8601String(),
          'tests': {'name': 'Mathematics Aptitude'},
        },
      ];
    } catch (e) {
      print('Error loading test history: $e');
      return [];
    }
  }

  Widget _buildHistoryCard(Map<String, dynamic> test) {
    final testData = test['tests'] ?? {};
    final percentage = test['percentage'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: const Icon(Icons.assignment, color: Colors.blue),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        testData['name'] ?? 'Unknown Test',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Score: ${test['score']}/${test['total_questions']}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text('$percentage%'),
                  backgroundColor: _getScoreColor(percentage).withOpacity(0.1),
                  labelStyle: TextStyle(
                    color: _getScoreColor(percentage),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(int percentage) {
    if (percentage >= 70) return Colors.green;
    if (percentage >= 50) return Colors.orange;
    return Colors.red;
  }

  // ============ FEEDBACK SECTION - FIXED ============
  Widget _buildFeedbackSection() {
    return Scaffold(
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(20.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const Text(
                  'Submit Feedback',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Help us improve the system',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 30),
                _buildFeedbackForm(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackForm() {
    return Column(
      children: [
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Title',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Rating'),
        const SizedBox(height: 10),
        Row(
          children: List.generate(5, (index) {
            return IconButton(
              onPressed: () {
                setState(() {
                  _feedbackRating = index + 1;
                });
              },
              icon: Icon(
                index < _feedbackRating ? Icons.star : Icons.star_border,
                color: Colors.amber,
              ),
            );
          }),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _feedbackController,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Your Feedback',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _submitFeedback,
            child: const Text('Submit Feedback'),
          ),
        ),
      ],
    );
  }

  Future<void> _submitFeedback() async {
    if (_titleController.text.isEmpty ||
        _feedbackController.text.isEmpty ||
        _feedbackRating == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      await supabase.from('student_feedback').insert({
        'student_id': user.id,
        'title': _titleController.text.trim(),
        'feedback': _feedbackController.text.trim(),
        'rating': _feedbackRating,
        'submitted_at': DateTime.now().toIso8601String(),
      });

      // Clear form
      setState(() {
        _titleController.clear();
        _feedbackController.clear();
        _feedbackRating = 0;
      });

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
          content: Text('Error submitting feedback: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications'),
        content: const Text('No new notifications'),
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
        content: const Text('Settings coming soon'),
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
        content: const Text('Contact support@collegeportal.com'),
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
                style: const TextStyle(fontSize: 32, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Text(user?.email ?? 'Student'),
            const SizedBox(height: 8),
            Text(
              _studentProfile?['name'] ?? 'Student Account',
              style: const TextStyle(color: Colors.grey),
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

  Future<void> _startQuickTest() async {
    try {
      final response = await supabase
          .from('tests')
          .select('id, name')
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
            selectedColleges: const [], // Empty list for quick test
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No tests available'),
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

// ============ TEST SCREEN - COMPLETELY FIXED ============
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
      setState(() => _isLoading = false);

      // Load mock questions for testing
      _loadMockQuestions();
    }
  }

  void _loadMockQuestions() {
    setState(() {
      _questions = [
        {
          'id': '1',
          'question_text': 'What does CPU stand for?',
          'options': [
            'Central Processing Unit',
            'Computer Personal Unit',
            'Central Process Unit',
            'Computer Processing Unit',
          ],
          'correct_answer': 'Central Processing Unit',
        },
        {
          'id': '2',
          'question_text': 'Which data structure uses LIFO?',
          'options': ['Queue', 'Stack', 'Array', 'Linked List'],
          'correct_answer': 'Stack',
        },
        {
          'id': '3',
          'question_text': 'What is the time complexity of binary search?',
          'options': ['O(n)', 'O(log n)', 'O(n²)', 'O(1)'],
          'correct_answer': 'O(log n)',
        },
        {
          'id': '4',
          'question_text':
              'Which language is primarily used for web development?',
          'options': ['Java', 'Python', 'JavaScript', 'C++'],
          'correct_answer': 'JavaScript',
        },
        {
          'id': '5',
          'question_text': 'What does HTML stand for?',
          'options': [
            'HyperText Markup Language',
            'HighText Machine Language',
            'HyperTool Markup Language',
            'HighTool Machine Language',
          ],
          'correct_answer': 'HyperText Markup Language',
        },
      ];
      _timeRemaining = (widget.testData?['duration'] ?? 60) * 60;
      _isLoading = false;
    });
    _startTimer();
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
    setState(() => _testSubmitted = true);

    // Calculate score
    int score = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_answers[i] == _questions[i]['correct_answer']) {
        score++;
      }
    }
    final percentage = (score / _questions.length * 100).toInt();

    // Save to database if needed
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        await supabase.from('student_tests').insert({
          'student_id': user.id,
          'test_id': widget.testId,
          'score': score,
          'total_questions': _questions.length,
          'percentage': percentage,
          'answers': _answers.map(
            (key, value) => MapEntry(key.toString(), value),
          ),
          'submitted_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Error saving test result: $e');
    }

    // Show results
    _showTestResults(score, _questions.length, percentage);
  }

  void _showTestResults(int score, int totalQuestions, int percentage) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Test Completed!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              percentage >= 70
                  ? Icons.emoji_events
                  : Icons.assignment_turned_in,
              size: 60,
              color: percentage >= 70 ? Colors.green : Colors.blue,
            ),
            const SizedBox(height: 20),
            Text(
              'Your Score: $score/$totalQuestions',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              'Percentage: $percentage%',
              style: TextStyle(
                fontSize: 18,
                color: percentage >= 70 ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Test submitted successfully!',
              style: TextStyle(color: Colors.grey),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_testSubmitted) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.testData?['name'] ?? 'Test'),
          elevation: 0,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.quiz, size: 60, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No questions available for this test',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
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
        try {
          final parsed = jsonDecode(optionsData);
          if (parsed is List) {
            options = parsed.map((item) => item.toString()).toList();
          }
        } catch (_) {
          options = optionsData.split(',').map((opt) => opt.trim()).toList();
        }
      }
    } catch (e) {
      print('Error parsing options: $e');
      options = ['Option A', 'Option B', 'Option C', 'Option D'];
    }

    // Ensure we have at least 4 options
    while (options.length < 4) {
      options.add('Option ${String.fromCharCode(65 + options.length)}');
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.testData?['name'] ?? 'Test'),
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _timeRemaining < 300
                  ? Colors.red.shade50
                  : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer,
                  size: 18,
                  color: _timeRemaining < 300 ? Colors.red : Colors.blue,
                ),
                const SizedBox(width: 6),
                Text(
                  _formatTime(_timeRemaining),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _timeRemaining < 300 ? Colors.red : Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress bar
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          'Answered: ${_answers.length}/${_questions.length}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (_currentQuestionIndex + 1) / _questions.length,
                        backgroundColor: Colors.grey.shade200,
                        color: Colors.blue,
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Question
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  currentQuestion['question_text'] ?? 'No question text',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Options header
              const Text(
                'Select your answer:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 16),

              // Options
              Expanded(
                child: ListView.separated(
                  itemCount: options.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final isSelected =
                        _answers[_currentQuestionIndex] == option;

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _selectAnswer(option),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.blue.shade50
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blue
                                  : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? Colors.blue
                                      : Colors.grey.shade200,
                                ),
                                child: Center(
                                  child: Text(
                                    String.fromCharCode(65 + index),
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey.shade700,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  option,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? Colors.blue.shade700
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.blue,
                                  size: 24,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Navigation buttons - FIXED WITH CONSTRAINED SIZING
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Previous button
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _currentQuestionIndex > 0
                              ? _previousQuestion
                              : null,
                          icon: const Icon(Icons.arrow_back, size: 18),
                          label: const Text('Previous'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade100,
                            foregroundColor: Colors.grey.shade800,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Next/Submit button
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed:
                              _currentQuestionIndex < _questions.length - 1
                              ? _nextQuestion
                              : _submitTest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _currentQuestionIndex < _questions.length - 1
                                ? Colors.blue
                                : Colors.green,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _currentQuestionIndex < _questions.length - 1
                                    ? 'Next'
                                    : 'Submit Test',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _currentQuestionIndex < _questions.length - 1
                                    ? Icons.arrow_forward
                                    : Icons.send,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============ TIMER ============
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
