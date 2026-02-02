import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'role_selection_page.dart';
import '../dashboards/admin_dashboard.dart';
import '../dashboards/student_dashboard.dart';
import '../dashboards/college_dashboard.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Stream<AuthState> _authStateStream;

  @override
  void initState() {
    super.initState();
    _authStateStream = Supabase.instance.client.auth.onAuthStateChange;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _authStateStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        final session = snapshot.data?.session;

        if (session == null) {
          return const RoleSelectionPage();
        }

        return FutureBuilder(
          future: Supabase.instance.client
              .from('profiles')
              .select('role, name, email')
              .eq('id', session.user.id)
              .single(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const SplashScreen();
            }

            if (profileSnapshot.hasError || !profileSnapshot.hasData) {
              // If profile doesn't exist, sign out and go to role selection
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Supabase.instance.client.auth.signOut();
              });
              return const RoleSelectionPage();
            }

            final profile = profileSnapshot.data!;
            final role = profile['role'] as String;

            // Navigate to appropriate dashboard
            switch (role) {
              case 'student':
                return const StudentDashboard();
              case 'college':
                return const CollegeDashboard();
              case 'admin':
                return const AdminDashboard();
              default:
                return const RoleSelectionPage();
            }
          },
        );
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.school, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 30),
            const Text(
              'College Admission Portal',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 10),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
