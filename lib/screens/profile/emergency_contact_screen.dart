import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState
    extends State<EmergencyContactsScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _relationController = TextEditingController();
  final uid = FirebaseAuth.instance.currentUser?.uid;

  void _addContact() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r)),
        title: Text('Add Emergency Contact',
            style: TextStyle(fontSize: 16.sp)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Contact Name',
                prefixIcon: Icon(Icons.person_rounded),
              ),
            ),
            SizedBox(height: 12.h),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: 'Phone Number',
                prefixIcon: Icon(Icons.phone_rounded),
              ),
            ),
            SizedBox(height: 12.h),
            TextFormField(
              controller: _relationController,
              decoration: const InputDecoration(
                hintText: 'Relation (e.g. Mother)',
                prefixIcon: Icon(Icons.people_rounded),
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
              if (_nameController.text.isNotEmpty &&
                  _phoneController.text.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('emergency_contacts')
                    .add({
                  'name': _nameController.text.trim(),
                  'phone': _phoneController.text.trim(),
                  'relation': _relationController.text.trim(),
                  'createdAt': FieldValue.serverTimestamp(),
                });
                _nameController.clear();
                _phoneController.clear();
                _relationController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        backgroundColor: AppColors.error,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addContact,
        backgroundColor: AppColors.error,
        icon: const Icon(Icons.add_rounded, color: AppColors.white),
        label: Text('Add Contact',
            style: TextStyle(color: AppColors.white, fontSize: 14.sp)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('emergency_contacts')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.error),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.contacts_rounded,
                      size: 64.sp, color: AppColors.border),
                  SizedBox(height: 16.h),
                  Text(
                    'No emergency contacts!\nAdd contacts for safety.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final data = snapshot.data!.docs[index].data()
              as Map<String, dynamic>;
              final docId = snapshot.data!.docs[index].id;
              return _buildContactCard(data, docId);
            },
          );
        },
      ),
    );
  }

  Widget _buildContactCard(Map<String, dynamic> data, String docId) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_rounded,
                color: AppColors.error, size: 26.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['name'] ?? '',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  data['phone'] ?? '',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (data['relation'] != null &&
                    data['relation'].isNotEmpty)
                  Text(
                    data['relation'],
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('emergency_contacts')
                  .doc(docId)
                  .delete();
            },
            icon: Icon(Icons.delete_rounded,
                color: AppColors.error, size: 22.sp),
          ),
        ],
      ),
    );
  }
}