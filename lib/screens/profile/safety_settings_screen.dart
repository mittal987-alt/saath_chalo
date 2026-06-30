import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../services/firebase_services.dart';

class SafetySettingsScreen extends StatefulWidget {
  const SafetySettingsScreen({super.key});

  @override
  State<SafetySettingsScreen> createState() => _SafetySettingsScreenState();
}

class _SafetySettingsScreenState extends State<SafetySettingsScreen> {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  bool _shareLocation = true;
  bool _emergencyAlerts = true;
  bool _rideConfirmation = false;
  bool _audioProtection = false; // New advanced safety feature toggle
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (uid != null) {
      final settings = await FirebaseService().getSafetySettings(uid!);
      if (settings != null && mounted) {
        setState(() {
          _shareLocation = settings['shareLocation'] ?? true;
          _emergencyAlerts = settings['emergencyAlerts'] ?? true;
          _rideConfirmation = settings['rideConfirmation'] ?? false;
          _audioProtection = settings['audioProtection'] ?? false;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateSetting(String key, bool value) async {
    if (uid != null) {
      await FirebaseService().updateSafetySettings(uid!, {key: value});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Preferences saved updated successfully'),
            duration: const Duration(milliseconds: 800),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Safety Toolkit',
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
            bottom: Radius.circular(24.r),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        children: [
          _buildSafetyCard(),
          SizedBox(height: 24.h),
          _buildSettingsSection(),
          SizedBox(height: 32.h),
          _buildSOSSection(),
          SizedBox(height: 88.h),
        ],
      ),
    );
  }

  Widget _buildSafetyCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF00B09B),
            Color(0xFF00A86B),
          ],
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.shield_rounded, color: AppColors.white, size: 40.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Safety Matters',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Configure how we keep you safe during your shared journeys.',
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.9),
                    fontSize: 12.sp,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 12.h),
          child: Text(
            'SECURITY PREFERENCES',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary.withValues(alpha: 0.8),
              letterSpacing: 0.5,
            ),
          ),
        ),
        _buildSwitchTile(
          icon: Icons.location_on_rounded,
          title: 'Share Live Location',
          subtitle: 'Share location with emergency contacts during ride',
          value: _shareLocation,
          onChanged: (val) {
            setState(() => _shareLocation = val);
            _updateSetting('shareLocation', val);
          },
        ),
        _buildSwitchTile(
          icon: Icons.notifications_active_rounded,
          title: 'Emergency Alerts',
          subtitle: 'Notify contacts immediately on SOS trigger',
          value: _emergencyAlerts,
          onChanged: (val) {
            setState(() => _emergencyAlerts = val);
            _updateSetting('emergencyAlerts', val);
          },
        ),
        _buildSwitchTile(
          icon: Icons.verified_user_rounded,
          title: 'Ride Confirmation',
          subtitle: 'Require OTP to start every ride',
          value: _rideConfirmation,
          onChanged: (val) {
            setState(() => _rideConfirmation = val);
            _updateSetting('rideConfirmation', val);
          },
        ),
      ],
    );
  }

  Widget _buildSOSSection() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24.sp),
              SizedBox(width: 12.w),
              Text(
                'Emergency SOS',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'Instantly alert authorities and emergency contacts with your live location.',
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
              minimumSize: Size(double.infinity, 50.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              elevation: 0,
            ),
            child: const Text('TRIGGER SOS NOW', 
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        secondary: Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22.sp),
        ),
        title: Text(
          title,
          style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 11.sp, color: AppColors.textSecondary, height: 1.3),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
        activeTrackColor: AppColors.primary.withValues(alpha: 0.2),
      ),
    );
  }
}