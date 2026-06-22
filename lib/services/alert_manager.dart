import 'package:shared_preferences/shared_preferences.dart';

class AlertManager {
  static List<String> alerts = [];

  // 1. Fungsi untuk Memuat Alert dari Memori HP (Panggil saat aplikasi dibuka)
  static Future<void> loadAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    alerts = prefs.getStringList('saved_alerts') ?? [];
  }

  // 2. Fungsi untuk Menambah Alert & Menyimpannya
  static Future<void> addAlert(String message) async {
    String time =
        "${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}";
    String fullMessage = "[$time] $message";

    // Cek agar tidak spam pesan yang sama di menit yang sama
    if (alerts.isEmpty || !alerts.first.contains(message)) {
      alerts.insert(0, fullMessage); // Masukkan ke urutan paling atas

      // Batasi maksimal 50 notifikasi saja agar memori HP tidak penuh
      if (alerts.length > 50) {
        alerts.removeLast();
      }

      // Simpan perubahan ke Memori Internal HP
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('saved_alerts', alerts);
    }
  }

  // 3. (Opsional) Fungsi untuk Menghapus Semua Alert
  static Future<void> clearAlerts() async {
    alerts.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_alerts');
  }
}
