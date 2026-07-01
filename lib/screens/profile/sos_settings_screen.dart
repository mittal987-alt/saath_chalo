import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../services/firebase_services.dart';

class SosSettingsScreen extends StatefulWidget {
  const SosSettingsScreen({super.key});

  @override
  State<SosSettingsScreen> createState() => _SosSettingsScreenState();
}

class _SosSettingsScreenState extends State<SosSettingsScreen> {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  bool _autoCall = false;
  bool _autoMessage = true;
  bool _detectAccident = false;
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
          _autoCall = settings['sosAutoCall'] ?? false;
          _autoMessage = settings['sosAutoMessage'] ?? true;
          _detectAccident = settings['detectAccident'] ?? false;
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
        title: const Text('SOS Settings'),
        backgroundColor: AppColors.error,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(16.w),
              children: [
                _buildSOSWarning(),
                SizedBox(height: 24.h),
                _buildSOSOptions(),
              ],
            ),
    );
  }

  Widget _buildSOSWarning() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 40.sp),
          SizedBox(height: 12.h),
          Text(
            'Emergency SOS',
            style: TextStyle(
              color: AppColors.error,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'When SOS is triggered, we will notify your emergency contacts and local authorities with your live location.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSOSOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Automated Actions',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 12.h),
        _buildSwitchTile(
          Icons.phone_in_talk_rounded,
          'Auto-call Emergency Services',
          'Automatically dial 112 when SOS is active',
          _autoCall,
          (val) {
            setState(() => _autoCall = val);
            _updateSetting('sosAutoCall', val);
          },
        ),
        _buildSwitchTile(
          Icons.message_rounded,
          'Auto-send SMS',
          'Send SMS to all emergency contacts',
          _autoMessage,
          (val) {
            setState(() => _autoMessage = val);
            _updateSetting('sosAutoMessage', val);
          },
        ),
        _buildSwitchTile(
          Icons.sensors_rounded,
          'Crash Detection',
          'Automatically trigger SOS on accident detection',
          _detectAccident,
          (val) {
            setState(() => _detectAccident = val);
            _updateSetting('detectAccident', val);
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
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: AppColors.error, size: 20.sp),
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
        activeThumbColor: AppColors.error,
      ),
    );
  }
}
