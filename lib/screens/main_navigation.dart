import 'package:flutter/material.dart';
import 'map_screen.dart';
import 'stats_screen.dart';
import 'alert_screen.dart';
import 'profile_screen.dart';

class MainNavigation extends StatefulWidget {
  final bool isGuest;
  const MainNavigation({super.key, required this.isGuest});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  // URUTAN HALAMAN HARUS SAMA DENGAN URUTAN NAVBAR!
  final List<Widget> _screens = [
    const MapScreen(), // Index 0: Peta
    const StatsScreen(), // Index 1: Statistik
    const AlertScreen(), // Index 2: Notifikasi (Alert)
    const ProfileScreen(), // Index 3: Profil
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Smart Parking PNP",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade800,
      ),
      body: _screens[_currentIndex], // Menampilkan halaman sesuai index

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blue.shade800,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed, // Penting jika tombol lebih dari 3
        onTap: (index) {
          if (widget.isGuest && index != 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "Akses Ditolak: Fitur ini khusus Petugas Keamanan!",
                ),
              ),
            );
            return;
          }
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: "Peta"),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: "Statistik",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_active),
            label: "Alert",
          ), // TAB BARU
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ],
      ),
    );
  }
}
