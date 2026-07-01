import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
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
import '../ride/ride_details_screen.dart';
import '../ai/ai_assistant_screen.dart';
import '../ride/driver_requests_screen.dart';
import '../ride/my_bookings_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Show notification banner at top of home
  Widget _buildNotificationBanner() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService().getNotifications(uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Notification Stream Error: ${snapshot.error}');
          return const SizedBox.shrink();
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        // Get the latest unread notification
        final unreadDocs = snapshot.data!.docs.where((d) => (d.data() as Map<String, dynamic>)['isRead'] == false).toList();
        
        if (unreadDocs.isEmpty) return const SizedBox.shrink();

        final doc = unreadDocs.first;
        final data = doc.data() as Map<String, dynamic>;
        final String title = data['title'] ?? 'Notification';
        final String body = data['body'] ?? '';

        return GestureDetector(
          onTap: () async {
            await FirebaseService().markNotificationRead(doc.id);
          },
          child: Container(
            margin: EdgeInsets.symmetric(
                horizontal: 16.w, vertical: 8.h),
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(14.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 36.w,
                  height: 36.w,
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.notifications_rounded,
                      color: AppColors.white, size: 20.sp),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        body,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.white.withOpacity(0.85),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                GestureDetector(
                  onTap: () async {
                    await FirebaseService().markNotificationRead(doc.id);
                  },
                  child: Icon(Icons.close_rounded,
                      color: AppColors.white.withOpacity(0.8),
                      size: 18.sp),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

// Unread notification count for bell icon
  Widget _buildNotificationBell() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService().getNotifications(uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Icon(Icons.notifications_rounded, color: AppColors.white, size: 26);
        
        final unreadCount = snapshot.data?.docs.where((d) => (d.data() as Map<String, dynamic>)['isRead'] == false).length ?? 0;
        
        return Stack(
          children: [
            IconButton(
              onPressed: () => setState(() => _selectedIndex = 4),
              icon: const Icon(Icons.notifications_rounded,
                  color: AppColors.white, size: 26),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: 16.w,
                  height: 16.w,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      style: TextStyle(
                        fontSize: 9.sp,
                        color: AppColors.white,
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
  int _selectedIndex = 0;
  final User? _user = FirebaseAuth.instance.currentUser;
  UserModel? _userModel;

  // Fake static count for preview; plug your streams here
  final int _unreadChatCount = 3;

  // Map related variables
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLoadingMap = true;
  Set<Marker> _rideMarkers = {};
  static const LatLng _defaultLocation = LatLng(28.6139, 77.2090);

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _getCurrentLocation();
    _listenToActiveRides();
  }

  void _listenToActiveRides() {
    FirebaseService().getActiveRides().listen((rides) {
      if (mounted) {
        setState(() {
          _rideMarkers = rides.map((ride) {
            return Marker(
              markerId: MarkerId(ride.rideId),
              position: LatLng(ride.fromLat, ride.fromLng),
              infoWindow: InfoWindow(
                title: '${ride.from} → ${ride.to}',
                snippet: '${ride.driverName} • ₹${ride.pricePerSeat}',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            );
          }).toSet();
        });
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoadingMap = false);
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLoadingMap = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMap = false);
      }
    }
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
      extendBody: true, // Allows content to flow softly underneath the floating nav bar
      body: SafeArea(
        bottom: false,
        child: _buildBody(),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildNotificationBanner(),
              _buildQuickActions(),
              _buildMapPreview(),
              _buildRecentRides(),
              _buildStats(),
              SizedBox(height: 100.h), // Padding to prevent bottom floating bar overlapping content
            ],
          ),
        );
      case 1:
        return const ChatListScreen();
      case 2:
        return const AIAssistantScreen();
      case 3:
        return const ProfileScreen();
      case 4:
        return const DriverRequestsScreen();
      case 5:
        return const MyBookingsScreen();
      default:
        return const SizedBox();
    }
  }

  // Refactored Premium Header
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 28.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28.r),
          bottomRight: Radius.circular(28.r),
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
                      color: AppColors.white.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 2.h),
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
                  // Map button
                  IconButton(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const MapScreen())),
                    icon: const Icon(Icons.map_rounded,
                        color: AppColors.white, size: 26),
                  ),
                  // 🔔 Notification bell with badge
                  _buildNotificationBell(),
                  // Avatar
                  GestureDetector(
                    onTap: () => setState(() => _selectedIndex = 3),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white.withValues(alpha: 0.4), width: 1.5),
                      ),
                      child: CircleAvatar(
                        radius: 20.r,
                        backgroundColor: AppColors.white.withValues(alpha: 0.15),
                        backgroundImage: _userModel?.profilePic.isNotEmpty == true
                            ? NetworkImage(_userModel!.profilePic)
                            : null,
                        child: _userModel?.profilePic.isNotEmpty == true
                            ? null
                            : Icon(Icons.person_outline, color: AppColors.white, size: 20.sp),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 24.h),

          // Modern Clean Search Bar Card
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FindRideScreen()),
            ),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: AppColors.primary, size: 20.sp),
                  SizedBox(width: 12.w),
                  Text(
                    'Where do you want to go?',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w400,
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

  Widget _buildHeaderRoundButton({required IconData icon, required VoidCallback onTap}) {
    return Container(
      height: 40.w,
      width: 40.w,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        icon: Icon(icon, color: AppColors.white, size: 20.sp),
      ),
    );
  }

  // Refactored Services Section
  Widget _buildQuickActions() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Explore Services',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              _buildActionCard(
                'Find Ride',
                Icons.search_rounded,
                AppColors.primary,
                    () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FindRideScreen()),
                ),
              ),
              SizedBox(width: 12.w),
              _buildActionCard(
                'Offer Ride',
                Icons.directions_car_rounded,
                AppColors.secondary,
                    () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OfferRideScreen()),
                ),
              ),
              SizedBox(width: 12.w),
              _buildActionCard(
                'My Rides',
                Icons.history_rounded,
                const Color(0xFF1E88E5),
                    () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RideHistoryScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              )
            ],
            border: Border.all(color: color.withValues(alpha: 0.08), width: 1),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22.sp),
              ),
              SizedBox(height: 8.h),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapPreview() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Live Ride Network',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6.w,
                          height: 6.w,
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'LIVE',
                          style: TextStyle(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MapScreen()),
                ),
                child: Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Container(
            height: 180.h,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.r),
              child: Stack(
                children: [
                  _isLoadingMap 
                    ? const Center(child: CircularProgressIndicator())
                    : GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _currentPosition != null 
                              ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                              : _defaultLocation,
                          zoom: 12,
                        ),
                        onMapCreated: (controller) {
                          _mapController = controller;
                          if (_currentPosition != null) {
                            _mapController?.animateCamera(
                              CameraUpdate.newLatLng(
                                LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                              ),
                            );
                          }
                        },
                        markers: _rideMarkers,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        scrollGesturesEnabled: false,
                        rotateGesturesEnabled: false,
                        tiltGesturesEnabled: false,
                      ),
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MapScreen()),
                      ),
                      child: Container(color: Colors.transparent),
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

  Widget _buildRecentRides() {
    return StreamBuilder<List<RideModel>>(
      stream: _user != null ? FirebaseService().getMyRides(_user!.uid) : null,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox();
        final rides = snapshot.data ?? [];
        if (rides.isEmpty) return const SizedBox();

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Offered Rides',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RideHistoryScreen()),
                    ),
                    child: Text('See All', style: TextStyle(color: AppColors.primary, fontSize: 12.sp, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              ...rides.take(3).map((ride) => GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RideDetailScreen(ride: ride),
                      ),
                    );
                  },
                  child: _buildRideCard(ride))),
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
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
              color: ride.status == 'active'
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : isCompleted
                  ? AppColors.success.withValues(alpha: 0.08)
                  : AppColors.error.withValues(alpha: 0.08),
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
              size: 20.sp,
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
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  '${ride.rideDate.day}/${ride.rideDate.month} • ${ride.rideTime}',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹${ride.pricePerSeat.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Impact 🌱',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              _buildStatCard('₹${(_userModel?.totalMoneySaved ?? 0).toStringAsFixed(0)}', 'Money Saved', Icons.savings_rounded, AppColors.primary),
              SizedBox(width: 10.w),
              _buildStatCard('${(_userModel?.totalCo2Saved ?? 0).toStringAsFixed(1)} kg', 'CO₂ Reduced', Icons.eco_rounded, AppColors.success),
              SizedBox(width: 10.w),
              _buildStatCard('${_userModel?.totalRides ?? 0}', 'Total Rides', Icons.directions_car_rounded, AppColors.secondary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24.sp),
            SizedBox(height: 6.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9.sp,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Modern Floating Navigation Bar Implementation
  Widget _buildBottomNav() {
    return Align(
      alignment: const Alignment(0, 0.94),
      child: Container(
        margin: EdgeInsets.fromLTRB(24.w, 0, 24.w, 20.h),
        height: 64.h,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
                _buildNavItem(1, Icons.chat_bubble_rounded, Icons.chat_bubble_outline_rounded, 'Chat'),
                _buildNavItem(4, Icons.inbox_rounded, Icons.inbox_outlined, 'Requests'),
                _buildNavItem(2, Icons.smart_toy_rounded, Icons.smart_toy_outlined, 'AI'),
                _buildNavItem(3, Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
                _buildNavItem(5, Icons.history_rounded, Icons.history_outlined, 'My Rides'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? AppColors.primary : AppColors.textHint.withValues(alpha: 0.6);

    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: color,
              size: 22.sp,
            ),
            SizedBox(height: 3.h),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}