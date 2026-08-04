import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'SaathChalo'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Travel Together, Save Together!'**
  String get tagline;

  /// No description provided for @namaste.
  ///
  /// In en, this message translates to:
  /// **'Namaste! 👋'**
  String get namaste;

  /// No description provided for @findRide.
  ///
  /// In en, this message translates to:
  /// **'Find Ride'**
  String get findRide;

  /// No description provided for @offerRide.
  ///
  /// In en, this message translates to:
  /// **'Offer Ride'**
  String get offerRide;

  /// No description provided for @myRides.
  ///
  /// In en, this message translates to:
  /// **'My Rides'**
  String get myRides;

  /// No description provided for @earnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get earnings;

  /// No description provided for @chats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chats;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @requests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get requests;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @ai.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get ai;

  /// No description provided for @whereToGo.
  ///
  /// In en, this message translates to:
  /// **'Where do you want to go?'**
  String get whereToGo;

  /// No description provided for @exploreServices.
  ///
  /// In en, this message translates to:
  /// **'Explore Services'**
  String get exploreServices;

  /// No description provided for @liveRideNetwork.
  ///
  /// In en, this message translates to:
  /// **'Live Ride Network'**
  String get liveRideNetwork;

  /// No description provided for @myOfferedRides.
  ///
  /// In en, this message translates to:
  /// **'My Offered Rides'**
  String get myOfferedRides;

  /// No description provided for @yourImpact.
  ///
  /// In en, this message translates to:
  /// **'Your Impact 🌱'**
  String get yourImpact;

  /// No description provided for @moneySaved.
  ///
  /// In en, this message translates to:
  /// **'Money Saved'**
  String get moneySaved;

  /// No description provided for @co2Reduced.
  ///
  /// In en, this message translates to:
  /// **'CO₂ Reduced'**
  String get co2Reduced;

  /// No description provided for @totalRides.
  ///
  /// In en, this message translates to:
  /// **'Total Rides'**
  String get totalRides;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @searchRides.
  ///
  /// In en, this message translates to:
  /// **'Search Rides'**
  String get searchRides;

  /// No description provided for @requestRide.
  ///
  /// In en, this message translates to:
  /// **'Request Ride'**
  String get requestRide;

  /// No description provided for @offerRideNow.
  ///
  /// In en, this message translates to:
  /// **'Offer Ride Now'**
  String get offerRideNow;

  /// No description provided for @vehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get vehicle;

  /// No description provided for @pricePerSeat.
  ///
  /// In en, this message translates to:
  /// **'Price per Seat'**
  String get pricePerSeat;

  /// No description provided for @availableSeats.
  ///
  /// In en, this message translates to:
  /// **'Available Seats'**
  String get availableSeats;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @womenOnly.
  ///
  /// In en, this message translates to:
  /// **'Women Only Ride 👩'**
  String get womenOnly;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @signup.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signup;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get email;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @rideHistory.
  ///
  /// In en, this message translates to:
  /// **'Ride History'**
  String get rideHistory;

  /// No description provided for @offered.
  ///
  /// In en, this message translates to:
  /// **'Offered'**
  String get offered;

  /// No description provided for @booked.
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get booked;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @emergencyContacts.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contacts'**
  String get emergencyContacts;

  /// No description provided for @safetySettings.
  ///
  /// In en, this message translates to:
  /// **'Safety Settings'**
  String get safetySettings;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About SaathChalo'**
  String get aboutApp;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified User'**
  String get verified;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get active;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'COMPLETED'**
  String get completed;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'CANCELLED'**
  String get cancelled;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Driver ⏳'**
  String get pending;

  /// No description provided for @confirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed ✅'**
  String get confirmed;

  /// No description provided for @started.
  ///
  /// In en, this message translates to:
  /// **'Ride Started 🟢'**
  String get started;

  /// No description provided for @ended.
  ///
  /// In en, this message translates to:
  /// **'Completed ✅'**
  String get ended;

  /// No description provided for @payNow.
  ///
  /// In en, this message translates to:
  /// **'Pay Now 💳'**
  String get payNow;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid ✅'**
  String get paid;

  /// No description provided for @chatWithDriver.
  ///
  /// In en, this message translates to:
  /// **'Chat with Driver'**
  String get chatWithDriver;

  /// No description provided for @chatWithRider.
  ///
  /// In en, this message translates to:
  /// **'Chat with Rider'**
  String get chatWithRider;

  /// No description provided for @trackMyRide.
  ///
  /// In en, this message translates to:
  /// **'Track My Ride'**
  String get trackMyRide;

  /// No description provided for @shareRide.
  ///
  /// In en, this message translates to:
  /// **'Share My Ride'**
  String get shareRide;

  /// No description provided for @noRidesFound.
  ///
  /// In en, this message translates to:
  /// **'No rides found!'**
  String get noRidesFound;

  /// No description provided for @noBookingsYet.
  ///
  /// In en, this message translates to:
  /// **'No booked rides yet!'**
  String get noBookingsYet;

  /// No description provided for @askMeAnything.
  ///
  /// In en, this message translates to:
  /// **'Ask me anything...'**
  String get askMeAnything;

  /// No description provided for @seatsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} left'**
  String seatsLeft(int count);

  /// No description provided for @seatsToBook.
  ///
  /// In en, this message translates to:
  /// **'Seats to book'**
  String get seatsToBook;

  /// No description provided for @totalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get totalAmount;

  /// No description provided for @perSeat.
  ///
  /// In en, this message translates to:
  /// **'per seat'**
  String get perSeat;

  /// No description provided for @sendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOtp;

  /// No description provided for @verifyOtp.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get verifyOtp;

  /// No description provided for @enterPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter 10 digit number'**
  String get enterPhone;

  /// No description provided for @enterOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter OTP'**
  String get enterOtp;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back! 👋'**
  String get welcomeBack;

  /// No description provided for @joinSaathChalo.
  ///
  /// In en, this message translates to:
  /// **'Join SaathChalo! 🚗'**
  String get joinSaathChalo;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @adminDashboard.
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard 👑'**
  String get adminDashboard;

  /// No description provided for @totalUsers.
  ///
  /// In en, this message translates to:
  /// **'Total Users'**
  String get totalUsers;

  /// No description provided for @totalEarnings.
  ///
  /// In en, this message translates to:
  /// **'Net Earnings'**
  String get totalEarnings;

  /// No description provided for @weeklyEarnings.
  ///
  /// In en, this message translates to:
  /// **'Weekly Earnings 📊'**
  String get weeklyEarnings;

  /// No description provided for @recentEarnings.
  ///
  /// In en, this message translates to:
  /// **'Recent Earnings'**
  String get recentEarnings;

  /// No description provided for @netEarnings.
  ///
  /// In en, this message translates to:
  /// **'Net Earnings'**
  String get netEarnings;

  /// No description provided for @platformFee.
  ///
  /// In en, this message translates to:
  /// **'Platform Fee'**
  String get platformFee;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get allTime;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
