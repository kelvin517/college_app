import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  SupabaseService() {
    _initializeAuthListener();
    _checkCurrentSession();
  }

  void _checkCurrentSession() {
    final session = _supabase.auth.currentSession;
    if (session != null) {
      print('📱 Existing session found for: ${session.user.email}');
      _currentUser = session.user;
      notifyListeners();
    } else {
      print('📱 No existing session found');
    }
  }

  void _initializeAuthListener() {
    _supabase.auth.onAuthStateChange.listen((data) {
      print('🔐 Auth state changed: ${data.event}');
      _currentUser = data.session?.user;
      notifyListeners();
    });
  }

  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  Future<bool> adminLogin(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      print('🔐 Attempting admin login for: $email');

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Check if user is null
      if (response.user == null) {
        print('❌ Auth failed: No user returned');
        _setError('Invalid credentials');
        return false;
      }

      // Safe to access user now
      print('✅ Auth successful for: ${response.user!.email}');
      print('👤 User ID: ${response.user!.id}');

      // Check if user is admin
      final isAdmin = await _checkIfAdmin(response.user!.id);

      if (!isAdmin) {
        print('🚫 User is not an admin, signing out...');
        await _supabase.auth.signOut();
        _setError('Access denied. Admin privileges required.');
        return false;
      }

      print('✅ Admin login successful');
      _currentUser = response.user;
      return true;
    } on AuthException catch (e) {
      print('❌ Auth error: ${e.message}');
      _setError(e.message);
      return false;
    } catch (e) {
      print('❌ Unexpected error: $e');
      _setError('An unexpected error occurred');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> _checkIfAdmin(String userId) async {
    try {
      final response = await _supabase
          .from('admin_users')
          .select('id, role')
          .eq('auth_id', userId)
          .maybeSingle();

      if (response != null) {
        print('✅ Admin check passed: ${response['role']}');
        return true;
      } else {
        print('❌ Admin check failed: No admin record found');
        return false;
      }
    } catch (e) {
      print('❌ Error checking admin status: $e');
      return false;
    }
  }

  Future<void> adminLogout() async {
    try {
      print('🔐 Logging out admin...');
      await _supabase.auth.signOut();
      _currentUser = null;
      print('✅ Logout successful');
    } catch (e) {
      print('❌ Logout error: $e');
      _currentUser = null;
    } finally {
      notifyListeners();
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // Keep your existing methods for getting colleges, students, etc.
  Future<List<Map<String, dynamic>>> getColleges() async {
    try {
      final response = await _supabase
          .from('colleges')
          .select('*')
          .order('name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting colleges: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getStudents() async {
    try {
      final response = await _supabase
          .from('students')
          .select('*')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting students: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final studentsCount = await _supabase
          .from('students')
          .select('count')
          .count(CountOption.exact);

      final collegesCount = await _supabase
          .from('colleges')
          .select('count')
          .count(CountOption.exact);

      final testsCount = await _supabase
          .from('tests')
          .select('count')
          .count(CountOption.exact);

      return {
        'users': studentsCount.count ?? 0,
        'colleges': collegesCount.count ?? 0,
        'tests': testsCount.count ?? 0,
      };
    } catch (e) {
      print('Error getting statistics: $e');
      return {'users': 0, 'colleges': 0, 'tests': 0};
    }
  }

  Future<void> addCollege(Map<String, dynamic> collegeData) async {
    try {
      await _supabase.from('colleges').insert(collegeData);
    } catch (e) {
      print('Error adding college: $e');
      rethrow;
    }
  }

  Future<void> updateCollege(
    String id,
    Map<String, dynamic> collegeData,
  ) async {
    try {
      await _supabase.from('colleges').update(collegeData).eq('id', id);
    } catch (e) {
      print('Error updating college: $e');
      rethrow;
    }
  }

  Future<void> deleteCollege(String id) async {
    try {
      await _supabase.from('colleges').delete().eq('id', id);
    } catch (e) {
      print('Error deleting college: $e');
      rethrow;
    }
  }

  Future<void> addStudent(Map<String, dynamic> studentData) async {
    try {
      await _supabase.from('students').insert(studentData);
    } catch (e) {
      print('Error adding student: $e');
      rethrow;
    }
  }

  Future<void> updateStudent(
    String id,
    Map<String, dynamic> studentData,
  ) async {
    try {
      await _supabase.from('students').update(studentData).eq('id', id);
    } catch (e) {
      print('Error updating student: $e');
      rethrow;
    }
  }
}
