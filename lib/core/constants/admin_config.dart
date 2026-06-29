class AdminConfig {
  // ⚠️ Add your email here - Only you can access admin!
  static const List<String> adminEmails = [
    'rrrr987368@gmail.com', // Replace with your email!
  ];

  static bool isAdmin(String? email) {
    if (email == null) return false;
    return adminEmails.contains(email.toLowerCase());
  }
}