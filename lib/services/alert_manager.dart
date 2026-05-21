class AlertManager {
  static List<String> alerts = [];

  static void addAlert(String message) {
    // Cek agar tidak spam pesan yang sama dalam waktu berdekatan
    String time =
        "${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}";
    String fullMessage = "[$time] $message";

    if (alerts.isEmpty || !alerts.first.contains(message)) {
      alerts.insert(0, fullMessage); // Masukkan ke urutan paling atas
    }
  }
}
