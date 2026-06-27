import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Ganti dengan IP WiFi Anda jika pakai HP Fisik. 10.0.2.2 khusus Emulator Android.
  static const String baseUrl =
      'http://10.5.50.2/smartparking-backend/public/api';

  // Timeout standar untuk semua request.
  // Tanpa ini, http.get/post akan menunggu TANPA BATAS WAKTU jika
  // backend tidak menjawab — inilah yang menyebabkan app terasa "hang".
  static const Duration _timeout = Duration(seconds: 8);

  // Fungsi Login Petugas
  static Future<bool> login(String email, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/v1/auth/login'),
            body: {'email': email, 'password': password},
          )
          .timeout(_timeout);

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
    } on TimeoutException catch (e) {
      print('Login Timeout: $e');
    } on SocketException catch (e) {
      print('Login Network Error: $e');
    } catch (e) {
      print('Login Error: $e');
    }
    return false; // Login gagal (termasuk gagal karena timeout/network)
  }

  // Fungsi Tarik Data Slot (Public)
  static Future<Map<String, dynamic>?> getPublicSlots() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/public/slots'))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } on TimeoutException catch (e) {
      print('getPublicSlots Timeout: $e');
    } on SocketException catch (e) {
      print('getPublicSlots Network Error: $e');
    } catch (e) {
      print('Error Fetching Data: $e');
    }
    return null;
  }

  // Tambahkan fungsi ini di dalam class ApiService
  static Future<List<dynamic>?> getTrafficStats() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/traffic/stats'))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
    } on TimeoutException catch (e) {
      print('getTrafficStats Timeout: $e');
    } on SocketException catch (e) {
      print('getTrafficStats Network Error: $e');
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
