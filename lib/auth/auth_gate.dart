import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
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

        return FutureBuilder<Map<String, dynamic>?>(
          future: _getUserProfile(session.user.id),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const SplashScreen();
            }

            // Handle error or no profile
            if (profileSnapshot.hasError || profileSnapshot.data == null) {
              print('❌ Profile error: ${profileSnapshot.error}');
              // Sign out and return to role selection
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _handleSignOut();
              });
              return const RoleSelectionPage();
            }

            final profile = profileSnapshot.data!;
            final role = profile['role'] as String;

            print('✅ User role: $role');

            // Update SupabaseService with current user
            final supabaseService = Provider.of<SupabaseService>(
              context,
              listen: false,
            );

            // You might want to update the service with user info
            // supabaseService.setCurrentUser(session.user);

            // Navigate to appropriate dashboard
            switch (role) {
              case 'student':
                return const StudentDashboard();
              case 'college':
                return const CollegeDashboard();
              case 'admin':
                return const AdminDashboard();
              default:
                print('❌ Unknown role: $role');
                return const RoleSelectionPage();
            }
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _getUserProfile(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('role, name, email')
          .eq('id', userId)
          .maybeSingle();

      print('📊 Profile response: $response');
      return response;
    } catch (e) {
      print('❌ Error fetching profile: $e');
      return null;
    }
  }

  Future<void> _handleSignOut() async {
    try {
      await Supabase.instance.client.auth.signOut();

      // Update provider if needed
      if (mounted) {
        final supabaseService = Provider.of<SupabaseService>(
          context,
          listen: false,
        );
        // Clear any user data in the service
        // supabaseService.clearUserData();
      }
    } catch (e) {
      print('❌ Sign out error: $e');
    }
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
            // Animated logo
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.elasticOut,
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.deepPurple.shade400,
                          Colors.deepPurple.shade700,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.school,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            const Text(
              'College Admission Portal',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
            ),
            const SizedBox(height: 20),
            Text(
              'Loading your dashboard...',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
