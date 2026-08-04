import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../services/firebase_services.dart';
import 'driver_dashboard_screen.dart';

class DriverVerificationScreen extends StatefulWidget {
  const DriverVerificationScreen({super.key});

  @override
  State<DriverVerificationScreen> createState() => _DriverVerificationScreenState();
}

class _DriverVerificationScreenState extends State<DriverVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _licenseController = TextEditingController();
  final _rcController = TextEditingController();
  final _insuranceController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _licenseController.dispose();
    _rcController.dispose();
    _insuranceController.dispose();
    super.dispose();
  }

  Future<void> _submitVerification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Update user profile in Firestore
        await FirebaseService().updateUser(user.uid, {
          'isDriverVerified': true,
          'drivingLicenseNumber': _licenseController.text.trim(),
          'rcNumber': _rcController.text.trim(),
          'insuranceDetails': _insuranceController.text.trim(),
        });
        
        if (mounted) {
          // Navigate to Driver Dashboard and replace the current screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const DriverDashboardScreen(),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, String hint) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: TextFormField(
        controller: controller,
        textCapitalization: TextCapitalization.characters,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.primary),
          filled: true,
          fillColor: AppColors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter your $label';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Driver Verification',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20.sp),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  children: [
                    Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 40.sp),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Text(
                        'To keep our community safe, please provide your driving credentials before offering rides.',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13.sp,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32.h),
              Text(
                'Personal Documents',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 16.h),
              _buildTextField(
                _licenseController,
                'Driving License Number',
                Icons.badge_rounded,
                'e.g. DL-1420110012345',
              ),
              _buildTextField(
                _rcController,
                'Vehicle RC Number',
                Icons.directions_car_rounded,
                'e.g. DL-8C-AA-1111',
              ),
              _buildTextField(
                _insuranceController,
                'Insurance Policy Number',
                Icons.security_rounded,
                'Enter policy number',
              ),
              SizedBox(height: 30.h),
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitVerification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    elevation: 4,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 24.w,
                          width: 24.w,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'Submit & Verify',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
}
