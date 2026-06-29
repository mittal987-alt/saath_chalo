import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/user_model.dart';
import '../../services/firebase_services.dart';
import '../home/home_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  final _formKey = GlobalKey<FormState>();

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Create user with email & password
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Update display name
      await credential.user!.updateDisplayName(_nameController.text.trim());

      // Save user to Firestore
      final user = UserModel(
        uid: credential.user!.uid,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        createdAt: DateTime.now(),
      );
      await FirebaseService().saveUser(user);

      // Go to Home
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      String msg = 'Signup failed!';
      if (e.code == 'weak-password') msg = 'Password is too weak!';
      if (e.code == 'email-already-in-use') msg = 'Email already registered!';
      if (e.code == 'invalid-email') msg = 'Invalid email address!';
      _showSnack(msg, isError: true);
    }
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
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
            stops: [0.0, 0.35],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: 8.w, vertical: 8.h),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_rounded,
                          color: AppColors.white),
                    ),
                    Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Logo small
              Icon(Icons.directions_car_rounded,
                  size: 40.sp, color: AppColors.white),
              SizedBox(height: 4.h),
              Text(
                AppStrings.appName,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),

              SizedBox(height: 16.h),

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
                            'Join SaathChalo! 🚗',
                            style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Create account & start saving money',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),

                          SizedBox(height: 24.h),

                          // Full Name
                          _buildLabel('Full Name'),
                          SizedBox(height: 8.h),
                          TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            validator: (val) {
                              if (val == null || val.isEmpty)
                                return 'Please enter your name';
                              if (val.length < 3)
                                return 'Name too short';
                              return null;
                            },
                            decoration: const InputDecoration(
                              hintText: 'Enter your full name',
                              prefixIcon: Icon(Icons.person_rounded),
                            ),
                          ),

                          SizedBox(height: 14.h),

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

                          SizedBox(height: 14.h),

                          // Phone
                          _buildLabel('Phone Number'),
                          SizedBox(height: 8.h),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            validator: (val) {
                              if (val == null || val.isEmpty)
                                return 'Please enter phone number';
                              if (val.length != 10)
                                return 'Enter valid 10 digit number';
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: 'Enter 10 digit number',
                              counterText: '',
                              prefixIcon: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12.w, vertical: 14.h),
                                child: Text(
                                  '+91',
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: 14.h),

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
                              hintText: 'Create password',
                              prefixIcon: const Icon(Icons.lock_rounded),
                              suffixIcon: GestureDetector(
                                onTap: () => setState(() =>
                                _obscurePassword = !_obscurePassword),
                                child: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: 14.h),

                          // Confirm Password
                          _buildLabel('Confirm Password'),
                          SizedBox(height: 8.h),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirm,
                            validator: (val) {
                              if (val == null || val.isEmpty)
                                return 'Please confirm password';
                              if (val != _passwordController.text)
                                return 'Passwords do not match!';
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: 'Re-enter password',
                              prefixIcon: const Icon(Icons.lock_outline_rounded),
                              suffixIcon: GestureDetector(
                                onTap: () => setState(
                                        () => _obscureConfirm = !_obscureConfirm),
                                child: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: 28.h),

                          // Signup Button
                          ElevatedButton(
                            onPressed: _isLoading ? null : _signup,
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                color: AppColors.white)
                                : const Text('Create Account'),
                          ),

                          SizedBox(height: 16.h),

                          // Already have account
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Already have an account? ',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Text(
                                    'Login',
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 24.h),
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