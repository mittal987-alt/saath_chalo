import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manage Users'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: EdgeInsets.all(16.w),
            color: const Color(0xFF1A237E),
            child: TextField(
              controller: _searchController,
              onChanged: (val) =>
                  setState(() => _searchQuery = val.toLowerCase()),
              style: TextStyle(color: AppColors.white, fontSize: 14.sp),
              decoration: InputDecoration(
                hintText: 'Search users...',
                hintStyle: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.6),
                    fontSize: 14.sp),
                prefixIcon: Icon(Icons.search_rounded,
                    color: AppColors.white.withValues(alpha: 0.8)),
                filled: true,
                fillColor: AppColors.white.withValues(alpha: 0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 12.h),
              ),
            ),
          ),

          // Users List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF1A237E)),
                  );
                }

                if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline_rounded,
                            size: 64.sp, color: AppColors.border),
                        SizedBox(height: 16.h),
                        Text('No users yet!',
                            style: TextStyle(
                                fontSize: 16.sp,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }

                var docs = snapshot.data!.docs;
                if (_searchQuery.isNotEmpty) {
                  docs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name =
                    (data['name'] ?? '').toString().toLowerCase();
                    final email =
                    (data['email'] ?? '').toString().toLowerCase();
                    return name.contains(_searchQuery) ||
                        email.contains(_searchQuery);
                  }).toList();
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data =
                    docs[index].data() as Map<String, dynamic>;
                    final docId = docs[index].id;
                    return _buildUserCard(data, docId);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> data, String uid) {
    final bool isBlocked = data['isBlocked'] ?? false;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: isBlocked
            ? Border.all(color: AppColors.error, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22.r,
            backgroundColor: const Color(0xFF1565C0).withValues(alpha: 0.1),
            child: Icon(Icons.person_rounded,
                color: const Color(0xFF1565C0), size: 26.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      data['name'] ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (isBlocked) ...[
                      SizedBox(width: 6.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          'BLOCKED',
                          style: TextStyle(
                            fontSize: 9.sp,
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  data['email'] ?? '',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  data['phone'] ?? '',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton(
            icon: Icon(Icons.more_vert_rounded,
                color: AppColors.textHint),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(
                      isBlocked
                          ? Icons.check_circle_rounded
                          : Icons.block_rounded,
                      color: isBlocked
                          ? AppColors.success
                          : AppColors.error,
                      size: 18.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(isBlocked ? 'Unblock User' : 'Block User'),
                  ],
                ),
                onTap: () async {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .update({'isBlocked': !isBlocked});
                },
              ),
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(Icons.verified_rounded,
                        color: AppColors.primary, size: 18.sp),
                    SizedBox(width: 8.w),
                    const Text('Verify User'),
                  ],
                ),
                onTap: () async {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .update({'isVerified': true});
                },
              ),
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(Icons.delete_rounded,
                        color: AppColors.error, size: 18.sp),
                    SizedBox(width: 8.w),
                    const Text('Delete User'),
                  ],
                ),
                onTap: () async {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .delete();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}