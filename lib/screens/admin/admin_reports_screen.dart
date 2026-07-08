import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/report_model.dart';
import '../../services/firebase_services.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('User Reports'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('reports').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.report_off_rounded, size: 64.sp, color: AppColors.textHint),
                  SizedBox(height: 16.h),
                  const Text('No reports filed yet'),
                ],
              ),
            );
          }

          final reports = snapshot.data!.docs
              .map((doc) => ReportModel.fromMap(doc.data() as Map<String, dynamic>))
              .toList();

          return ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              return _buildReportCard(reports[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildReportCard(ReportModel report) {
    Color statusColor = Colors.orange;
    if (report.status == 'resolved') statusColor = AppColors.success;
    if (report.status == 'investigating') statusColor = Colors.blue;
    if (report.status == 'dismissed') statusColor = AppColors.textHint;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: _getTypeColor(report.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  report.type.toUpperCase(),
                  style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold, color: _getTypeColor(report.type)),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  report.status.toUpperCase(),
                  style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            report.category,
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          SizedBox(height: 4.h),
          Text(
            report.description,
            style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
          ),
          SizedBox(height: 16.h),
          const Divider(),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('From: ${report.reporterName}', style: TextStyle(fontSize: 11.sp, color: AppColors.textHint)),
                  Text(DateFormat('MMM d, yyyy • HH:mm').format(report.createdAt), style: TextStyle(fontSize: 11.sp, color: AppColors.textHint)),
                ],
              ),
              PopupMenuButton<String>(
                onSelected: (val) => _updateReportStatus(report, val),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'pending', child: Text('Set Pending')),
                  const PopupMenuItem(value: 'investigating', child: Text('Set Investigating')),
                  const PopupMenuItem(value: 'resolved', child: Text('Mark Resolved')),
                  const PopupMenuItem(value: 'dismissed', child: Text('Dismiss')),
                ],
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      Text('Action', style: TextStyle(fontSize: 12.sp)),
                      Icon(Icons.arrow_drop_down, size: 18.sp),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'ride': return Colors.blue;
      case 'user': return Colors.purple;
      case 'safety': return Colors.red;
      default: return Colors.grey;
    }
  }

  Future<void> _updateReportStatus(ReportModel report, String status) async {
    try {
      await _firebaseService.updateReportStatus(
        reportId: report.reportId,
        status: status,
        reporterId: report.reporterId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report status updated to $status'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating report: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
