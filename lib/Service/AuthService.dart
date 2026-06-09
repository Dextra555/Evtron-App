import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userPhoneKey = 'user_phone';
  static const String _userTokenKey = 'user_token';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';

  static Future<void> setLoggedIn(bool isLoggedIn, {
    String? phone,
    String? token,
    String? name,
    String? email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, isLoggedIn);
    if (phone != null) {
      await prefs.setString(_userPhoneKey, phone);
    }
    if (token != null) {
      await prefs.setString(_userTokenKey, token);
    }
    if (name != null) {
      await prefs.setString(_userNameKey, name);
    }
    if (email != null) {
      await prefs.setString(_userEmailKey, email);
    }
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  static Future<String?> getUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userPhoneKey);
  }

  static Future<String?> getUserToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userTokenKey);
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  // Logout user
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_userPhoneKey);
    await prefs.remove(_userTokenKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
  }
}