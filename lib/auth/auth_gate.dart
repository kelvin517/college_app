import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../pages/login_page.dart';
import '../pages/role_selection_page.dart';
import '../pages/student_home.dart';
import '../pages/admin_home.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;

        // Not logged in
        if (session == null) {
          return const LoginPage();
        }

        // Logged in → check role
        return FutureBuilder(
          future: Supabase.instance.client
              .from('profiles')
              .select('role')
              .eq('id', session.user.id)
              .maybeSingle(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // No role yet
            if (!snap.hasData || snap.data == null) {
              return RoleSelectionPage(); // ✅ no const
            }

            final role = snap.data!['role'];

            if (role == 'student') return StudentHome();
            if (role == 'admin') return AdminHome();

            return RoleSelectionPage();
          },
        );
      },
    );
  }
}
