import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui';
import '../../core/constants/app_colors.dart';
import 'earnings_dashboard_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firebase_services.dart';
import '../../models/booking_model.dart';
import '../../l10n/app_localizations.dart';
import '../ride/active_ride_screen.dart';
import '../ride/driver_requests_screen.dart';
import '../profile/profile_screen.dart';
import '../ride/offer_ride_screen.dart';
import '../chat/chat_list_screen.dart';
import '../home/home_screen.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  int _selectedIndex = 0;

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const DriverRequestsScreen();
      case 1:
        return const DriverActiveRidesScreen();
      case 2:
        return const ChatListScreen();
      case 3:
        return const EarningsDashboardScreen();
      case 4:
        return const ProfileScreen();
      default:
        return const SizedBox();
    }
  }

  Widget _buildChatNavIcon(bool isSelected) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final color = isSelected ? AppColors.secondary : AppColors.textHint.withValues(alpha: 0.6);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ride_chats')
          .where(Filter.or(
            Filter('riderUid', isEqualTo: uid),
            Filter('driverUid', isEqualTo: uid),
          ))
          .snapshots(),
      builder: (context, snapshot) {
        int unread = 0;
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            if (data['lastSenderId'] != uid) {
              // In a real app, you'd check a per-user read status
              // For now, if I'm not the last sender, it's "new" to me
              unread++;
            }
          }
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              isSelected ? Icons.chat_bubble_rounded : Icons.chat_bubble_outline_rounded,
              color: color,
              size: 22.sp,
            ),
            if (unread > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  constraints: BoxConstraints(
                    minWidth: 14.w,
                    minHeight: 14.w,
                  ),
                  child: Center(
                    child: Text(
                      unread > 9 ? '9+' : '$unread',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildBottomNav() {
    final l10n = AppLocalizations.of(context);
    return Align(
      alignment: const Alignment(0, 0.95),
      child: Container(
        margin: EdgeInsets.fromLTRB(24.w, 0, 24.w, 16.h),
        height: 68.h,
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(color: AppColors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: 0.15),
              blurRadius: 30,
              spreadRadius: 5,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.inbox_rounded, Icons.inbox_outlined, l10n?.requestsTab ?? 'Requests'),
                _buildNavItem(1, Icons.directions_car_rounded, Icons.directions_car_outlined, l10n?.activeTab ?? 'Active'),
                _buildNavItem(2, Icons.chat_bubble_rounded, Icons.chat_bubble_outline_rounded, l10n?.chatsTab ?? 'Chats', customIcon: _buildChatNavIcon),
                _buildNavItem(3, Icons.account_balance_wallet_rounded, Icons.account_balance_wallet_outlined, l10n?.earningsTab ?? 'Earnings'),
                _buildNavItem(4, Icons.person_rounded, Icons.person_outline_rounded, l10n?.profileTab ?? 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label, {Widget Function(bool)? customIcon}) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? AppColors.secondary : AppColors.textHint.withValues(alpha: 0.6);

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedIndex = index);
      },
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: isSelected ? EdgeInsets.all(6.w) : EdgeInsets.zero,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.secondary.withValues(alpha: 0.1) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: customIcon != null 
                ? customIcon(isSelected)
                : Icon(
                    isSelected ? activeIcon : inactiveIcon,
                    color: color,
                    size: 22.sp,
                  ),
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 9.sp,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n?.driverDashboard ?? 'Driver Dashboard',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              // Switch back to passenger mode
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            },
            icon: Icon(Icons.swap_horiz_rounded, color: AppColors.primary, size: 18.sp),
            label: Text(l10n?.passengerButton ?? 'Passenger', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: Stack(
        children: [
          _buildBody(),
          _buildBottomNav(),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 80.h), // Push above bottom nav
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const OfferRideScreen()),
            );
          },
          backgroundColor: AppColors.secondary,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: Text(l10n?.offerRideButton ?? 'Offer Ride', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

class DriverActiveRidesScreen extends StatelessWidget {
  const DriverActiveRidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n?.activeTab ?? 'Active Rides'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<List<BookingModel>>(
        stream: FirebaseService().getDriverActiveBookingsList(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text(l10n?.noActiveRides ?? 'No active rides currently.'));
          }

          final rides = snapshot.data!;
          return ListView.builder(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
            itemCount: rides.length,
            itemBuilder: (context, index) {
              final booking = rides[index];
              return Card(
                margin: EdgeInsets.only(bottom: 12.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                child: ListTile(
                  contentPadding: EdgeInsets.all(16.w),
                  title: Text('${booking.from} to ${booking.to}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
                  subtitle: Text('${l10n?.riderLabel(booking.riderName) ?? "Rider: ${booking.riderName}"}\nStatus: ${booking.status.toUpperCase()}'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primary),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ActiveRideScreen(booking: booking, isDriver: true),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
