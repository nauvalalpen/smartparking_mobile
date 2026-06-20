import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Ganti dengan IP WiFi Anda jika pakai HP Fisik. 10.0.2.2 khusus Emulator Android.
  static const String baseUrl =
      'http://10.0.2.2/smartparking-backend/public/api';

  // Fungsi Login Petugas
  static Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/v1/auth/login'),
        body: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Simpan data user ke sesi HP
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', 'active_session');
        await prefs.setString('nama', data['data']['nama_lengkap']);
        await prefs.setString('email', data['data']['email']);
        await prefs.setString('role', data['data']['role']);
        return true;
      }
    } catch (e) {
      print('Login Error: $e');
    }
    return false; // Login gagal
  }

  // Fungsi Tarik Data Slot (Public)
  static Future<Map<String, dynamic>?> getPublicSlots() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/public/slots'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error Fetching Data: $e');
    }
    return null;
  }

  // Tambahkan fungsi ini di dalam class ApiService
  static Future<List<dynamic>?> getTrafficStats() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/traffic/stats'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
    } catch (e) {
      print('Error Fetching Stats: $e');
    }
    return null;
  }

  // Fungsi Logout
  static Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
