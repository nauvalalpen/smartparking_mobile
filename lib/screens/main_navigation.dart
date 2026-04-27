import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'map_screen.dart'; // Import halaman peta yang baru dibuat
import '../services/api_service.dart'; // Import service untuk fitur Logout
import 'stats_screen.dart'; // Import halaman statistik yang baru dibuat

class MainNavigation extends StatefulWidget {
  final bool isGuest; // Penanda apakah ini Satpam atau Mahasiswa

  const MainNavigation({super.key, required this.isGuest});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // === DAFTAR HALAMAN (SCREENS) ===
    final List<Widget> screens = [
      // Tab 0: Halaman Peta Parkir Real-Time (Fitur Killer)
      const MapScreen(),
      const StatsScreen(), // Tab 1: Halaman Statistik & Traffic Flow
      // Tab 1: Halaman Grafik Traffic Flow (Sementara placeholder)
      const Center(
        child: Text(
          "Halaman Statistik & Traffic Flow\nAkan Muncul di Sini",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),

      // Tab 2: Halaman Profil & Logout
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.security, size: 100, color: Colors.blue.shade800),
            const SizedBox(height: 16),
            const Text(
              "Profil Petugas Keamanan",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Akses Penuh Sistem Monitoring",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),

            // Tombol Logout
            SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.red.shade600, // Warna merah destruktif
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  // Panggil fungsi logout dari ApiService untuk hapus Sesi
                  await ApiService.logout();

                  if (!context.mounted) return;

                  // Kembali ke halaman Login dan hapus histori halaman
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text(
                  "Logout",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    ];

    // === TAMPILAN UTAMA (SCAFFOLD) ===
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Smart Parking PNP",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
      ),

      body: screens[_currentIndex], // Render halaman sesuai tab yang diklik
      // === BOTTOM NAVIGATION BAR ===
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blue.shade800,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          // LOGIKA KEAMANAN: Cegah Mahasiswa (Guest) membuka tab selain Peta (0)
          if (widget.isGuest && index != 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  "Akses Ditolak: Fitur ini khusus Petugas Keamanan!",
                ),
                backgroundColor: Colors.red.shade600,
                duration: const Duration(seconds: 2),
              ),
            );
            return; // Hentikan proses, jangan pindah tab
          }

          // Jika aman, pindah tab
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
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ],
      ),
    );
  }
}
