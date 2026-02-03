import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final supabase = Supabase.instance.client;
  int _selectedIndex = 0;

  // Dashboard sections
  final List<Widget> _dashboardSections = [
    const DashboardHome(),
    const CollegeSelection(),
    const MyApplications(),
    const TestHistory(),
    const ProfileSection(),
  ];

  // Navigation items
  final List<Map<String, dynamic>> _navItems = [
    {'icon': Icons.home, 'label': 'Home'},
    {'icon': Icons.school, 'label': 'Colleges'},
    {'icon': Icons.assignment, 'label': 'Applications'},
    {'icon': Icons.history, 'label': 'Test History'},
    {'icon': Icons.person, 'label': 'Profile'},
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
      floatingActionButton:
          _selectedIndex ==
              1 // Show FAB on College Selection page
          ? FloatingActionButton(
              onPressed: _showCollegeSearch,
              child: const Icon(Icons.search),
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
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 30,
                  child: Text(
                    user?.email?.substring(0, 1).toUpperCase() ?? 'S',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  user?.email ?? 'Student',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Student Account',
                  style: TextStyle(color: Colors.white70),
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
            leading: const Icon(Icons.feedback, color: Colors.grey),
            title: const Text('Feedback'),
            onTap: _showFeedbackForm,
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
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.school, color: Colors.blue),
              title: Text('Application Update'),
              subtitle: Text('Your MIT application is under review'),
            ),
            ListTile(
              leading: Icon(Icons.assignment, color: Colors.green),
              title: Text('Test Reminder'),
              subtitle: Text('Computer Science test tomorrow'),
            ),
            ListTile(
              leading: Icon(Icons.info, color: Colors.orange),
              title: Text('System Update'),
              subtitle: Text('New features available'),
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

  void _showCollegeSearch() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Colleges'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Enter college name or location...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Perform search
                },
                child: const Text('Search'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.notifications),
              title: Text('Notification Settings'),
            ),
            ListTile(
              leading: Icon(Icons.security),
              title: Text('Privacy & Security'),
            ),
            ListTile(leading: Icon(Icons.language), title: Text('Language')),
            ListTile(leading: Icon(Icons.help), title: Text('Help & Support')),
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

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Need assistance? Here are your options:'),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.email),
              title: Text('Email Support'),
              subtitle: Text('support@collegeadmission.com'),
            ),
            ListTile(
              leading: Icon(Icons.phone),
              title: Text('Call Support'),
              subtitle: Text('+1 800-123-4567'),
            ),
            ListTile(
              leading: Icon(Icons.chat),
              title: Text('Live Chat'),
              subtitle: Text('Available 9 AM - 5 PM'),
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

  void _showFeedbackForm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Feedback'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Your Feedback',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thank you for your feedback!')),
              );
            },
            child: const Text('Submit'),
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
      await supabase.auth.signOut();

      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const Scaffold()),
        (_) => false,
      );
    }
  }
}

