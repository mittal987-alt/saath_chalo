import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/locale_provider.dart';
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
  bool _audioProtection = false;
  List<dynamic> _emergencyContacts = [];
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
          _emergencyContacts = settings['emergencyContacts'] ?? [];
          _isLoading = false;
        });
        // Sync global provider with Firestore setting
        if (settings['isHindi'] != null) {
          context.read<LocaleProvider>().toggleLanguage(settings['isHindi']);
        }
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    final isHindi = context.read<LocaleProvider>().isHindi;
    if (uid != null) {
      await FirebaseService().updateSafetySettings(uid!, {key: value});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isHindi ? 'प्राथमिकताएं सफलतापूर्वक अपडेट की गईं' : 'Preferences updated successfully',
            ),
            duration: const Duration(milliseconds: 800),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
          ),
        );
      }
    }
  }

  void _addEmergencyContact() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final isHindi = context.read<LocaleProvider>().isHindi;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isHindi ? 'संपर्क जोड़ें' : 'Add Contact'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: isHindi ? 'नाम' : 'Name'),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: isHindi ? 'फ़ोन नंबर' : 'Phone Number'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text(isHindi ? 'रद्द करें' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                final newContact = {
                  'name': nameController.text,
                  'phone': phoneController.text,
                };
                setState(() {
                  _emergencyContacts.add(newContact);
                });
                _updateSetting('emergencyContacts', _emergencyContacts);
                Navigator.pop(context);
              }
            },
            child: Text(isHindi ? 'जोड़ें' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _removeContact(int index) {
    setState(() {
      _emergencyContacts.removeAt(index);
    });
    _updateSetting('emergencyContacts', _emergencyContacts);
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = context.watch<LocaleProvider>().isHindi;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isHindi ? 'सुरक्षा टूलकिट' : 'Safety Toolkit',
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
          _buildSafetyCard(isHindi),
          SizedBox(height: 24.h),
          _buildSettingsSection(isHindi),
          SizedBox(height: 24.h),
          _buildEmergencyContactsSection(isHindi),
          SizedBox(height: 32.h),
          _buildSOSSection(isHindi),
          SizedBox(height: 88.h),
        ],
      ),
    );
  }

  Widget _buildSafetyCard(bool isHindi) {
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
                  isHindi ? 'आपकी सुरक्षा महत्वपूर्ण है' : 'Your Safety Matters',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  isHindi 
                      ? 'कॉन्फ़िगर करें कि हम आपकी साझा यात्राओं के दौरान आपको कैसे सुरक्षित रखते हैं।'
                      : 'Configure how we keep you safe during your shared journeys.',
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

  Widget _buildSettingsSection(bool isHindi) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 12.h),
          child: Text(
            isHindi ? 'सुरक्षा प्राथमिकताएं' : 'SECURITY PREFERENCES',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary.withValues(alpha: 0.8),
              letterSpacing: 0.5,
            ),
          ),
        ),
        _buildSwitchTile(
          icon: Icons.language_rounded,
          title: isHindi ? 'हिंदी भाषा' : 'Hindi Language',
          subtitle: isHindi ? 'ऐप को हिंदी में इस्तेमाल करें' : 'Use the app in Hindi',
          value: isHindi,
          onChanged: (val) {
            context.read<LocaleProvider>().toggleLanguage(val);
            _updateSetting('isHindi', val);
          },
        ),
        _buildSwitchTile(
          icon: Icons.location_on_rounded,
          title: isHindi ? 'लाइव लोकेशन साझा करें' : 'Share Live Location',
          subtitle: isHindi ? 'यात्रा के दौरान संपर्कों के साथ स्थान साझा करें' : 'Share location with emergency contacts during ride',
          value: _shareLocation,
          onChanged: (val) {
            setState(() => _shareLocation = val);
            _updateSetting('shareLocation', val);
          },
        ),
        _buildSwitchTile(
          icon: Icons.notifications_active_rounded,
          title: isHindi ? 'आपातकालीन अलर्ट' : 'Emergency Alerts',
          subtitle: isHindi ? 'SOS ट्रिगर होने पर संपर्कों को तुरंत सूचित करें' : 'Notify contacts immediately on SOS trigger',
          value: _emergencyAlerts,
          onChanged: (val) {
            setState(() => _emergencyAlerts = val);
            _updateSetting('emergencyAlerts', val);
          },
        ),
        _buildSwitchTile(
          icon: Icons.verified_user_rounded,
          title: isHindi ? 'यात्रा पुष्टि' : 'Ride Confirmation',
          subtitle: isHindi ? 'हर यात्रा शुरू करने के लिए OTP की आवश्यकता है' : 'Require OTP to start every ride',
          value: _rideConfirmation,
          onChanged: (val) {
            setState(() => _rideConfirmation = val);
            _updateSetting('rideConfirmation', val);
          },
        ),
        _buildSwitchTile(
          icon: Icons.mic_rounded,
          title: isHindi ? 'ऑडियो सुरक्षा' : 'Audio Protection',
          subtitle: isHindi ? 'यदि आवश्यक हो तो ऑडियो सुरक्षित रूप से रिकॉर्ड करें' : 'Securely record audio during trip if needed',
          value: _audioProtection,
          onChanged: (val) {
            setState(() => _audioProtection = val);
            _updateSetting('audioProtection', val);
          },
        ),
      ],
    );
  }

  Widget _buildEmergencyContactsSection(bool isHindi) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 12.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isHindi ? 'आपातकालीन संपर्क' : 'EMERGENCY CONTACTS',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                  letterSpacing: 0.5,
                ),
              ),
              GestureDetector(
                onTap: _addEmergencyContact,
                child: Text(
                  isHindi ? '+ नया जोड़ें' : '+ Add New',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_emergencyContacts.isEmpty)
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.people_outline_rounded, color: AppColors.textSecondary.withValues(alpha: 0.5), size: 40.sp),
                  SizedBox(height: 8.h),
                  Text(
                    isHindi ? 'अभी तक कोई आपातकालीन संपर्क नहीं जोड़ा गया है।' : 'No emergency contacts added yet.',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ..._emergencyContacts.asMap().entries.map((entry) {
            final index = entry.key;
            final contact = entry.value;
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
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                leading: Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person_rounded, color: AppColors.primary, size: 20.sp),
                ),
                title: Text(
                  contact['name'] ?? 'Unknown',
                  style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                subtitle: Text(
                  contact['phone'] ?? '',
                  style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete_outline_rounded, color: AppColors.error.withValues(alpha: 0.7), size: 20.sp),
                  onPressed: () => _removeContact(index),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildSOSSection(bool isHindi) {
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
                isHindi ? 'आपातकालीन SOS' : 'Emergency SOS',
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
            isHindi 
                ? 'अपने लाइव लोकेशन के साथ अधिकारियों और संपर्कों को तुरंत सचेत करें।'
                : 'Instantly alert authorities and emergency contacts with your live location.',
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
            child: Text(isHindi ? 'अभी SOS ट्रिगर करें' : 'TRIGGER SOS NOW',
              style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
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
        activeThumbColor: AppColors.primary,
        activeTrackColor: AppColors.primary.withValues(alpha: 0.2),
      ),
    );
  }
}