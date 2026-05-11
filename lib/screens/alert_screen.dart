import 'package:flutter/material.dart';

class AlertScreen extends StatelessWidget {
  const AlertScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Riwayat Peringatan",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Card(
            color: Colors.red.shade50,
            child: ListTile(
              leading: Icon(
                Icons.warning_amber_rounded,
                color: Colors.red.shade700,
                size: 40,
              ),
              title: const Text(
                "Kapasitas Hampir Penuh!",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                "Area Parkiran Rektorat mencapai 95% kapasitas.",
              ),
              trailing: const Text("10:45 AM"),
            ),
          ),
          // Tambahkan riwayat lain di sini jika ada
        ],
      ),
    );
  }
}
