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
import '../ride/active_ride_screen.dart';
import '../ride/driver_requests_screen.dart';
import '../profile/profile_screen.dart';
import '../ride/offer_ride_screen.dart';
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
        return const EarningsDashboardScreen();
      case 3:
        return const ProfileScreen();
      default:
        return const SizedBox();
    }
  }

  Widget _buildBottomNav() {
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
                _buildNavItem(0, Icons.inbox_rounded, Icons.inbox_outlined, 'Requests'),
                _buildNavItem(1, Icons.directions_car_rounded, Icons.directions_car_outlined, 'Active'),
                _buildNavItem(2, Icons.account_balance_wallet_rounded, Icons.account_balance_wallet_outlined, 'Earnings'),
                _buildNavItem(3, Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
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
              child: Icon(
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Driver Dashboard',
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
            label: Text('Passenger', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
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
          label: const Text('Offer Ride', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Active Rides'),
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
            return const Center(child: Text('No active rides currently.'));
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
                  subtitle: Text('Rider: ${booking.riderName}\nStatus: ${booking.status.toUpperCase()}'),
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
