import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../services/firebase_services.dart';
import 'package:intl/intl.dart';

class PaymentHistoryScreen extends StatelessWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Payment History'),
        backgroundColor: AppColors.primary,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F9D58),
                Color(0xFF0B8043),
              ],
            ),
          ),
        ),
        foregroundColor: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30.r),
          ),
        ),
      ),
      body: user == null
          ? const Center(child: Text('Please login to view payment history'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseService().getPaymentHistory(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error loading history: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                final docs = snapshot.data!.docs;
                double totalSpent = 0;
                double totalAdded = 0;
                
                // Grouping transactions by Month
                Map<String, List<Map<String, dynamic>>> groupedPayments = {};

                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final double amount = (data['amount'] ?? 0).toDouble();
                  final String type = (data['type'] ?? 'PAYMENT').toString().toUpperCase();
                  final Timestamp? timestamp = data['timestamp'] as Timestamp?;
                  
                  if (type == 'TOPUP') {
                    totalAdded += amount;
                  } else {
                    totalSpent += amount;
                  }

                  if (timestamp != null) {
                    String monthYear = DateFormat('MMMM yyyy').format(timestamp.toDate());
                    if (!groupedPayments.containsKey(monthYear)) {
                      groupedPayments[monthYear] = [];
                    }
                    groupedPayments[monthYear]!.add(data);
                  }
                }

                return Column(
                  children: [
                    _buildSummaryRow(totalSpent, totalAdded),
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        physics: const BouncingScrollPhysics(),
                        itemCount: groupedPayments.length,
                        itemBuilder: (context, index) {
                          String month = groupedPayments.keys.elementAt(index);
                          List<Map<String, dynamic>> items = groupedPayments[month]!;
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 4.w),
                                child: Text(
                                  month.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              ...items.map((item) => _buildTransactionCard(item)).toList(),
                              SizedBox(height: 8.h),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildSummaryRow(double spent, double added) {
    return Container(
      margin: EdgeInsets.all(20.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem('Funds Added', added, AppColors.primaryLight),
          ),
          Container(width: 1, height: 40.h, color: Colors.white12),
          Expanded(
            child: _buildSummaryItem('Ride Expenses', spent, AppColors.error),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: Colors.white54, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 4.h),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 20.sp,
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> data) {
    final timestamp = data['timestamp'] as Timestamp?;
    final date = timestamp != null
        ? DateFormat('dd MMM, hh:mm a').format(timestamp.toDate())
        : 'N/A';
    
    final status = (data['status'] ?? 'SUCCESS').toString().toUpperCase();
    final type = (data['type'] ?? 'PAYMENT').toString().toUpperCase();
    final route = data['route'] as String?;
    
    final bool isSuccess = status == 'SUCCESS' || status == 'PAID' || status == 'COMPLETED';
    final Color statusColor = isSuccess ? AppColors.success : AppColors.error;
    final bool isTopup = type == 'TOPUP';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: (isTopup ? AppColors.primary : statusColor).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isTopup ? Icons.add_rounded : Icons.remove_rounded,
              color: isTopup ? AppColors.primary : statusColor,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['description'] ?? (isTopup ? 'Wallet Top-up' : 'Ride Payment'),
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  date,
                  style: TextStyle(fontSize: 10.sp, color: AppColors.textHint, fontWeight: FontWeight.w500),
                ),
                if (route != null) ...[
                  SizedBox(height: 4.h),
                  Text(
                    route,
                    style: TextStyle(fontSize: 10.sp, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isTopup ? "+" : "-"} ₹${(data['amount'] ?? 0).toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                  color: isTopup ? AppColors.success : AppColors.textPrimary,
                ),
              ),
              if (!isSuccess)
                Text(
                  status,
                  style: TextStyle(fontSize: 8.sp, fontWeight: FontWeight.bold, color: AppColors.error),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 64.sp, color: AppColors.textHint.withValues(alpha: 0.3)),
          SizedBox(height: 16.h),
          Text(
            'No transactions yet',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          SizedBox(height: 4.h),
          Text(
            'Your payment history will appear here',
            style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
