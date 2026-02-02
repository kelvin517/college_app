import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Added for kDebugMode
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  final String role;
  const RegisterPage({super.key, required this.role});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final nameController = TextEditingController();
  bool isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String getRoleTitle() {
    switch (widget.role) {
      case 'student':
        return 'Student';
      case 'college':
        return 'College';
      case 'admin':
        return 'Admin';
      default:
        return 'User';
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      print('Starting registration process...');

      // Validate passwords match
      if (passwordController.text != confirmPasswordController.text) {
        _showError('Passwords do not match');
        setState(() => isLoading = false);
        return;
      }

      final email = emailController.text.trim();
      final password = passwordController.text.trim();
      final name = nameController.text.trim();

      print('Registration details:');
      print('Email: $email');
      print('Password length: ${password.length}');
      print('Name: $name');
      print('Role: ${widget.role}');

      // Register user in Supabase Auth
      print('Calling Supabase signUp...');
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name, 'role': widget.role},
      );

      print('SignUp response received');
      print('User: ${response.user?.email}');
      print('Session: ${response.session}');

      // Check for errors in a different way
      if (response.user != null) {
        print('User created successfully, creating profile...');

        // Create profile in profiles table
        final profileResult = await Supabase.instance.client
            .from('profiles')
            .upsert({
              'id': response.user!.id,
              'email': email,
              'name': name,
              'role': widget.role,
              'created_at': DateTime.now().toIso8601String(),
            });

        // Check if profile creation had errors
        if (profileResult.hasError) {
          print('Profile creation failed: ${profileResult.error?.message}');
          _showError('Profile creation failed. Please try again.');
          setState(() => isLoading = false);
          return;
        }

        print('Registration completed successfully!');
        _showSuccess('Registration successful! Welcome $name');

        // Navigate to login page
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => LoginPage(role: widget.role)),
          (route) => false,
        );
      } else {
        print('Registration failed - no user created');
        // Check if there was an error in the response
        if (response.session == null && response.user == null) {
          _showError(
            'Registration failed. Please check your credentials and try again.',
          );
        } else {
          _showError('Registration failed. Please try again.');
        }
      }
    } on AuthException catch (e) {
      print('AuthException caught: ${e.message}');
      String errorMessage;

      if (e.message.toLowerCase().contains('already registered') ||
          e.message.toLowerCase().contains('user already exists') ||
          e.message.toLowerCase().contains('user with email')) {
        errorMessage = 'Email already registered. Please login instead.';
      } else if (e.message.toLowerCase().contains('weak password') ||
          e.message.toLowerCase().contains('password should')) {
        errorMessage =
            'Password is too weak. Use at least 6 characters with letters and numbers.';
      } else if (e.message.toLowerCase().contains('invalid email') ||
          e.message.toLowerCase().contains('valid email')) {
        errorMessage = 'Please enter a valid email address.';
      } else if (e.message.toLowerCase().contains('rate limit') ||
          e.message.toLowerCase().contains('too many requests')) {
        errorMessage = 'Too many attempts. Please wait a moment and try again.';
      } else {
        errorMessage = 'Registration failed: ${e.message}';
      }

      _showError(errorMessage);
    } catch (e) {
      print('General exception: $e');
      print('Exception type: ${e.runtimeType}');
      _showError(
        'An unexpected error occurred. Please check your connection and try again.',
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Test Supabase connection button (for debugging)
  Widget _buildTestButton() {
    return ElevatedButton(
      onPressed: testSupabaseConnection,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text(
        'Test Supabase Connection',
        style: TextStyle(fontSize: 14),
      ),
    );
  }

  Future<void> testSupabaseConnection() async {
    print('=== SUPABASE CONNECTION TEST ===');

    try {
      final client = Supabase.instance.client;
      print('1. Supabase client available');

      final session = client.auth.currentSession;
      print('2. Current session: ${session?.user.email ?? "No session"}');

      print('3. Testing simple query...');
      final response = await client.from('profiles').select('count');
      print('Query response: $response');

      print('✅ Supabase connection is working!');

      _showSuccess('Supabase connection successful!');
    } catch (e) {
      print('❌ Supabase connection failed: $e');
      _showError('Connection failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register as ${getRoleTitle()}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                ),
                child: Icon(
                  widget.role == 'student'
                      ? Icons.school
                      : widget.role == 'college'
                      ? Icons.business
                      : Icons.admin_panel_settings,
                  size: 40,
                  color: Colors.deepPurple,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Create ${getRoleTitle()} Account',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              const Text(
                'Fill in your details to get started',
                style: TextStyle(color: Colors.grey, fontSize: 16),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Name Field
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                  hintText: 'Enter your full name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  if (value.length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Email Field
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email),
                  hintText: 'Enter your email address',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Password Field
              TextFormField(
                controller: passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  hintText: 'At least 6 characters',
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Confirm Password Field
              TextFormField(
                controller: confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 30),

              // Password requirements
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Password requirements:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• At least 6 characters',
                      style: TextStyle(
                        color: passwordController.text.length >= 6
                            ? Colors.green
                            : Colors.grey,
                      ),
                    ),
                    Text(
                      '• Use letters and numbers',
                      style: TextStyle(
                        color:
                            RegExp(
                                  r'[A-Za-z]',
                                ).hasMatch(passwordController.text) &&
                                RegExp(
                                  r'[0-9]',
                                ).hasMatch(passwordController.text)
                            ? Colors.green
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Register Button
              ElevatedButton(
                onPressed: isLoading ? null : register,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.deepPurple,
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Create Account',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),

              const SizedBox(height: 20),

              // Test Connection Button (for debugging - optional)
              if (kDebugMode) ...[
                _buildTestButton(),
                const SizedBox(height: 10),
              ],

              // Login Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account?'),
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LoginPage(role: widget.role),
                              ),
                            );
                          },
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
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
