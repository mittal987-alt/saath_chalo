import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../services/firebase_services.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _bioController = TextEditingController();
  bool _isLoading = false;
  final User? _user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    _nameController.text = _user?.displayName ?? '';
    _emailController.text = _user?.email ?? '';

    final userData = await FirebaseService().getUser(_user?.uid ?? '');
    if (userData != null) {
      _phoneController.text = userData.phone;
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnack('Please enter your name!', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _user?.updateDisplayName(_nameController.text.trim());
      await FirebaseService().updateUser(_user?.uid ?? '', {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
      });

      setState(() => _isLoading = false);
      _showSnack('Profile updated successfully!');
      Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack('Error updating profile!', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20.r),
          ),
        ),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _saveProfile,
              child: Text(
                'Save',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
        child: Column(
          children: [
            // Modern Profile Photo Frame
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.1), width: 4),
                    ),
                    child: CircleAvatar(
                      radius: 50.r,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.05),
                      child: Icon(Icons.person_rounded, size: 54.sp, color: AppColors.primary),
                    ),
                  ),
                  Positioned(
                    right: 2.w,
                    bottom: 2.h,
                    child: Container(
                      width: 32.w,
                      height: 32.w,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 2),
                      ),
                      child: Icon(Icons.camera_alt_rounded, size: 15.sp, color: AppColors.white),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              'Tap to change photo',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 28.h),

            // Form Input Stack
            _buildInputField(
              label: 'Full Name',
              controller: _nameController,
              icon: Icons.person_rounded,
              hint: 'Enter your full name',
            ),
            SizedBox(height: 16.h),
            _buildInputField(
              label: 'Phone Number',
              controller: _phoneController,
              icon: Icons.phone_rounded,
              hint: 'Enter phone number',
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 16.h),
            _buildInputField(
              label: 'Email Address',
              controller: _emailController,
              icon: Icons.email_rounded,
              hint: 'Enter email address',
              keyboardType: TextInputType.emailAddress,
              readOnly: true,
            ),
            SizedBox(height: 16.h),
            _buildInputField(
              label: 'Bio',
              controller: _bioController,
              icon: Icons.info_rounded,
              hint: 'Tell others about yourself...',
              maxLines: 3,
            ),
            SizedBox(height: 32.h),

            // Primary Form Save Button
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                  height: 20.w,
                  width: 20.w,
                  child: const CircularProgressIndicator(color: AppColors.white, strokeWidth: 2.5),
                )
                    : Text(
                  'Save Changes',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: 80.h), // Safe spacing padding from UI overlaps
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 6.h),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary.withValues(alpha: 0.8),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: readOnly ? AppColors.border.withValues(alpha: 0.25) : AppColors.white,
            borderRadius: BorderRadius.circular(14.r),
            boxShadow: readOnly
                ? null
                : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            maxLines: maxLines,
            style: TextStyle(
              fontSize: 14.sp,
              color: readOnly ? AppColors.textSecondary : AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: AppColors.textHint.withValues(alpha: 0.6),
                fontSize: 14.sp,
              ),
              prefixIcon: Icon(icon, color: readOnly ? AppColors.textHint : AppColors.primary, size: 18.sp),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.5), width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.4), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: maxLines > 1 ? 12.h : 0),
            ),
          ),
        ),
      ],
    );
  }
}