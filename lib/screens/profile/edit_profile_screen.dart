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

    final userData =
    await FirebaseService().getUser(_user?.uid ?? '');
    if (userData != null) {
      _phoneController.text = userData.phone;
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty) {
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
        title: const Text('Edit Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: Text(
              'Save',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            // Profile Picture
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 56.r,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Icon(Icons.person_rounded,
                        size: 64.sp, color: AppColors.primary),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 36.w,
                      height: 36.w,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.white, width: 2),
                      ),
                      child: Icon(Icons.camera_alt_rounded,
                          size: 18.sp, color: AppColors.white),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 8.h),
            Text(
              'Tap to change photo',
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.textSecondary,
              ),
            ),

            SizedBox(height: 24.h),

            // Form Fields
            _buildCard(
              children: [
                _buildField(
                  'Full Name',
                  _nameController,
                  Icons.person_rounded,
                  'Enter your full name',
                ),
                Divider(color: AppColors.divider),
                _buildField(
                  'Phone Number',
                  _phoneController,
                  Icons.phone_rounded,
                  'Enter phone number',
                  keyboardType: TextInputType.phone,
                ),
                Divider(color: AppColors.divider),
                _buildField(
                  'Email',
                  _emailController,
                  Icons.email_rounded,
                  'Enter email address',
                  keyboardType: TextInputType.emailAddress,
                  readOnly: true,
                ),
              ],
            ),

            SizedBox(height: 16.h),

            _buildCard(
              children: [
                _buildField(
                  'Bio',
                  _bioController,
                  Icons.info_rounded,
                  'Tell others about yourself...',
                  maxLines: 3,
                ),
              ],
            ),

            SizedBox(height: 24.h),

            ElevatedButton(
              onPressed: _isLoading ? null : _saveProfile,
              child: _isLoading
                  ? const CircularProgressIndicator(
                  color: AppColors.white)
                  : const Text('Save Changes'),
            ),

            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildField(
      String label,
      TextEditingController controller,
      IconData icon,
      String hint, {
        TextInputType keyboardType = TextInputType.text,
        bool readOnly = false,
        int maxLines = 1,
      }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 22.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 4.h),
                TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  readOnly: readOnly,
                  maxLines: maxLines,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: AppColors.textHint,
                      fontSize: 14.sp,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    filled: readOnly,
                    fillColor: readOnly
                        ? AppColors.background
                        : Colors.transparent,
                  ),
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: readOnly
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}