// ========== Dashboard Home ==========
class DashboardHome extends StatelessWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome Back!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            'Ready to explore colleges and take tests?',
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
                'Applied Colleges',
                '3',
                Colors.blue,
                Icons.school,
              ),
              _buildStatCard(
                'Tests Taken',
                '5',
                Colors.green,
                Icons.assignment,
              ),
              _buildStatCard(
                'Avg Score',
                '85%',
                Colors.orange,
                Icons.leaderboard,
              ),
              _buildStatCard(
                'Notifications',
                '2',
                Colors.purple,
                Icons.notifications,
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
                label: 'Browse Colleges',
                onTap: () {
                  // Navigate to colleges
                },
                color: Colors.blue,
              ),
              _buildActionButton(
                icon: Icons.assignment,
                label: 'Take Test',
                onTap: () {
                  _showTestSelection(context);
                },
                color: Colors.green,
              ),
              _buildActionButton(
                icon: Icons.history,
                label: 'View Results',
                onTap: () {
                  // Navigate to test history
                },
                color: Colors.orange,
              ),
              _buildActionButton(
                icon: Icons.person,
                label: 'My Profile',
                onTap: () {
                  // Navigate to profile
                },
                color: Colors.purple,
              ),
            ],
          ),
        ],
      ),
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

  static void _showTestSelection(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Test'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.school, color: Colors.blue),
              title: const Text('Computer Science Test'),
              subtitle: const Text('50 questions - 60 minutes'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to test screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.school, color: Colors.green),
              title: const Text('Engineering Test'),
              subtitle: const Text('40 questions - 45 minutes'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to test screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.school, color: Colors.orange),
              title: const Text('Medical Test'),
              subtitle: const Text('60 questions - 75 minutes'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to test screen
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

// ========== College Selection ==========
class CollegeSelection extends StatelessWidget {
  const CollegeSelection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search colleges...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Available Colleges',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 0.9,
              children: [
                _buildCollegeCard(
                  name: 'MIT',
                  location: 'Cambridge, MA',
                  courses: 'Engineering, CS',
                  color: Colors.red,
                ),
                _buildCollegeCard(
                  name: 'Stanford',
                  location: 'Stanford, CA',
                  courses: 'Business, Medicine',
                  color: Colors.blue,
                ),
                _buildCollegeCard(
                  name: 'Harvard',
                  location: 'Cambridge, MA',
                  courses: 'Law, Business',
                  color: Colors.green,
                ),
                _buildCollegeCard(
                  name: 'Caltech',
                  location: 'Pasadena, CA',
                  courses: 'Science, Engineering',
                  color: Colors.orange,
                ),
                _buildCollegeCard(
                  name: 'Princeton',
                  location: 'Princeton, NJ',
                  courses: 'Humanities, Sciences',
                  color: Colors.purple,
                ),
                _buildCollegeCard(
                  name: 'Yale',
                  location: 'New Haven, CT',
                  courses: 'Arts, Law',
                  color: Colors.teal,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildCollegeCard({
    required String name,
    required String location,
    required String courses,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      child: InkWell(
        onTap: () {
          // Navigate to college details
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.2),
                child: Icon(Icons.school, color: color),
              ),
              const SizedBox(height: 10),
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                location,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 5),
              Text(
                courses,
                style: const TextStyle(fontSize: 11),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Apply to college
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 30),
                      ),
                      child: const Text('Apply'),
                    ),
                  ),
                  const SizedBox(width: 5),
                  IconButton(
                    icon: const Icon(Icons.info_outline, size: 20),
                    onPressed: () {
                      // Show college details
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ========== My Applications ==========
class MyApplications extends StatelessWidget {
  const MyApplications({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Applications',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Track your college applications',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                _buildApplicationCard(
                  college: 'MIT',
                  program: 'Computer Science',
                  status: 'Under Review',
                  date: '2024-01-15',
                  color: Colors.blue,
                ),
                _buildApplicationCard(
                  college: 'Stanford',
                  program: 'MBA',
                  status: 'Submitted',
                  date: '2024-01-10',
                  color: Colors.green,
                ),
                _buildApplicationCard(
                  college: 'Harvard',
                  program: 'Law',
                  status: 'Rejected',
                  date: '2023-12-20',
                  color: Colors.red,
                ),
                _buildApplicationCard(
                  college: 'Caltech',
                  program: 'Engineering',
                  status: 'Accepted',
                  date: '2024-01-05',
                  color: Colors.orange,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildApplicationCard({
    required String college,
    required String program,
    required String status,
    required String date,
    required Color color,
  }) {
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
                  backgroundColor: color.withOpacity(0.2),
                  child: Text(
                    college.substring(0, 1),
                    style: TextStyle(color: color),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        college,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(program),
                    ],
                  ),
                ),
                Chip(
                  label: Text(status),
                  backgroundColor: _getStatusColor(status).withOpacity(0.2),
                  labelStyle: TextStyle(color: _getStatusColor(status)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Applied: $date'),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility, size: 20),
                      onPressed: () {
                        // View application details
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () {
                        // Edit application
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      onPressed: () {
                        // Delete application
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'under review':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }
}

// ========== Test History ==========
class TestHistory extends StatelessWidget {
  const TestHistory({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Test History',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'View your test results and performance',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                _buildTestCard(
                  testName: 'Computer Science Assessment',
                  college: 'MIT',
                  score: 85,
                  total: 100,
                  date: '2024-01-20',
                ),
                _buildTestCard(
                  testName: 'Engineering Aptitude',
                  college: 'Stanford',
                  score: 78,
                  total: 100,
                  date: '2024-01-18',
                ),
                _buildTestCard(
                  testName: 'Medical Entrance',
                  college: 'Harvard Medical',
                  score: 92,
                  total: 100,
                  date: '2024-01-15',
                ),
                _buildTestCard(
                  testName: 'Business Management',
                  college: 'Wharton',
                  score: 81,
                  total: 100,
                  date: '2024-01-10',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildTestCard({
    required String testName,
    required String college,
    required int score,
    required int total,
    required String date,
  }) {
    final percentage = (score / total * 100).toInt();

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              testName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 5),
            Text('College: $college'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Score: $score/$total',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      LinearProgressIndicator(
                        value: score / total,
                        backgroundColor: Colors.grey.shade300,
                        color: _getScoreColor(percentage),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                CircleAvatar(
                  backgroundColor: _getScoreColor(percentage).withOpacity(0.2),
                  child: Text(
                    '$percentage%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getScoreColor(percentage),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Date: $date'),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        // View detailed results
                      },
                      child: const Text('View Details'),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () {
                        // Retake test
                      },
                      child: const Text('Retake'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Color _getScoreColor(int percentage) {
    if (percentage >= 85) return Colors.green;
    if (percentage >= 70) return Colors.orange;
    return Colors.red;
  }
}

// ========== Profile Section ==========
class ProfileSection extends StatelessWidget {
  const ProfileSection({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    user?.email?.substring(0, 1).toUpperCase() ?? 'S',
                    style: const TextStyle(fontSize: 36, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  user?.email ?? 'Student',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text('Student Account'),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            'Profile Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildProfileItem(
                    icon: Icons.person,
                    label: 'Full Name',
                    value: 'John Doe',
                    editable: true,
                  ),
                  _buildProfileItem(
                    icon: Icons.email,
                    label: 'Email',
                    value: user?.email ?? 'Not set',
                    editable: false,
                  ),
                  _buildProfileItem(
                    icon: Icons.phone,
                    label: 'Phone',
                    value: '+1 234 567 8900',
                    editable: true,
                  ),
                  _buildProfileItem(
                    icon: Icons.location_on,
                    label: 'Address',
                    value: '123 Main St, City, Country',
                    editable: true,
                  ),
                  _buildProfileItem(
                    icon: Icons.school,
                    label: 'Education',
                    value: 'High School Graduate',
                    editable: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Edit profile
              },
              child: const Text('Edit Profile'),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildProfileItem({
    required IconData icon,
    required String label,
    required String value,
    required bool editable,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(value, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
          if (editable)
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () {
                // Edit this field
              },
            ),
        ],
      ),
    );
  }
}
