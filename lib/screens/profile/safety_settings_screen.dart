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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Safety Settings'),
        backgroundColor: AppColors.info,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(16.w),
              children: [
                _buildSafetyCard(),
                SizedBox(height: 24.h),
                _buildSettingsSection(),
              ],
            ),
    );
  }

  Widget _buildSafetyCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.info, AppColors.info.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_rounded, color: AppColors.white, size: 50.sp),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Safety Matters',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Configure how we keep you safe during your rides.',
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.9),
                    fontSize: 12.sp,
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
        Text(
          'Security Preferences',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 12.h),
        _buildSwitchTile(
          Icons.location_on_rounded,
          'Share Live Location',
          'Share location with emergency contacts during ride',
          _shareLocation,
          (val) {
            setState(() => _shareLocation = val);
            _updateSetting('shareLocation', val);
          },
        ),
        _buildSwitchTile(
          Icons.notifications_active_rounded,
          'Emergency Alerts',
          'Notify contacts immediately on SOS trigger',
          _emergencyAlerts,
          (val) {
            setState(() => _emergencyAlerts = val);
            _updateSetting('emergencyAlerts', val);
          },
        ),
        _buildSwitchTile(
          Icons.verified_user_rounded,
          'Ride Confirmation',
          'Require OTP to start every ride',
          _rideConfirmation,
          (val) {
            setState(() => _rideConfirmation = val);
            _updateSetting('rideConfirmation', val);
          },
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
      IconData icon, String title, String subtitle, bool value, Function(bool) onChanged) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
          ),
        ],
      ),
      child: SwitchListTile(
        secondary: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: AppColors.info, size: 20.sp),
        ),
        title: Text(
          title,
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 11.sp, color: AppColors.textSecondary),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.info,
      ),
    );
  }
}
