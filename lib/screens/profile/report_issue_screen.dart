import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../models/report_model.dart';
import '../../services/firebase_services.dart';

class ReportIssueScreen extends StatefulWidget {
  final String reportedId;
  final String type; // 'ride', 'user', 'safety', 'app'
  final Map<String, dynamic>? metadata;

  const ReportIssueScreen({
    super.key,
    required this.reportedId,
    required this.type,
    this.metadata,
  });

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'Other';
  bool _isSubmitting = false;

  final List<String> _rideCategories = [
    'Driver Behavior',
    'Vehicle Condition',
    'Route Deviation',
    'Payment Issue',
    'Late Arrival',
    'Other',
  ];

  final List<String> _userCategories = [
    'Inappropriate Behavior',
    'Fake Profile',
    'No Show',
    'Harassment',
    'Other',
  ];

  final List<String> _safetyCategories = [
    'Dangerous Driving',
    'Accident',
    'Medical Emergency',
    'Threatening Behavior',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.type == 'ride') _selectedCategory = _rideCategories[0];
    if (widget.type == 'user') _selectedCategory = _userCategories[0];
    if (widget.type == 'safety') _selectedCategory = _safetyCategories[0];
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final report = ReportModel(
        reportId: DateTime.now().millisecondsSinceEpoch.toString(),
        reporterId: user?.uid ?? 'anonymous',
        reporterName: user?.displayName ?? 'Anonymous User',
        reportedId: widget.reportedId,
        type: widget.type,
        category: _selectedCategory,
        description: _descriptionController.text.trim(),
        createdAt: DateTime.now(),
        metadata: widget.metadata,
      );

      await FirebaseService().submitReport(report);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report submitted successfully. We will investigate.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> categories = _rideCategories;
    if (widget.type == 'user') categories = _userCategories;
    if (widget.type == 'safety') categories = _safetyCategories;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Report Issue', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Help us understand what happened',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              SizedBox(height: 8.h),
              Text(
                'Your feedback is important for maintaining a safe community.',
                style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
              ),
              SizedBox(height: 24.h),
              Text(
                'Category',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              SizedBox(height: 10.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                'Description',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              SizedBox(height: 10.h),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Provide details about the issue...',
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Please enter description' : null,
              ),
              SizedBox(height: 40.h),
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('Submit Report', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
