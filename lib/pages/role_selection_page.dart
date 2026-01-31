import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  bool _loading = false;

  final supabase = Supabase.instance.client;

  Future<void> _selectRole(String role) async {
    setState(() => _loading = true);

    final user = supabase.auth.currentUser;

    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      await supabase.from('profiles').upsert({
        'id': user.id,
        'email': user.email,
        'role': role,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving role: $e')),
      );
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Role'),
        centerTitle: true,
      ),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _roleButton(
                    icon: Icons.school,
                    label: 'Student',
                    onTap: () => _selectRole('student'),
                  ),
                  const SizedBox(height: 20),
                  _roleButton(
                    icon: Icons.admin_panel_settings,
                    label: 'Admin',
                    onTap: () => _selectRole('admin'),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _roleButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 250,
      height: 55,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 24),
        label: Text(
          label,
          style: const TextStyle(fontSize: 18),
        ),
        onPressed: onTap,
      ),
    );
  }
}
