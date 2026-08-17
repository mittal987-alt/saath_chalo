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
import '../../core/constants/app_colors.dart';
import '../../widgets/shimmer_loading.dart';
import '../profile/safety_settings_screen.dart';
import '../ride/find_ride_screen.dart';
import 'map_screen.dart';
import '../chat/chat_list_screen.dart';
import '../chat/ride_chat_screen.dart';
import '../profile/profile_screen.dart';
import '../profile/notification_screen.dart';
import '../profile/ride_history_screen.dart';
import '../ride/ride_details_screen.dart';
import '../ai/ai_assistant_screen.dart';
import '../ride/driver_requests_screen.dart';
import '../ride/my_bookings_screen.dart';
import '../driver/driver_dashboard_screen.dart';
import '../driver/driver_verification_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../l10n/app_localizations.dart';
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
                snippet: '${ride.driverName} • ₹${ride.pricePerSeat}',
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
      if (mounted) setState(() => _isLoadingMap = false);
    }
  }

  Future<void> _fetchUserData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final user = await FirebaseService().getUser(currentUser.uid);
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
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final String title = data['title'] ?? 'Notification';
        final String body = data['body'] ?? '';

        return GestureDetector(
          onTap: () async {
            final navigator = Navigator.of(context);
            await FirebaseFirestore.instance
                .collection('notifications')
                .doc(doc.id)
                .update({'isRead': true});
            if (!mounted) return;
            navigator.push(
              MaterialPageRoute(
                builder: (_) => const NotificationsScreen(),
              ),
            );
          },
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
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
                GestureDetector(
                  onTap: () async {
                    await FirebaseFirestore.instance
                        .collection('notifications')
                        .doc(doc.id)
                        .update({'isRead': true});
                  },
                  child: Icon(Icons.close_rounded,
                      color: AppColors.white.withOpacity(0.8), size: 18.sp),
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
              onPressed: () {
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                }
              },
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
  // Active Ride Chat Banner
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
            snapshot.data!.docs.first.data() as Map<String, dynamic>? ?? {});

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
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(14.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withOpacity(0.3),
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
                    color: AppColors.white.withOpacity(0.2),
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
                          color: AppColors.white.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    color: AppColors.white.withOpacity(0.8), size: 14.sp),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // Driver Active Ride Chat Banner
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
            snapshot.data!.docs.first.data() as Map<String, dynamic>? ?? {});

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
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0),
              borderRadius: BorderRadius.circular(14.r),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1565C0).withOpacity(0.3),
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
                    color: AppColors.white.withOpacity(0.2),
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
                          color: AppColors.white.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    color: AppColors.white.withOpacity(0.8), size: 14.sp),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // Chat Nav Badge
  // ─────────────────────────────────────────────
  Widget _buildChatNavIcon(bool isSelected) {
    final uid = _user?.uid ?? '';
    final color =
    isSelected ? AppColors.primary : AppColors.textHint.withOpacity(0.6);

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

            for (var doc in riderSnap.data?.docs ?? []) {
              final data = doc.data() as Map<String, dynamic>? ?? {};
              if (data['lastSenderId'] != uid) unread++;
            }
            for (var doc in driverSnap.data?.docs ?? []) {
              final data = doc.data() as Map<String, dynamic>? ?? {};
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

  Widget _buildHeaderAction(
      {required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.white, size: 18.sp),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _buildBody(),
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
              _buildActiveChatBanner(),
              _buildDriverChatBanner(),
              _buildQuickActions(),
              _buildMapPreview(),
              _buildRecentRides(),
              _buildStats(),
              SizedBox(height: 120.h),
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28.r),
          bottomRight: Radius.circular(28.r),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 10.h, 12.w, 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Namaste! 👋',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.white.withOpacity(0.75),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _userModel?.name ?? _user?.displayName ?? 'User',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 195.w,
                    child: Wrap(
                      spacing: 4.w,
                      runSpacing: 4.h,
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _buildHeaderAction(
                          icon: Icons.directions_car_rounded,
                          onTap: () {
                            if (_userModel?.isDriverVerified == true) {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                      const DriverDashboardScreen()));
                            } else {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                      const DriverVerificationScreen()));
                            }
                          },
                        ),
                        const LanguageSwitcher(),
                        _buildHeaderAction(
                          icon: Icons.map_rounded,
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const MapScreen())),
                        ),
                        _buildNotificationBell(),
                        GestureDetector(
                          onTap: () => setState(() => _selectedIndex = 3),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.white.withOpacity(0.4),
                                  width: 1.5),
                            ),
                            child: CircleAvatar(
                              radius: 16.r,
                              backgroundColor:
                              AppColors.white.withOpacity(0.15),
                              backgroundImage:
                              _userModel?.profilePic.isNotEmpty == true
                                  ? NetworkImage(_userModel!.profilePic)
                                  : null,
                              child: _userModel?.profilePic.isNotEmpty == true
                                  ? null
                                  : Icon(Icons.person_outline,
                                  color: AppColors.white, size: 16.sp),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const FindRideScreen()),
                ),
                child: Container(
                  padding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
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
                          color: AppColors.textSecondary.withOpacity(0.8),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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
          Wrap(
            spacing: 12.w,
            runSpacing: 12.h,
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
              _buildActionCard(
                l10n?.myRides ?? 'My Rides',
                Icons.history_rounded,
                const Color(0xFF1E88E5),
                    () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const RideHistoryScreen()),
                ),
              ),
              _buildActionCard(
                'Safety',
                Icons.shield_rounded,
                AppColors.error,
                    () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SafetySettingsScreen()),
                ),
              ),
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
    return SizedBox(
      width: 78.w,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              )
            ],
            border: Border.all(color: color.withOpacity(0.08), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20.sp),
              ),
              SizedBox(height: 8.h),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.sp,
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
                    padding:
                    EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
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
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MapScreen()),
                ),
                child: Text(
                  'View Full',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Container(
            height: 180.h,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: _isLoadingMap
                  ? ShimmerLoading(width: double.infinity, height: 180.h, borderRadius: 16.r)
                  : GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentPosition != null
                      ? LatLng(_currentPosition!.latitude,
                      _currentPosition!.longitude)
                      : _defaultLocation,
                  zoom: 14,
                ),
                markers: _rideMarkers,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                onMapCreated: (controller) {
                  _mapController = controller;
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentRides() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Rides',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RideHistoryScreen()),
                ),
                child: Text(
                  'See All',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('rides')
                .orderBy('createdAt', descending: true)
                .limit(3)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return ShimmerLoading(height: 100.h, width: double.infinity, borderRadius: 14.r);
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                        color: AppColors.textHint.withOpacity(0.1)),
                  ),
                  child: Center(
                    child: Text(
                      'No recent rides available.',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }

              return Column(
                children: snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final ride = RideModel.fromMap(data);
                  return Container(
                    margin: EdgeInsets.only(bottom: 10.h),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(14.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                      leading: Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.directions_car_rounded,
                            color: AppColors.primary, size: 20.sp),
                      ),
                      title: Text(
                        '${ride.from} → ${ride.to}',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        'Driver: ${ride.driverName} • ₹${ride.pricePerSeat}',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios_rounded,
                          size: 14.sp, color: AppColors.textHint),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RideDetailScreen(ride: ride),
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 12.h),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.08),
              AppColors.secondary.withOpacity(0.08)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.primary.withOpacity(0.15)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Eco Friendly', '🌱 100%', 'Zero Emission'),
            Container(
                height: 30.h,
                width: 1,
                color: AppColors.textHint.withOpacity(0.2)),
            _buildStatItem('Community', '👥 Trusted', 'Verified Peers'),
            Container(
                height: 30.h,
                width: 1,
                color: AppColors.textHint.withOpacity(0.2)),
            _buildStatItem('Safety', '🛡️ 24/7', 'SOS & Support'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, String subtitle) {
    return Column(
      children: [
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
          title,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 9.sp,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
              _buildNavItem(1, Icons.chat_bubble_rounded,
                  Icons.chat_bubble_outline_rounded, 'Chats',
                  customIcon: _buildChatNavIcon),
              _buildNavItem(2, Icons.smart_toy_rounded,
                  Icons.smart_toy_outlined, 'AI Assistant'),
              _buildNavItem(3, Icons.person_rounded,
                  Icons.person_outline_rounded, 'Profile'),
              _buildNavItem(4, Icons.car_rental_rounded,
                  Icons.car_rental_outlined, 'Requests'),
              _buildNavItem(5, Icons.bookmark_rounded,
                  Icons.bookmark_outline_rounded, 'Bookings'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      int index, IconData activeIcon, IconData inactiveIcon, String label,
      {Widget Function(bool)? customIcon}) {
    final isSelected = _selectedIndex == index;
    final color =
    isSelected ? AppColors.primary : AppColors.textHint.withOpacity(0.6);

    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            customIcon != null
                ? customIcon(isSelected)
                : Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: color,
              size: 22.sp,
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}