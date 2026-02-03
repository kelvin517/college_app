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

  @override
  void initState() {
    super.initState();
    _dashboardData = _loadDashboardData();
  }

  Future<Map<String, dynamic>> _loadDashboardData() async {
    try {
      // Fetch multiple data points in parallel with error handling
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
      // Return default values if there's an error
      return {
        'totalStudents': 0,
        'totalCourses': 0,
        'todayAttendance': [],
        'recentApplications': [],
        'upcomingEvents': [],
      };
    }
  }

  Future<int> _getTotalStudents() async {
    try {
      final response = await supabase
          .from('students')
          .select()
          .count(CountOption.exact);
      return response.count;
    } catch (e) {
      print('Error getting students count: $e');
      // Fallback to simple select if count doesn't work
      final response = await supabase.from('students').select('*');
      return response.length;
    }
  }

  Future<int> _getTotalCourses() async {
    try {
      final response = await supabase
          .from('courses')
          .select()
          .count(CountOption.exact);
      return response.count;
    } catch (e) {
      print('Error getting courses count: $e');
      final response = await supabase.from('courses').select('*');
      return response.length;
    }
  }

  Future<List<dynamic>> _getTodayAttendance() async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final response = await supabase
          .from('attendance')
          .select('''
            *,
            student:students(id, name, roll_number)
          ''')
          .eq('date', today)
          .order('created_at', ascending: false)
          .limit(10);
      return response;
    } catch (e) {
      print('Error getting attendance: $e');
      // Try without join if join fails
      try {
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final response = await supabase
            .from('attendance')
            .select('*')
            .eq('date', today)
            .order('created_at', ascending: false)
            .limit(10);
        return response;
      } catch (e2) {
        return [];
      }
    }
  }

  Future<List<dynamic>> _getRecentApplications() async {
    try {
      final response = await supabase
          .from('admission_applications')
          .select('''
            *,
            applicant:applicants(id, name, email)
          ''')
          .eq('status', 'pending')
          .order('created_at', ascending: false)
          .limit(5);
      return response;
    } catch (e) {
      print('Error getting applications: $e');
      // Try without join if join fails
      try {
        final response = await supabase
            .from('admission_applications')
            .select('*')
            .eq('status', 'pending')
            .order('created_at', ascending: false)
            .limit(5);
        return response;
      } catch (e2) {
        return [];
      }
    }
  }

  Future<List<dynamic>> _getUpcomingEvents() async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final response = await supabase
          .from('events')
          .select('*')
          .gte('date', today)
          .order('date', ascending: true)
          .limit(5);
      return response;
    } catch (e) {
      print('Error getting events: $e');
      return [];
    }
  }

  Future<void> logout(BuildContext context) async {
    await supabase.auth.signOut();
    if (!context.mounted) return;

    // Navigate to login screen - adjust route name as needed
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  Widget _buildStatsCard(IconData icon, String title, int count, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              radius: 24,
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              count.toString(),
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
    );
  }

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
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading dashboard',
                  style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _dashboardData = _loadDashboardData();
                    });
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data!;
        final user = supabase.auth.currentUser;

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _dashboardData = _loadDashboardData();
            });
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Section
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Icon(
                            Icons.school,
                            size: 32,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'College Dashboard',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.email ?? 'Admin User',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat(
                                  'EEEE, MMMM d, yyyy',
                                ).format(DateTime.now()),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Stats Grid
                const Text(
                  'Quick Stats',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    _buildStatsCard(
                      Icons.people,
                      'Total Students',
                      data['totalStudents'],
                      Colors.blue,
                    ),
                    _buildStatsCard(
                      Icons.book,
                      'Total Courses',
                      data['totalCourses'],
                      Colors.green,
                    ),
                    _buildStatsCard(
                      Icons.check_circle,
                      'Today\'s Attendance',
                      (data['todayAttendance'] as List).length,
                      Colors.orange,
                    ),
                    _buildStatsCard(
                      Icons.pending_actions,
                      'Pending Applications',
                      (data['recentApplications'] as List).length,
                      Colors.red,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Quick Actions
                const Text(
                  'Quick Actions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildActionButton(
                        Icons.person_add,
                        'Add Student',
                        Colors.blue,
                        () {
                          // Navigate to add student
                        },
                      ),
                      const SizedBox(width: 12),
                      _buildActionButton(
                        Icons.check_circle,
                        'Mark Attendance',
                        Colors.green,
                        () {
                          // Navigate to attendance
                        },
                      ),
                      const SizedBox(width: 12),
                      _buildActionButton(
                        Icons.add_circle,
                        'Create Course',
                        Colors.purple,
                        () {
                          // Navigate to create course
                        },
                      ),
                      const SizedBox(width: 12),
                      _buildActionButton(
                        Icons.announcement,
                        'New Notice',
                        Colors.orange,
                        () {
                          // Navigate to create announcement
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Recent Applications
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Applications',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'View All',
                          style: TextStyle(color: Colors.blue, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if ((data['recentApplications'] as List).isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 48,
                                color: Colors.green,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No Pending Applications',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Card(
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount:
                              (data['recentApplications'] as List).length,
                          itemBuilder: (context, index) {
                            final app = data['recentApplications'][index];
                            final applicant = app['applicant'] ?? {};
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.withOpacity(0.1),
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.blue,
                                ),
                              ),
                              title: Text(
                                applicant['name']?.toString() ??
                                    'Unknown Applicant',
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    app['course_id']?.toString() ?? 'No course',
                                  ),
                                  Text(
                                    applicant['email']?.toString() ??
                                        'No email',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                              trailing: Chip(
                                label: Text(
                                  (app['status']?.toString() ?? 'pending')
                                      .toUpperCase(),
                                  style: const TextStyle(fontSize: 10),
                                ),
                                backgroundColor:
                                    (app['status']?.toString() ?? 'pending') ==
                                        'pending'
                                    ? Colors.orange.withOpacity(0.2)
                                    : Colors.green.withOpacity(0.2),
                              ),
                              onTap: () {
                                // Navigate to application details
                              },
                            );
                          },
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 24),

                // Upcoming Events
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Upcoming Events',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'View All',
                          style: TextStyle(color: Colors.blue, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if ((data['upcomingEvents'] as List).isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.event_available,
                                size: 48,
                                color: Colors.blue,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No Upcoming Events',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...(data['upcomingEvents'] as List).map((event) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.event,
                                color: Colors.blue,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              event['title']?.toString() ?? 'Untitled Event',
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (event['description'] != null &&
                                    event['description'].toString().isNotEmpty)
                                  Text(
                                    event['description'].toString(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                const SizedBox(height: 4),
                                if (event['date'] != null)
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        DateFormat('MMM d, yyyy').format(
                                          DateTime.parse(
                                            event['date'].toString(),
                                          ),
                                        ),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            onTap: () {
                              // Navigate to event details
                            },
                          ),
                        );
                      }).toList(),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
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

  // ... (rest of the methods for other views remain similar with error handling) ...

  Widget _buildStudentsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          const Text(
            'Students Management',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'View, add, edit, and manage student records and information',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to students list
            },
            icon: const Icon(Icons.view_list),
            label: const Text('View All Students'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          [
            'Dashboard',
            'Students',
            'Courses',
            'Attendance',
            'Profile',
          ][_currentIndex],
        ),
        actions: _currentIndex == 0
            ? [
                IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: () {
                    // Navigate to notifications
                  },
                ),
              ]
            : null,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboardView(),
          _buildStudentsView(),
          _buildCoursesView(),
          _buildAttendanceView(),
          _buildProfileView(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Students'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Courses'),
          BottomNavigationBarItem(
            icon: Icon(Icons.checklist),
            label: 'Attendance',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  // Placeholder methods for other views (keep your existing implementations)
  Widget _buildCoursesView() {
    return Center(child: Text('Courses Management'));
  }

  Widget _buildAttendanceView() {
    return Center(child: Text('Attendance Management'));
  }

  Widget _buildProfileView() {
    final user = supabase.auth.currentUser;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            child: Text(user?.email?.substring(0, 1).toUpperCase() ?? 'A'),
          ),
          const SizedBox(height: 20),
          Text(user?.email ?? 'College Admin'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => logout(context),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
