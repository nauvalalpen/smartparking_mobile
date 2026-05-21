import 'package:flutter/material.dart';
import '../services/alert_manager.dart';

class AlertScreen extends StatefulWidget {
  const AlertScreen({super.key});

  @override
  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: AlertManager.alerts.isEmpty
          ? const Center(child: Text("Belum ada peringatan."))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: AlertManager.alerts.length,
              itemBuilder: (context, index) {
                return Card(
                  color: Colors.red.shade50,
                  child: ListTile(
                    leading: Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red.shade700,
                      size: 40,
                    ),
                    title: const Text(
                      "Kapasitas Penuh!",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(AlertManager.alerts[index]),
                  ),
                );
              },
            ),
    );
  }
}
