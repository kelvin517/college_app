import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Admin Authentication
  Future<bool> adminLogin(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Check if user is admin
        final userData = await _supabase
            .from('users')
            .select()
            .eq('id', response.user!.id)
            .single();

        return userData['role'] == 'admin';
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<void> adminLogout() async {
    await _supabase.auth.signOut();
  }

  // College Management
  Future<void> addCollege(Map<String, dynamic> collegeData) async {
    await _supabase.from('colleges').insert(collegeData);
  }

  Future<List<Map<String, dynamic>>> getColleges() async {
    final response = await _supabase.from('colleges').select();
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateCollege(String id, Map<String, dynamic> data) async {
    await _supabase.from('colleges').update(data).eq('id', id);
  }

  Future<void> deleteCollege(String id) async {
    await _supabase.from('colleges').delete().eq('id', id);
  }

  // Student Management
  Future<void> addStudent(Map<String, dynamic> studentData) async {
    await _supabase.from('students').insert(studentData);
  }

  Future<List<Map<String, dynamic>>> getStudents() async {
    final response = await _supabase.from('students').select();
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateStudent(String id, Map<String, dynamic> data) async {
    await _supabase.from('students').update(data).eq('id', id);
  }

  // Test Management
  Future<void> addTest(Map<String, dynamic> testData) async {
    await _supabase.from('tests').insert(testData);
  }

  Future<List<Map<String, dynamic>>> getTests() async {
    final response = await _supabase.from('tests').select();
    return List<Map<String, dynamic>>.from(response);
  }

  // User Statistics - FIXED: Remove count parameter
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      // Get counts using separate queries
      final usersResponse = await _supabase.from('users').select();
      final collegesResponse = await _supabase.from('colleges').select();
      final testsResponse = await _supabase.from('tests').select();

      return {
        'users': (usersResponse as List).length,
        'colleges': (collegesResponse as List).length,
        'tests': (testsResponse as List).length,
      };
    } catch (e) {
      print('Error getting statistics: $e');
      return {'users': 0, 'colleges': 0, 'tests': 0};
    }
  }

  // Get current admin user
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }
}
