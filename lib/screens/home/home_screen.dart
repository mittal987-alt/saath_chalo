import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firebase_services.dart';
import '../../models/user_model.dart';
import '../../models/ride_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../ride/find_ride_screen.dart';
import '../ride/offer_ride_screen.dart';
import 'map_screen.dart';
import '../chat/chat_list_screen.dart';
import '../profile/profile_screen.dart';
import '../profile/ride_history_screen.dart';
import '../ai/ai_assistant_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final User? _user = FirebaseAuth.instance.currentUser;
  UserModel? _userModel;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (_user != null) {
      final user = await FirebaseService().getUser(_user!.uid);
      if (mounted) {
        setState(() => _userModel = user);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        // ✅ Now uses _buildBody()
        child: _buildBody(),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ✅ Body switcher
  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildQuickActions(),
              _buildRecentRides(),
              _buildStats(),
            ],
          ),
        );
      case 1:
        return const FindRideScreen();
      case 2:
        return const OfferRideScreen();
      case 3:
        return const ChatListScreen();
      case 4:
       return const ProfileScreen();
      case 5:
        return const AIAssistantScreen();
      default:
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildQuickActions(),
              _buildRecentRides(),
              _buildStats(),
            ],
          ),
        );
    }
  }

  // Header
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Namaste! 👋',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  Text(
                    _userModel?.name ?? _user?.displayName ?? 'User',
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const MapScreen()),
                    ),
                    icon: const Icon(Icons.map_rounded,
                        color: AppColors.white, size: 28),
                  ),
                  CircleAvatar(
                    radius: 24.r,
                    backgroundColor: AppColors.white.withValues(alpha: 0.2),
                    backgroundImage: _userModel?.profilePic.isNotEmpty == true
                        ? NetworkImage(_userModel!.profilePic)
                        : null,
                    child: _userModel?.profilePic.isNotEmpty == true
                        ? null
                        : Icon(Icons.person, color: AppColors.white, size: 28.sp),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: 20.h),

          // Search Bar
          GestureDetector(
            onTap: () => setState(() => _selectedIndex = 1),
            child: Container(
              padding:
              EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.search,
                      color: AppColors.textHint, size: 20.sp),
                  SizedBox(width: 8.w),
                  Text(
                    'Where do you want to go?',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Quick Actions
  Widget _buildQuickActions() {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedIndex = 1),
                  child: Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.search_rounded,
                            color: AppColors.white, size: 36.sp),
                        SizedBox(height: 8.h),
                        Text(
                          'Find\nRide',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(width: 16.w),

              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedIndex = 2),
                  child: Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.directions_car_rounded,
                            color: AppColors.white, size: 36.sp),
                        SizedBox(height: 8.h),
                        Text(
                          'Offer\nRide',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(width: 16.w),

              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const RideHistoryScreen()),
                  ),
                  child: Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.history_rounded,
                            color: AppColors.white, size: 36.sp),
                        SizedBox(height: 8.h),
                        Text(
                          'My\nRides',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Recent Rides
  Widget _buildRecentRides() {
    return StreamBuilder<List<RideModel>>(
      stream: _user != null ? FirebaseService().getMyRides(_user!.uid) : null,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox();
        }
        final rides = snapshot.data ?? [];
        if (rides.isEmpty) return const SizedBox();

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Offered Rides',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const RideHistoryScreen()),
                    ),
                    child: Text('See All',
                        style: TextStyle(
                            color: AppColors.primary, fontSize: 13.sp)),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              ...rides.take(3).map((ride) => _buildRideCard(ride)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRideCard(RideModel ride) {
    final isCompleted = ride.status == 'completed';
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: ride.status == 'active'
                ? AppColors.primary.withValues(alpha: 0.1)
                : isCompleted
                ? AppColors.success.withValues(alpha: 0.1)
                : AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              ride.status == 'active'
                  ? Icons.directions_car_rounded
                  : isCompleted
                  ? Icons.check_circle_rounded
                  : Icons.cancel_rounded,
              color: ride.status == 'active'
                  ? AppColors.primary
                  : isCompleted
                  ? AppColors.success
                  : AppColors.error,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${ride.from} → ${ride.to}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${ride.rideDate.day}/${ride.rideDate.month} • ${ride.rideTime}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹${ride.pricePerSeat.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // Stats
  Widget _buildStats() {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Impact 🌱',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              _buildStatCard('₹${((_userModel?.totalRides ?? 0) * 150)}', 'Money Saved',
                  Icons.savings_rounded, AppColors.primary),
              SizedBox(width: 12.w),
              _buildStatCard('${((_userModel?.totalRides ?? 0) * 1.5).toStringAsFixed(1)} kg', 'CO₂ Reduced',
                  Icons.eco_rounded, AppColors.success),
              SizedBox(width: 12.w),
              _buildStatCard('${_userModel?.totalRides ?? 0}', 'Total Rides',
                  Icons.directions_car_rounded, AppColors.secondary),
            ],
          ),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28.sp),
            SizedBox(height: 8.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Bottom Navigation
  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) => setState(() => _selectedIndex = index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textHint,
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded), label: 'Home'),
        BottomNavigationBarItem(
            icon: Icon(Icons.search_rounded), label: 'Find'),
        BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_rounded), label: 'Offer'),
        BottomNavigationBarItem(
            icon: Icon(Icons.chat_rounded), label: 'Chat'),
        BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy_rounded), label: 'AI'),
        BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded), label: 'Profile'),
             ],
    );
  }
}