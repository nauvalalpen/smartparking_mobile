import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Ganti dengan IP WiFi Anda jika pakai HP Fisik. 10.0.2.2 khusus Emulator Android.
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  // Fungsi Login Petugas (Mesimulasikan Login & Simpan Sesi)
  static Future<bool> login(String email, String password) async {
    // Catatan: Di project Laravel kita belum membuat endpoint POST /login khusus API token.
    // Untuk efisiensi frontend saat ini, kita simulasikan bypass pengecekan email khusus petugas.
    // Jika Anda ingin hit API asli, gunakan http.post ke endpoint auth Laravel Anda.

    if (email.isNotEmpty && password.isNotEmpty) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', 'dummy_token_123'); // Simpan token sesi
      await prefs.setString('role', 'petugas');
      return true;
    }
    return false;
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
