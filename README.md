# Saath Chalo 🚗💚

**Saath Chalo** is a premium, AI-powered carpooling application designed specifically for India. It aims to reduce carbon emissions, traffic congestion, and commuting costs by effortlessly connecting riders and drivers heading in the same direction.

<p align="center">
  <img src="assets/images/app_icon.png" alt="Saath Chalo App Icon" width="150"/>
</p>

## ✨ Key Features

- **Live Google Maps Integration:** Seamless location picking, dynamic routing, and real-time live map tracking using `google_maps_flutter` and `geolocator`.
- **Razorpay Payment Gateway:** Fully integrated secure payment system supporting online payments (UPI, NetBanking, Cards) as well as Cash. Platform fees are dynamically calculated.
- **Robust Admin Dashboard:** A beautiful analytics suite using `fl_chart` to track active rides, revenue, total users, and moderate flagged reviews or SOS alerts.
- **Push Notifications:** Firebase Cloud Messaging (FCM) is fully wired for instant alerts on ride requests, payment confirmations, and chat messages.
- **Real-Time Chat & Calls:** Communicate instantly with your driver/rider using Firebase Firestore and the native phone dialer integration.
- **Advanced Ride Preferences:** Filter rides by Women-Only, Music Allowed, Pets Allowed, Smoking, and AC preference.
- **Gamification & Eco-Tracking:** Users can track their Total Money Saved and Total CO2 Emissions Reduced per ride.

## 🛠 Tech Stack

- **Frontend:** Flutter & Dart
- **Backend:** Firebase (Auth, Firestore, Cloud Messaging)
- **Maps:** Google Maps Platform (Maps SDK, Places SDK, Directions API)
- **Payments:** Razorpay Flutter SDK
- **State Management:** Provider
- **UI Toolkit:** `flutter_screenutil` (responsive sizing), `google_fonts`, `lottie` (animations)

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>=3.0.0)
- Firebase Project configured (Add your `google-services.json` and `GoogleService-Info.plist`)
- Google Maps API Key
- Razorpay API Key

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/saath_chalo.git
   cd saath_chalo
   ```

2. **Configure Secrets**
   Open `lib/core/constants/secrets.dart` and add your API keys:
   ```dart
   class Secrets {
     static const String mapsApiKey = 'YOUR_GOOGLE_MAPS_KEY';
     static const String razorpayKey = 'YOUR_RAZORPAY_KEY';
   }
   ```

3. **Install Dependencies**
   ```bash
   flutter pub get
   ```

4. **Generate App Assets**
   We use packages to auto-generate the native splash screen and launcher icons. Run:
   ```bash
   dart run flutter_launcher_icons
   dart run flutter_native_splash:create
   ```

5. **Run the App**
   ```bash
   flutter run
   ```

## 🌍 Impact
By using Saath Chalo, every shared ride contributes directly to reducing India's carbon footprint. Track your impact right on your profile!
