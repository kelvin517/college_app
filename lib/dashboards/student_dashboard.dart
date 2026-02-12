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

  // College Selection Fields - FIXED
  List<Map<String, dynamic>> _allColleges = [];
  List<Map<String, dynamic>> _filteredColleges = [];
  String _searchQuery = '';
  bool _isLoadingColleges = false;
  final Set<String> _selectedColleges = {}; // For multi-select feature

  // Feedback Form Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();
  int _feedbackRating = 0;

  @override
  void initState() {
    super.initState();
    _loadStudentProfile();
    _loadColleges(); // Load colleges on init
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

  // FIXED: College loading method
  Future<void> _loadColleges() async {
    setState(() => _isLoadingColleges = true);
    try {
      final response = await supabase
          .from('colleges')
          .select('*')
          .eq('is_active', true)
          .order('name', ascending: true);

      setState(() {
        _allColleges = List<Map<String, dynamic>>.from(response);
        _filteredColleges = List.from(_allColleges);
        _isLoadingColleges = false;
      });
    } catch (e) {
      print('Error loading colleges: $e');
      setState(() {
        _allColleges = [];
        _filteredColleges = [];
        _isLoadingColleges = false;
      });
    }
  }

  // FIXED: Filter method with real-time updates
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
          final description =
              college['description']?.toString().toLowerCase() ?? '';

          return name.contains(query.toLowerCase()) ||
              location.contains(query.toLowerCase()) ||
              courses.contains(query.toLowerCase()) ||
              description.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  // FIXED: Clear search
  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _filteredColleges = List.from(_allColleges);
    });
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
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _navItems[_selectedIndex]['label'],
          style: TextStyle(
            fontSize: isSmallScreen ? 18 : 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: _showNotifications,
            tooltip: 'Notifications',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
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
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text(
                'Quick Test',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            )
          : null,
    );
  }

  Widget _buildDrawer(User? user) {
    return Drawer(
      elevation: 0,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.blue.shade700, Colors.blue.shade900],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 30,
                            child: Text(
                              user?.email?.substring(0, 1).toUpperCase() ?? 'S',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            user?.email ?? 'Student',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _studentProfile?['name'] ?? 'Student Account',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                ..._navItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return ListTile(
                    leading: Icon(
                      item['icon'],
                      color: _selectedIndex == index
                          ? Colors.blue
                          : Colors.grey,
                    ),
                    title: Text(
                      item['label'],
                      style: TextStyle(
                        color: _selectedIndex == index
                            ? Colors.blue
                            : Colors.black87,
                        fontWeight: _selectedIndex == index
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    selected: _selectedIndex == index,
                    selectedTileColor: Colors.blue.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onTap: () {
                      setState(() => _selectedIndex = index);
                      Navigator.pop(context);
                    },
                  );
                }),
                const Divider(height: 24),
                ListTile(
                  leading: const Icon(
                    Icons.settings_outlined,
                    color: Colors.grey,
                  ),
                  title: const Text('Settings'),
                  onTap: _showSettings,
                ),
                ListTile(
                  leading: const Icon(Icons.help_outline, color: Colors.grey),
                  title: const Text('Help & Support'),
                  onTap: _showHelp,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: SafeArea(
              child: ListTile(
                leading: const CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, size: 18, color: Colors.white),
                ),
                title: Text(
                  user?.email ?? 'Student',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showProfileDialog();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============ DASHBOARD HOME ============
  Widget _buildDashboardHome() {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(20.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.blue.shade50, Colors.white],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _studentProfile?['name']?.split(' ').first ?? 'Student',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ready to take your next test?',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Your Progress',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildStatsSection(),
                const SizedBox(height: 24),
                const Text(
                  'Quick Actions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildQuickActions(),
                const SizedBox(height: 24),
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
          crossAxisCount: 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1,
          children: [
            _buildStatCard(
              'Tests',
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
              'Apps',
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 9),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {
        'icon': Icons.quiz,
        'label': 'Take Test',
        'color': Colors.blue,
        'index': 2,
      },
      {
        'icon': Icons.school,
        'label': 'Colleges',
        'color': Colors.green,
        'index': 1,
      },
      {
        'icon': Icons.history,
        'label': 'Results',
        'color': Colors.orange,
        'index': 3,
      },
      {
        'icon': Icons.feedback,
        'label': 'Feedback',
        'color': Colors.purple,
        'index': 4,
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
        return _buildActionButton(
          icon: action['icon'] as IconData,
          label: action['label'] as String,
          onTap: () => setState(() => _selectedIndex = action['index'] as int),
          color: action['color'] as Color,
        );
      }).toList(),
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
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

  // ============ COLLEGE SELECTION - COMPLETELY FIXED ============
  Widget _buildCollegeSelection() {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Header with refresh button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Colleges',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadColleges,
                      tooltip: 'Refresh',
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Search Field - FIXED with proper constraints
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: _filterColleges,
                    controller: TextEditingController(text: _searchQuery),
                    decoration: InputDecoration(
                      hintText: 'Search colleges...',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: _clearSearch,
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Results count and filters
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _searchQuery.isEmpty
                          ? 'All Colleges (${_allColleges.length})'
                          : 'Search Results (${_filteredColleges.length})',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    if (_selectedColleges.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 14,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_selectedColleges.length} selected',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Colleges Grid
                _isLoadingColleges
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : _filteredColleges.isEmpty
                    ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                _searchQuery.isEmpty
                                    ? Icons.school_outlined
                                    : Icons.search_off,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'No colleges available'
                                    : 'No colleges found for "$_searchQuery"',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                              if (_searchQuery.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _clearSearch,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 10,
                                    ),
                                  ),
                                  child: const Text('Clear Search'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                    : _buildCollegeGrid(_filteredColleges),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollegeGrid(List<Map<String, dynamic>> colleges) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 600 ? 3 : 2;
    final childAspectRatio = screenWidth > 600 ? 1.2 : 0.95;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: colleges.length,
      itemBuilder: (context, index) {
        final college = colleges[index];
        final isSelected = _selectedColleges.contains(college['id']);
        return _buildCollegeCard(college, isSelected);
      },
    );
  }

  Widget _buildCollegeCard(Map<String, dynamic> college, bool isSelected) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.transparent,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _showCollegeDetails(college),
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // College Icon with selection indicator
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.blue.shade50
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.school,
                            size: 20,
                            color: isSelected
                                ? Colors.blue
                                : Colors.grey.shade600,
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

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
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 10,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            college['location'] ?? '',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Course Chips
                    if (college['courses'] != null) ...[
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children:
                            (college['courses'].toString().split(',').take(2))
                                .map(
                                  (course) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      course.trim(),
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.blue.shade700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    ],

                    const Spacer(),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                _toggleCollegeSelection(college['id']),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              side: BorderSide(
                                color: isSelected
                                    ? Colors.blue
                                    : Colors.grey.shade300,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              minimumSize: const Size(double.infinity, 32),
                            ),
                            child: Text(
                              isSelected ? 'Selected' : 'Select',
                              style: TextStyle(
                                fontSize: 11,
                                color: isSelected
                                    ? Colors.blue
                                    : Colors.grey.shade700,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.info_outline, size: 16),
                            onPressed: () => _showCollegeDetails(college),
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            tooltip: 'View Details',
                          ),
                        ),
                      ],
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

  // FIXED: Toggle college selection
  void _toggleCollegeSelection(String collegeId) {
    setState(() {
      if (_selectedColleges.contains(collegeId)) {
        _selectedColleges.remove(collegeId);
      } else {
        _selectedColleges.add(collegeId);
      }
    });
  }

  // FIXED: Show college details with proper constraints
  void _showCollegeDetails(Map<String, dynamic> college) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.school, color: Colors.blue),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          college['name'] ?? 'College Details',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          college['location'] ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            const Divider(height: 24),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Courses
                    const Text(
                      'Available Courses',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          (college['courses']?.toString().split(',') ??
                                  ['No courses listed'])
                              .map(
                                (course) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.blue.shade200,
                                    ),
                                  ),
                                  child: Text(
                                    course.trim(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),

                    const SizedBox(height: 24),

                    // Description
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      college['description'] ?? 'No description available',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Contact Information
                    const Text(
                      'Contact Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (college['email'] != null)
                      _buildContactTile(Icons.email, 'Email', college['email']),
                    if (college['website'] != null)
                      _buildContactTile(
                        Icons.link,
                        'Website',
                        college['website'],
                      ),
                    if (college['phone'] != null)
                      _buildContactTile(Icons.phone, 'Phone', college['phone']),
                  ],
                ),
              ),
            ),

            // Action Button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _toggleCollegeSelection(college['id']);
                      },
                      icon: Icon(
                        _selectedColleges.contains(college['id'])
                            ? Icons.check_circle
                            : Icons.add_circle_outline,
                        size: 18,
                      ),
                      label: Text(
                        _selectedColleges.contains(college['id'])
                            ? 'Remove from Selection'
                            : 'Add to Selection',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _selectedColleges.contains(college['id'])
                            ? Colors.red.shade50
                            : Colors.blue.shade50,
                        foregroundColor:
                            _selectedColleges.contains(college['id'])
                            ? Colors.red
                            : Colors.blue,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: _selectedColleges.contains(college['id'])
                                ? Colors.red.shade200
                                : Colors.blue.shade200,
                          ),
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
    );
  }

  Widget _buildContactTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============ TEST SELECTION ============
  Widget _buildTestSelection() {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
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
                    const SizedBox(height: 8),
                    const Text(
                      'Select a test to assess your knowledge',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    ...tests.map((test) => _buildTestCard(test)).toList(),
                    if (tests.isEmpty) ...[
                      const SizedBox(height: 40),
                      const Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.quiz_outlined,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No tests available',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TestScreen(
                  testId: test['id'].toString(),
                  testData: test,
                  selectedColleges: _selectedColleges
                      .toList(), // Pass selected colleges
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.quiz, color: Colors.blue),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        test['name'] ?? 'Unnamed Test',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${test['duration']} min',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${test['total_questions']} Qs',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============ TEST HISTORY ============
  Widget _buildTestHistory() {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
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
                    const SizedBox(height: 8),
                    const Text(
                      'Your previous test attempts',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    if (history.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              Icon(
                                Icons.history_outlined,
                                size: 48,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No test history yet',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Take your first test to see results here',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getScoreColor(percentage).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                percentage >= 70 ? Icons.emoji_events : Icons.assignment,
                color: _getScoreColor(percentage),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    testData['name'] ?? 'Unknown Test',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Score: ${test['score']}/${test['total_questions']}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _getScoreColor(percentage).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getScoreColor(percentage).withOpacity(0.3),
                ),
              ),
              child: Text(
                '$percentage%',
                style: TextStyle(
                  color: _getScoreColor(percentage),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(int percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.blue;
    if (percentage >= 40) return Colors.orange;
    return Colors.red;
  }

  // ============ FEEDBACK SECTION - FIXED ============
  Widget _buildFeedbackSection() {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(20.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const Text(
                  'Feedback',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Help us improve your experience',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 24),
                _buildFeedbackForm(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackForm() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Field
          const Text(
            'Title',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Brief summary of your feedback',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Rating
          const Text(
            'Rating',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
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
                  size: 32,
                ),
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
              );
            }),
          ),
          const SizedBox(height: 20),

          // Feedback Text
          const Text(
            'Your Feedback',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextFormField(
              controller: _feedbackController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Share your experience, suggestions, or issues...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _submitFeedback,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Submit Feedback',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitFeedback() async {
    if (_titleController.text.isEmpty ||
        _feedbackController.text.isEmpty ||
        _feedbackRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill all fields'),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
        ),
      );
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
        SnackBar(
          content: const Text('Thank you for your feedback!'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      print('Error submitting feedback: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting feedback: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _showNotifications() {
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
              'Notifications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('No new notifications'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Settings coming soon...'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Close'),
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Contact: support@collegeportal.com'),
            const Text('Phone: +1 800-TEST-HELP'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileDialog() {
    final user = supabase.auth.currentUser;
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
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blue,
              child: Text(
                user?.email?.substring(0, 1).toUpperCase() ?? 'S',
                style: const TextStyle(fontSize: 32, color: Colors.white),
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
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Close'),
            ),
          ],
        ),
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
            selectedColleges: _selectedColleges
                .toList(), // Pass selected colleges
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No tests available'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
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

        // Send results to selected colleges
        if (widget.selectedColleges.isNotEmpty) {
          for (final collegeId in widget.selectedColleges) {
            await supabase.from('college_test_results').insert({
              'college_id': collegeId,
              'student_id': user.id,
              'score': score,
              'percentage': percentage,
              'test_name': widget.testData?['name'] ?? 'Test',
              'submitted_at': DateTime.now().toIso8601String(),
            });
          }
        }
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
            if (widget.selectedColleges.isNotEmpty)
              Text(
                'Results sent to ${widget.selectedColleges.length} college(s)',
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
              Icon(Icons.quiz_outlined, size: 60, color: Colors.grey),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

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
        title: Text(
          widget.testData?['name'] ?? 'Test',
          style: TextStyle(
            fontSize: isSmallScreen ? 16 : 18,
            fontWeight: FontWeight.w600,
          ),
        ),
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
              border: Border.all(
                color: _timeRemaining < 300
                    ? Colors.red.shade200
                    : Colors.blue.shade200,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer,
                  size: 16,
                  color: _timeRemaining < 300 ? Colors.red : Colors.blue,
                ),
                const SizedBox(width: 6),
                Text(
                  _formatTime(_timeRemaining),
                  style: TextStyle(
                    fontSize: 13,
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
          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress bar
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_answers.length}/${_questions.length}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade700,
                            ),
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

              const SizedBox(height: 20),

              // Question
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  currentQuestion['question_text'] ?? 'No question text',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                    color: Colors.blue.shade900,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Options header
              const Text(
                'Select your answer:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 16),

              // Options
              Expanded(
                child: ListView.separated(
                  itemCount: options.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
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
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 14 : 16,
                            vertical: isSmallScreen ? 12 : 14,
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
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  option,
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 14 : 15,
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
                                  size: 22,
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

              // Navigation buttons - FIXED LAYOUT
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                child: Row(
                  children: [
                    // Previous button
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: _currentQuestionIndex > 0
                              ? _previousQuestion
                              : null,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.arrow_back, size: 18),
                              const SizedBox(width: 6),
                              const Text('Previous'),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

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
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _currentQuestionIndex < _questions.length - 1
                                    ? 'Next'
                                    : 'Submit',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                _currentQuestionIndex < _questions.length - 1
                                    ? Icons.arrow_forward
                                    : Icons.send,
                                size: 16,
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
