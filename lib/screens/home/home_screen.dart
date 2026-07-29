import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/firebase_services.dart';
import '../../models/user_model.dart';
import '../../models/ride_model.dart';
import '../../models/booking_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/shimmer_loading.dart';
import '../ride/find_ride_screen.dart';
import '../ride/offer_ride_screen.dart';
import 'map_screen.dart';
import '../chat/chat_list_screen.dart';
import '../chat/ride_chat_screen.dart';
import '../profile/profile_screen.dart';
import '../profile/ride_history_screen.dart';
import '../ride/ride_details_screen.dart';
import '../ai/ai_assistant_screen.dart';
import '../ride/driver_requests_screen.dart';
import '../ride/my_bookings_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../widgets/language_switcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final User? _user = FirebaseAuth.instance.currentUser;
  UserModel? _userModel;

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
                snippet:
                '${ride.driverName} • ₹${ride.pricePerSeat}',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueAzure),
            );
          }).toSet();
        });
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission =
      await Geolocator.checkPermission();
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
      if (mounted) setState(() => _isLoadingMap = false);
    }
  }

  Future<void> _fetchUserData() async {
    if (_user != null) {
      final user = await FirebaseService().getUser(_user!.uid);
      if (mounted) setState(() => _userModel = user);
    }
  }

  // ─────────────────────────────────────────────
  // Notification Banner
  // ─────────────────────────────────────────────
  Widget _buildNotificationBanner() {
    final uid = _user?.uid ?? '';
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('toUid', isEqualTo: uid)
          .where('isRead', isEqualTo: false)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }
        final doc = snapshot.data!.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        final String title = data['title'] ?? 'Notification';
        final String body = data['body'] ?? '';

        return GestureDetector(
          onTap: () async {
            await FirebaseFirestore.instance
                .collection('notifications')
                .doc(doc.id)
                .update({'isRead': true});
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
                  color: AppColors.primary.withValues(alpha: 0.3),
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
                    color: AppColors.white.withValues(alpha: 0.2),
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
                          color: AppColors.white.withValues(alpha: 0.85),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    await FirebaseFirestore.instance
                        .collection('notifications')
                        .doc(doc.id)
                        .update({'isRead': true});
                  },
                  child: Icon(Icons.close_rounded,
                      color: AppColors.white.withValues(alpha: 0.8),
                      size: 18.sp),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // Notification Bell
  // ─────────────────────────────────────────────
  Widget _buildNotificationBell() {
    final uid = _user?.uid ?? '';
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('toUid', isEqualTo: uid)
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data?.docs.length ?? 0;
        return Stack(
          children: [
            IconButton(
              onPressed: () => setState(() => _selectedIndex = 3),
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

  // ─────────────────────────────────────────────
  // ✅ Active Ride Chat Banner
  // Shows when rider has an accepted/confirmed booking
  // ─────────────────────────────────────────────
  Widget _buildActiveChatBanner() {
    final uid = _user?.uid ?? '';
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('riderUid', isEqualTo: uid)
          .where('status', whereIn: [
        'accepted',
        'confirmed',
        'en_route',
        'started',
      ]).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final booking = BookingModel.fromMap(
            snapshot.data!.docs.first.data()
            as Map<String, dynamic>);

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RideChatScreen(
                booking: booking,
                isDriver: false,
              ),
            ),
          ),
          child: Container(
            margin: EdgeInsets.symmetric(
                horizontal: 16.w, vertical: 4.h),
            padding: EdgeInsets.symmetric(
                horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(14.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 34.w,
                  height: 34.w,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.chat_rounded,
                      color: AppColors.white, size: 18.sp),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chat with ${booking.driverName.isEmpty ? 'Your Driver' : booking.driverName} 🚗',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${booking.from} → ${booking.to}',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    color: AppColors.white.withValues(alpha: 0.8),
                    size: 14.sp),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // ✅ Driver Active Ride Chat Banner
  // Shows when driver has accepted bookings
  // ─────────────────────────────────────────────
  Widget _buildDriverChatBanner() {
    final uid = _user?.uid ?? '';
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('driverUid', isEqualTo: uid)
          .where('status', whereIn: [
        'accepted',
        'confirmed',
        'en_route',
        'started',
      ]).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final count = snapshot.data!.docs.length;
        final booking = BookingModel.fromMap(
            snapshot.data!.docs.first.data()
            as Map<String, dynamic>);

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RideChatScreen(
                booking: booking,
                isDriver: true,
              ),
            ),
          ),
          child: Container(
            margin: EdgeInsets.symmetric(
                horizontal: 16.w, vertical: 4.h),
            padding: EdgeInsets.symmetric(
                horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0),
              borderRadius: BorderRadius.circular(14.r),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 34.w,
                  height: 34.w,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.chat_rounded,
                      color: AppColors.white, size: 18.sp),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chat with ${count > 1 ? '$count Riders' : (booking.riderName.isEmpty ? 'Rider' : booking.riderName)} 👤',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${booking.from} → ${booking.to}',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    color: AppColors.white.withValues(alpha: 0.8),
                    size: 14.sp),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // ✅ Chat Nav Badge — unread count
  // ─────────────────────────────────────────────
  Widget _buildChatNavIcon(bool isSelected) {
    final uid = _user?.uid ?? '';
    final color = isSelected ? AppColors.primary : AppColors.textHint.withValues(alpha: 0.6);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ride_chats')
          .where('riderUid', isEqualTo: uid)
          .snapshots(),
      builder: (context, riderSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('ride_chats')
              .where('driverUid', isEqualTo: uid)
              .snapshots(),
          builder: (context, driverSnap) {
            int unread = 0;

            // Count chats where last message is NOT from me
            for (var doc in riderSnap.data?.docs ?? []) {
              final data = doc.data() as Map<String, dynamic>;
              if (data['lastSenderId'] != uid) unread++;
            }
            for (var doc in driverSnap.data?.docs ?? []) {
              final data = doc.data() as Map<String, dynamic>;
              if (data['lastSenderId'] != uid) unread++;
            }

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected
                      ? Icons.chat_bubble_rounded
                      : Icons.chat_bubble_outline_rounded,
                  color: color,
                  size: 22.sp,
                ),
                if (unread > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          unread > 9 ? '9+' : '$unread',
                          style: const TextStyle(
                            fontSize: 8,
                            color: Colors.white,
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
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
              _buildNotificationBanner(),     // 🔔 Notifications
              _buildActiveChatBanner(),       // 💬 Rider chat banner
              _buildDriverChatBanner(),       // 💬 Driver chat banner
              _buildQuickActions(),
              _buildMapPreview(),
              _buildRecentRides(),
              _buildStats(),
              SizedBox(height: 100.h),
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

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 28.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.85)
          ],
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
                    _userModel?.name ??
                        _user?.displayName ??
                        'User',
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
                  const LanguageSwitcher(),
                  SizedBox(width: 8.w),
                  IconButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MapScreen())),
                    icon: const Icon(Icons.map_rounded,
                        color: AppColors.white, size: 26),
                  ),
                  _buildNotificationBell(),
                  GestureDetector(
                    onTap: () => setState(() => _selectedIndex = 3),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.white.withValues(alpha: 0.4),
                            width: 1.5),
                      ),
                      child: CircleAvatar(
                        radius: 20.r,
                        backgroundColor:
                        AppColors.white.withValues(alpha: 0.15),
                        backgroundImage:
                        _userModel?.profilePic.isNotEmpty == true
                            ? NetworkImage(_userModel!.profilePic)
                            : null,
                        child:
                        _userModel?.profilePic.isNotEmpty == true
                            ? null
                            : Icon(Icons.person_outline,
                            color: AppColors.white,
                            size: 20.sp),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: 24.h),

          // Search Bar
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const FindRideScreen()),
            ),
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: 16.w, vertical: 12.h),
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
                  Icon(Icons.search_rounded,
                      color: AppColors.primary, size: 20.sp),
                  SizedBox(width: 12.w),
                  Text(
                    l10n?.whereToGo ?? 'Where do you want to go?',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color:
                      AppColors.textSecondary.withValues(alpha: 0.8),
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

  Widget _buildQuickActions() {
    final l10n = AppLocalizations.of(context);
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
                l10n?.findRide ?? 'Find Ride',
                Icons.search_rounded,
                AppColors.primary,
                    () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const FindRideScreen()),
                ),
              ),
              SizedBox(width: 12.w),
              _buildActionCard(
                l10n?.offerRide ?? 'Offer Ride',
                Icons.directions_car_rounded,
                AppColors.secondary,
                    () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const OfferRideScreen()),
                ),
              ),
              SizedBox(width: 12.w),
              _buildActionCard(
                l10n?.myRides ?? 'My Rides',
                Icons.history_rounded,
                const Color(0xFF1E88E5),
                    () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                      const RideHistoryScreen()),
                ),
              ),
              SizedBox(width: 12.w),
              // ✅ Chat quick action
              _buildActionCard(
                'Chats',
                Icons.chat_rounded,
                AppColors.success,
                    () => setState(() => _selectedIndex = 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
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
            border: Border.all(
                color: color.withValues(alpha: 0.08), width: 1),
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
                  fontSize: 11.sp,
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
                    padding: EdgeInsets.symmetric(
                        horizontal: 8.w, vertical: 4.h),
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
                  MaterialPageRoute(
                      builder: (context) => const MapScreen()),
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
                      ? Container(
                    color: AppColors.background,
                    child: Center(
                        child: ShimmerLoading(width: double.infinity, height: 180.h, borderRadius: 20.r)),
                  )
                      : GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _currentPosition != null
                          ? LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude)
                          : _defaultLocation,
                      zoom: 12,
                    ),
                    onMapCreated: (controller) {
                      _mapController = controller;
                      if (_currentPosition != null) {
                        _mapController?.animateCamera(
                          CameraUpdate.newLatLng(LatLng(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                          )),
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
                        MaterialPageRoute(
                            builder: (context) => const MapScreen()),
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
      stream: _user != null
          ? FirebaseService().getMyRides(_user!.uid)
          : null,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
            child: Column(
              children: List.generate(2, (index) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: ShimmerLoading(width: double.infinity, height: 80.h, borderRadius: 20.r),
              )),
            ),
          );
        }
        final rides = snapshot.data ?? [];
        if (rides.isEmpty) {
          return Center(
            child: Column(
              children: [
                SizedBox(
                  height: 150.h,
                  child: Lottie.network('https://lottie.host/804c8612-4cf0-4963-8a30-80252ad8b9ed/cWl4XFhH0R.json'), // A generic empty state lottie url
                ),
                Text('No recent rides', style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp)),
              ],
            ),
          );
        }

        return Padding(
          padding:
          EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
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
                      MaterialPageRoute(
                          builder: (context) =>
                          const RideHistoryScreen()),
                    ),
                    child: Text('See All',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              ...rides.take(3).map((ride) => GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        RideDetailScreen(ride: ride),
                  ),
                ),
                child: _buildRideCard(ride),
              )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRideCard(RideModel ride) {
    final isCompleted = ride.status == 'completed';
    return Hero(
      tag: 'ride_card_${ride.rideId}',
      child: Material(
        color: Colors.transparent,
        child: Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.border.withOpacity(0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: ride.status == 'active'
                  ? AppColors.primary.withOpacity(0.1)
                  : isCompleted
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16.r),
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
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${ride.from} → ${ride.to}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 12.sp, color: AppColors.textSecondary),
                    SizedBox(width: 4.w),
                    Text(
                      '${ride.rideDate.day}/${ride.rideDate.month} • ${ride.rideTime}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              '₹${ride.pricePerSeat.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding:
      EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
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
              _buildStatCard(
                '₹${(_userModel?.totalMoneySaved ?? 0).toStringAsFixed(0)}',
                'Money Saved',
                Icons.savings_rounded,
                AppColors.primary,
              ),
              SizedBox(width: 10.w),
              _buildStatCard(
                '${(_userModel?.totalCo2Saved ?? 0).toStringAsFixed(1)} kg',
                'CO₂ Reduced',
                Icons.eco_rounded,
                AppColors.success,
              ),
              SizedBox(width: 10.w),
              _buildStatCard(
                '${_userModel?.totalRides ?? 0}',
                'Total Rides',
                Icons.directions_car_rounded,
                AppColors.secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding:
        EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColors.border.withOpacity(0.5), width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24.sp),
            ),
            SizedBox(height: 12.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.sp,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // ✅ Bottom Nav with Chat Badge
  // ─────────────────────────────────────────────
  Widget _buildBottomNav() {
    return Align(
      alignment: const Alignment(0, 0.95),
      child: Container(
        margin: EdgeInsets.fromLTRB(24.w, 0, 24.w, 16.h),
        height: 68.h,
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(color: AppColors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.15),
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
                _buildNavItem(0, Icons.home_rounded,
                    Icons.home_outlined, 'Home'),
                _buildChatNavItemWrapper(),
                _buildNavItem(4, Icons.inbox_rounded,
                    Icons.inbox_outlined, 'Requests'),
                _buildNavItem(2, Icons.smart_toy_rounded,
                    Icons.smart_toy_outlined, 'AI'),
                _buildNavItem(3, Icons.person_rounded,
                    Icons.person_outline_rounded, 'Profile'),
                _buildNavItem(5, Icons.history_rounded,
                    Icons.history_outlined, 'Rides'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Chat nav item with unread badge
  Widget _buildChatNavItemWrapper() {
    final isSelected = _selectedIndex == 1;
    final color = isSelected
        ? AppColors.primary
        : AppColors.textHint.withValues(alpha: 0.6);

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedIndex = 1);
      },
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Container(
        padding:
        EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildChatNavIcon(isSelected),
            SizedBox(height: 3.h),
            Text(
              'Chat',
              style: TextStyle(
                color: color,
                fontSize: 10.sp,
                fontWeight: isSelected
                    ? FontWeight.bold
                    : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon,
      IconData inactiveIcon, String label) {
    final isSelected = _selectedIndex == index;
    final color = isSelected
        ? AppColors.primary
        : AppColors.textHint.withOpacity(0.6);

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedIndex = index);
      },
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Container(
        padding:
        EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: isSelected ? EdgeInsets.all(6.w) : EdgeInsets.zero,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
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
                fontWeight: isSelected
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
