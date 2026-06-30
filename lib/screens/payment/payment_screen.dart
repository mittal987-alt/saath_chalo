import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../services/firebase_services.dart';

import '../../core/constants/secrets.dart';

class PaymentScreen extends StatefulWidget {
  final String rideId;
  final String driverName;
  final String from;
  final String to;
  final double pricePerSeat;
  final int seats;

  const PaymentScreen({
    super.key,
    required this.rideId,
    required this.driverName,
    required this.from,
    required this.to,
    required this.pricePerSeat,
    required this.seats,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late Razorpay _razorpay;
  bool _isLoading = false;
  String _selectedMethod = 'razorpay'; // 'razorpay' or 'cash'
  final User? _user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  double get totalAmount => widget.pricePerSeat * widget.seats;

  @override 
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  // ✅ Payment Success
  void _onPaymentSuccess(PaymentSuccessResponse response) async {
    setState(() => _isLoading = false);

    final FirebaseService firebaseService = FirebaseService();

    // 1. Save payment to Firestore
    await _db.collection('payments').add({
      'rideId': widget.rideId,
      'userId': _user?.uid,
      'paymentId': response.paymentId,
      'orderId': response.orderId,
      'amount': totalAmount,
      'status': 'success',
      'method': 'online',
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 2. Book seat (decrement availableSeats)
    for (int i = 0; i < widget.seats; i++) {
      await firebaseService.bookSeat(widget.rideId);
    }

    // 3. Update User Stats (Money Saved & CO2 Saved)
    if (_user != null) {
      await _db.collection('users').doc(_user!.uid).update({
        'totalMoneySaved': FieldValue.increment(totalAmount),
        'totalCo2Saved': FieldValue.increment(1.5 * widget.seats),
        'totalRides': FieldValue.increment(1),
      });
    }

    // 4. Send notification to driver
    final rideDoc = await _db.collection('rides').doc(widget.rideId).get();
    final driverUid = rideDoc.data()?['driverUid'];

    if (driverUid != null) {
      await firebaseService.sendNotification(
        toUid: driverUid,
        title: 'Payment Received! 💰',
        body: '${_user?.displayName ?? 'A rider'} paid ₹${totalAmount.toStringAsFixed(0)} for ${widget.seats} seat(s).',
        type: 'payment',
        data: {'rideId': widget.rideId},
      );
    }

    // Show success dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 80.sp),
              SizedBox(height: 16.h),
              Text(
                'Payment Successful!',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                '₹${totalAmount.toStringAsFixed(0)} paid successfully!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  'Payment ID: ${response.paymentId}',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      );
    }
  }

  // ✅ Cash Payment Logic
  void _payWithCash() async {
    setState(() => _isLoading = true);
    final FirebaseService firebaseService = FirebaseService();

    try {
      // 1. Save payment record
      await _db.collection('payments').add({
        'rideId': widget.rideId,
        'userId': _user?.uid,
        'amount': totalAmount,
        'status': 'pending_cash',
        'method': 'cash',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 2. Book seats
      for (int i = 0; i < widget.seats; i++) {
        await firebaseService.bookSeat(widget.rideId);
      }

      // 3. Update User Stats
      if (_user != null) {
        await _db.collection('users').doc(_user!.uid).update({
          'totalMoneySaved': FieldValue.increment(totalAmount),
          'totalCo2Saved': FieldValue.increment(1.5 * widget.seats),
          'totalRides': FieldValue.increment(1),
        });
      }

      // 4. Notify Driver
      final rideDoc = await _db.collection('rides').doc(widget.rideId).get();
      final driverUid = rideDoc.data()?['driverUid'];
      if (driverUid != null) {
        await firebaseService.sendNotification(
          toUid: driverUid,
          title: 'New Cash Booking! 💵',
          body: '${_user?.displayName ?? 'A rider'} booked ${widget.seats} seat(s). Please collect ₹${totalAmount.toStringAsFixed(0)} at the end of the ride.',
          type: 'payment_cash',
          data: {'rideId': widget.rideId},
        );
      }

      setState(() => _isLoading = false);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.handshake_rounded, color: AppColors.primary, size: 80.sp),
                SizedBox(height: 16.h),
                Text('Booking Confirmed!', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
                SizedBox(height: 8.h),
                Text('You have chosen to pay by Cash.', textAlign: TextAlign.center),
                SizedBox(height: 12.h),
                Text('Total to pay: ₹${totalAmount.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                SizedBox(height: 24.h),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text('Got it!'),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // ❌ Payment Error
  void _onPaymentError(PaymentFailureResponse response) {
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment Failed: ${response.message}'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  // 👛 External Wallet
  void _onExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('External Wallet: ${response.walletName}'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  // 💳 Open Razorpay or Process Cash
  void _handlePayment() {
    if (_selectedMethod == 'razorpay') {
      _openRazorpay();
    } else {
      _payWithCash();
    }
  }

  void _openRazorpay() {
    setState(() => _isLoading = true);

    var options = {
      'key': Secrets.razorpayKey,
      'amount': (totalAmount * 100).toInt(), // Amount in paise
      'name': 'SaathChalo',
      'description': '${widget.from} → ${widget.to} (${widget.seats} seats)',
      'prefill': {
        'contact': _user?.phoneNumber ?? '',
        'email': _user?.email ?? '',
      },
      'theme': {
        'color': '#00A86B',
      },
      'notes': {
        'ride_id': widget.rideId,
        'driver_name': widget.driverName,
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            // Ride Summary Card
            _buildRideSummary(),

            SizedBox(height: 16.h),

            // Price Breakdown
            _buildPriceBreakdown(),

            SizedBox(height: 16.h),

            // Payment Methods
            _buildPaymentMethods(),

            SizedBox(height: 24.h),

            // Pay Button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _handlePayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: Size(double.infinity, 56.h),
              ),
              icon: _isLoading
                  ? SizedBox(
                width: 20.w,
                height: 20.w,
                child: const CircularProgressIndicator(
                    color: AppColors.white, strokeWidth: 2),
              )
                  : Icon(_selectedMethod == 'razorpay' ? Icons.payment_rounded : Icons.handshake_rounded),
              label: Text(
                _isLoading
                    ? 'Processing...'
                    : _selectedMethod == 'razorpay'
                    ? 'Pay ₹${totalAmount.toStringAsFixed(0)}'
                    : 'Confirm Cash Booking',
                style: TextStyle(
                    fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
            ),

            SizedBox(height: 12.h),

            // Secure Payment Note
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_rounded,
                    size: 14.sp, color: AppColors.textHint),
                SizedBox(width: 4.w),
                Text(
                  'Secured by Razorpay',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideSummary() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ride Summary',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),

          // Driver
          Row(
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Icon(Icons.person_rounded,
                    color: AppColors.primary, size: 22.sp),
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.driverName,
                      style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  Row(
                    children: [
                      Icon(Icons.star_rounded,
                          color: Colors.amber, size: 12.sp),
                      Text(' 4.8',
                          style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: 16.h),
          Divider(color: AppColors.divider),
          SizedBox(height: 16.h),

          // Route
          Row(
            children: [
              Column(
                children: [
                  Icon(Icons.circle,
                      color: AppColors.primary, size: 10.sp),
                  Container(
                      width: 1.5, height: 20.h, color: AppColors.border),
                  Icon(Icons.location_on,
                      color: AppColors.secondary, size: 14.sp),
                ],
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.from,
                      style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  SizedBox(height: 12.h),
                  Text(widget.to,
                      style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBreakdown() {
    final double subtotal = totalAmount;
    final double platformFee = subtotal * 0.05;
    final double total = subtotal + platformFee;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Price Breakdown',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          _buildPriceRow('Fare (₹${widget.pricePerSeat.toStringAsFixed(0)} × ${widget.seats})', '₹${subtotal.toStringAsFixed(0)}'),
          SizedBox(height: 8.h),
          _buildPriceRow(
              'Platform Fee (5%)', '₹${platformFee.toStringAsFixed(0)}'),
          SizedBox(height: 8.h),
          Divider(color: AppColors.divider),
          SizedBox(height: 8.h),
          _buildPriceRow(
            'Total Amount',
            '₹${total.toStringAsFixed(0)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value,
      {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 15.sp : 13.sp,
            fontWeight:
            isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal
                ? AppColors.textPrimary
                : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18.sp : 13.sp,
            fontWeight: FontWeight.bold,
            color: isTotal ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethods() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Methods',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          _buildPaymentOption(
            Icons.account_balance_rounded,
            'Online (UPI, Card, NetBanking)',
            _selectedMethod == 'razorpay',
            () => setState(() => _selectedMethod = 'razorpay'),
          ),
          _buildPaymentOption(
            Icons.money_rounded,
            'Cash Payment',
            _selectedMethod == 'cash',
            () => setState(() => _selectedMethod = 'cash'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(
      IconData icon, String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(10.r),
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.05)
              : AppColors.white,
        ),
        child: Row(
          children: [
            Icon(icon,
                color:
                isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 22.sp),
            SizedBox(width: 12.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 18.sp),
          ],
        ),
      ),
    );
  }
}