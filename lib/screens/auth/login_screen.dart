import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../home/home_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      _goToHome();
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      String msg = 'Login failed!';
      if (e.code == 'user-not-found') msg = 'No user found with this email!';
      if (e.code == 'wrong-password') msg = 'Wrong password!';
      if (e.code == 'invalid-email') msg = 'Invalid email address!';
      _showSnack(msg, isError: true);
    }
  }

  void _goToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, AppColors.primaryDark],
            stops: [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: 40.h),

              // Logo
              Container(
                width: 80.w,
                height: 80.w,
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.directions_car_rounded,
                    size: 44.sp, color: AppColors.white),
              ),
              SizedBox(height: 12.h),
              Text(
                AppStrings.appName,
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
              Text(
                AppStrings.tagline,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.white.withOpacity(0.8),
                ),
              ),

              SizedBox(height: 32.h),

              // White Card
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32.r),
                      topRight: Radius.circular(32.r),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 8.h),
                          Text(
                            'Welcome Back! 👋',
                            style: TextStyle(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Login to continue your journey',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),

                          SizedBox(height: 32.h),

                          // Email
                          _buildLabel('Email Address'),
                          SizedBox(height: 8.h),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: (val) {
                              if (val == null || val.isEmpty)
                                return 'Please enter email';
                              if (!val.contains('@'))
                                return 'Enter valid email';
                              return null;
                            },
                            decoration: const InputDecoration(
                              hintText: 'Enter your email',
                              prefixIcon: Icon(Icons.email_rounded),
                            ),
                          ),

                          SizedBox(height: 16.h),

                          // Password
                          _buildLabel('Password'),
                          SizedBox(height: 8.h),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            validator: (val) {
                              if (val == null || val.isEmpty)
                                return 'Please enter password';
                              if (val.length < 6)
                                return 'Password must be 6+ characters';
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: 'Enter your password',
                              prefixIcon: const Icon(Icons.lock_rounded),
                              suffixIcon: GestureDetector(
                                onTap: () => setState(
                                        () => _obscurePassword = !_obscurePassword),
                                child: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ),
                          ),

                          // Forgot Password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _forgotPassword,
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 13.sp,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: 8.h),

                          // Login Button
                          ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                color: AppColors.white)
                                : const Text('Login'),
                          ),

                          SizedBox(height: 20.h),

                          // Divider
                          Row(
                            children: [
                              Expanded(
                                  child: Divider(color: AppColors.border)),
                              Padding(
                                padding:
                                EdgeInsets.symmetric(horizontal: 12.w),
                                child: Text(
                                  'OR',
                                  style: TextStyle(
                                    color: AppColors.textHint,
                                    fontSize: 13.sp,
                                  ),
                                ),
                              ),
                              Expanded(
                                  child: Divider(color: AppColors.border)),
                            ],
                          ),

                          SizedBox(height: 20.h),

                          // Sign Up Button
                          OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                    const SignupScreen()),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              minimumSize: Size(double.infinity, 52.h),
                              side: const BorderSide(
                                  color: AppColors.primary, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            child: Text(
                              'Create New Account',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          SizedBox(height: 20.h),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _forgotPassword() async {
    if (_emailController.text.isEmpty) {
      _showSnack('Enter your email first!', isError: true);
      return;
    }
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: _emailController.text.trim());
      _showSnack('Password reset email sent!');
    } catch (e) {
      _showSnack('Error sending reset email!', isError: true);
    }
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}