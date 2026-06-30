import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/ride_model.dart';

import '../../services/firebase_services.dart';
class OfferRideScreen extends StatefulWidget {
  const OfferRideScreen({super.key});

  @override
  State<OfferRideScreen> createState() => _OfferRideScreenState();
}

class _OfferRideScreenState extends State<OfferRideScreen> {
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _priceController = TextEditingController();
  final _vehicleController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _seats = 1;
  bool _womenOnly = false;
  bool _isLoading = false;

  void _offerRide() async {
    if (_fromController.text.isEmpty ||
        _toController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _vehicleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final rideId = DateTime.now().millisecondsSinceEpoch.toString();

      final ride = RideModel(
        rideId: rideId,
        driverUid: user?.uid ?? '',
        driverName: user?.displayName ?? 'User',
        driverPhone: user?.phoneNumber ?? '',
        vehicle: _vehicleController.text,
        from: _fromController.text,
        to: _toController.text,
        fromLat: 0.0, // Should ideally be fetched from a map picker
        fromLng: 0.0,
        toLat: 0.0,
        toLng: 0.0,
        rideDate: _selectedDate,
        rideTime: _selectedTime.format(context),
        availableSeats: _seats,
        pricePerSeat: double.parse(_priceController.text),
        womenOnly: _womenOnly,
        createdAt: DateTime.now(),
      );

      await FirebaseService().offerRide(ride);
      setState(() => _isLoading = false);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 64.sp),
              SizedBox(height: 16.h),
              Text(
                'Ride Offered!',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Your ride is now live on SaathChalo!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Great!'),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _priceController.dispose();
    _vehicleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Offer a Ride'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 40.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route Card
            _buildSectionCard(
              title: '📍 Route Details',
              child: Column(
                children: [
                  _buildLabel('From'),
                  SizedBox(height: 8.h),
                  TextFormField(
                    controller: _fromController,
                    decoration: InputDecoration(
                      hintText: 'Starting location',
                      prefixIcon: Icon(Icons.circle,
                          color: AppColors.primary, size: 12.sp),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  _buildLabel('To'),
                  SizedBox(height: 8.h),
                  TextFormField(
                    controller: _toController,
                    decoration: InputDecoration(
                      hintText: 'Destination',
                      prefixIcon: Icon(Icons.location_on,
                          color: AppColors.secondary, size: 20.sp),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Date & Time Card
            _buildSectionCard(
              title: '🕐 Date & Time',
              child: Row(
                children: [
                  // Date
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now(),
                          lastDate:
                          DateTime.now().add(const Duration(days: 30)),
                        );
                        if (date != null)
                          setState(() => _selectedDate = date);
                      },
                      child: Container(
                        padding: EdgeInsets.all(14.w),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_rounded,
                                color: AppColors.primary, size: 18.sp),
                            SizedBox(width: 8.w),
                            Text(
                              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 12.w),

                  // Time
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _selectedTime,
                        );
                        if (time != null)
                          setState(() => _selectedTime = time);
                      },
                      child: Container(
                        padding: EdgeInsets.all(14.w),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.access_time_rounded,
                                color: AppColors.primary, size: 18.sp),
                            SizedBox(width: 8.w),
                            Text(
                              _selectedTime.format(context),
                              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Vehicle & Price Card
            _buildSectionCard(
              title: '🚗 Vehicle & Price',
              child: Column(
                children: [
                  _buildLabel('Vehicle Details'),
                  SizedBox(height: 8.h),
                  TextFormField(
                    controller: _vehicleController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Swift Dzire • DL 4C 1234',
                      prefixIcon: const Icon(Icons.directions_car_rounded),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      // Price
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Price per Seat'),
                            SizedBox(height: 8.h),
                            TextFormField(
                              controller: _priceController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: '₹ Amount',
                                prefixIcon: const Icon(Icons.currency_rupee_rounded),
                                filled: true,
                                fillColor: AppColors.background,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12.w),
                      // Seats
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Available Seats'),
                            SizedBox(height: 8.h),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12.w, vertical: 10.h),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.r),
                                color: AppColors.background,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      if (_seats > 1)
                                        setState(() => _seats--);
                                    },
                                    child: Icon(Icons.remove_circle_outline,
                                        color: AppColors.primary),
                                  ),
                                  Text('$_seats',
                                      style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.bold)),
                                  GestureDetector(
                                    onTap: () {
                                      if (_seats < 4)
                                        setState(() => _seats++);
                                    },
                                    child: Icon(Icons.add_circle_outline,
                                        color: AppColors.primary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Preferences Card
            _buildSectionCard(
              title: '⚙️ Preferences',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Women Only Ride 👩',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Only women can request this ride',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: _womenOnly,
                    onChanged: (val) => setState(() => _womenOnly = val),
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ),

            SizedBox(height: 32.h),

            // Offer Ride Button
            SizedBox(
              width: double.infinity,
              height: 54.h,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _offerRide,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  elevation: 0,
                ),
                icon: _isLoading
                    ? SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: const CircularProgressIndicator(
                      color: AppColors.white, strokeWidth: 2),
                )
                    : const Icon(Icons.directions_car_rounded),
                label: Text(
                  _isLoading ? 'Publishing...' : 'Publish Ride',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 16.h),
          child,
        ],
      ),
    );
  }


  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }
}