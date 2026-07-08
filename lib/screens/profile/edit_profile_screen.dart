import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
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

  File? _imageFile;
  String? _profilePicUrl;
  final ImagePicker _picker = ImagePicker();

  String _initialPhone = '';
  String _initialEmail = '';
  String _verificationId = '';

  // Preferences state
  bool _musicAllowed = true;
  bool _petsAllowed = false;
  bool _smokingAllowed = false;
  bool _acPreferred = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    _nameController.text = _user?.displayName ?? '';
    _emailController.text = _user?.email ?? '';
    _initialEmail = _user?.email ?? '';

    final userData = await FirebaseService().getUser(_user?.uid ?? '');
    if (userData != null) {
      _phoneController.text = userData.phone;
      _initialPhone = userData.phone;
      _bioController.text = userData.bio;
      _profilePicUrl = userData.profilePic;

      // Load preferences if saved
      // (Add more fields to UserModel if needed)
      setState(() {
        _musicAllowed = userData.musicAllowed;
        _petsAllowed = userData.petsAllowed;
        _smokingAllowed = userData.smokingAllowed;
        _acPreferred = userData.acPreferred;
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final bio = _bioController.text.trim();

    if (name.isEmpty) {
      _showSnack('Please enter your name!', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? updatedProfilePicUrl = _profilePicUrl;

      // 0. Upload Image if changed
      if (_imageFile != null) {
        final uploadedUrl = await FirebaseService().uploadProfilePic(_user?.uid ?? '', _imageFile!);
        if (uploadedUrl != null) {
          updatedProfilePicUrl = uploadedUrl;
        } else {
          _showSnack('Failed to upload profile picture', isError: true);
          setState(() => _isLoading = false);
          return;
        }
      }

      // 1. Update profile info in Firestore (with nested preferences)
      await FirebaseService().updateUser(_user?.uid ?? '', {
        'name': name,
        'bio': bio,
        'profilePic': updatedProfilePicUrl ?? '',
        'preferences': {
          'musicAllowed': _musicAllowed,
          'petsAllowed': _petsAllowed,
          'smokingAllowed': _smokingAllowed,
          'acPreferred': _acPreferred,
        },
      });
      await _user?.updateDisplayName(name);
      if (updatedProfilePicUrl != null) {
        await _user?.updatePhotoURL(updatedProfilePicUrl);
      }
      await _user?.reload();

      // 2. Check if Email changed
      if (email != _initialEmail && email.isNotEmpty) {
        await _user?.verifyBeforeUpdateEmail(email);
        _showSnack('Verification link sent to $email. Please verify to update.');
      }

      // 3. Check if Phone changed (Triggers OTP)
      if (phone != _initialPhone && phone.isNotEmpty) {
        await _sendOTP(phone);
        // We don't stop loading yet, the OTP dialog will handle the rest
      } else {
        setState(() => _isLoading = false);
        _showSnack('Profile updated successfully!');
        if (email == _initialEmail) Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack('Error updating profile: $e', isError: true);
    }
  }

  Future<void> _sendOTP(String phoneNumber) async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _user?.updatePhoneNumber(credential);
        await FirebaseService().updateUser(_user?.uid ?? '', {'phone': phoneNumber});
        if (mounted) {
          setState(() => _isLoading = false);
          _showSnack('Phone number verified and updated!');
          Navigator.pop(context);
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() => _isLoading = false);
        _showSnack('Verification failed: ${e.message}', isError: true);
      },
      codeSent: (String verId, int? resendToken) {
        _verificationId = verId;
        setState(() => _isLoading = false);
        _showOTPDialog(phoneNumber);
      },
      codeAutoRetrievalTimeout: (String verId) {
        _verificationId = verId;
      },
    );
  }

  void _showOTPDialog(String newPhone) {
    final otpController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text('Verify Phone Number', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter the 6-digit OTP sent to $newPhone', style: TextStyle(fontSize: 13.sp)),
            SizedBox(height: 20.h),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20.sp, letterSpacing: 8, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                counterText: '',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final otp = otpController.text.trim();
              if (otp.length == 6) {
                try {
                  PhoneAuthCredential credential = PhoneAuthProvider.credential(
                    verificationId: _verificationId,
                    smsCode: otp,
                  );
                  await _user?.updatePhoneNumber(credential);
                  await FirebaseService().updateUser(_user?.uid ?? '', {'phone': newPhone});
                  Navigator.pop(context); // Close dialog
                  _showSnack('Phone number updated successfully!');
                  Navigator.pop(this.context); // Close profile screen
                } catch (e) {
                  _showSnack('Invalid OTP!', isError: true);
                }
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
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
            GestureDetector(
              onTap: _pickImage,
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary.withOpacity(0.1), width: 4),
                      ),
                      child: CircleAvatar(
                        radius: 50.r,
                        backgroundColor: AppColors.primary.withOpacity(0.05),
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : (_profilePicUrl != null && _profilePicUrl!.isNotEmpty
                            ? NetworkImage(_profilePicUrl!)
                            : null) as ImageProvider?,
                        child: (_imageFile == null && (_profilePicUrl == null || _profilePicUrl!.isEmpty))
                            ? Icon(Icons.person_rounded, size: 54.sp, color: AppColors.primary)
                            : null,
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
            SizedBox(height: 24.h),

            // Ride Preferences Card
            _buildPreferencesCard(),

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

  Widget _buildPreferencesCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, color: AppColors.primary, size: 18.sp),
              SizedBox(width: 8.w),
              Text(
                'Ride Preferences',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _prefToggle('🎵 Music Allowed', _musicAllowed, (v) => setState(() => _musicAllowed = v)),
          _prefToggle('🐾 Pets Allowed', _petsAllowed, (v) => setState(() => _petsAllowed = v)),
          _prefToggle('🚬 Smoking Allowed', _smokingAllowed, (v) => setState(() => _smokingAllowed = v)),
          _prefToggle('❄️ AC Preferred', _acPreferred, (v) => setState(() => _acPreferred = v)),
        ],
      ),
    );
  }

  Widget _prefToggle(String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
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