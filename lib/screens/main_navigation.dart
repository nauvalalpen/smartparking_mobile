import 'package:flutter/material.dart';
import 'map_screen.dart';
import 'stats_screen.dart';
import 'alert_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import '../services/alert_manager.dart';
import '../theme/app_theme.dart';

class MainNavigation extends StatefulWidget {
  final bool isGuest;
  const MainNavigation({super.key, required this.isGuest});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  // URUTAN HALAMAN HARUS SAMA DENGAN URUTAN NAVBAR! (tidak diubah)
  final List<Widget> _screens = [
    const MapScreen(), // Index 0: Peta
    const StatsScreen(), // Index 1: Statistik
    const AlertScreen(), // Index 2: Notifikasi (Alert)
    const ProfileScreen(), // Index 3: Profil
  ];

  static const List<_NavItem> _allNavItems = [
    _NavItem(
      icon: Icons.map_outlined,
      activeIcon: Icons.map_rounded,
      label: "Peta",
    ),
    _NavItem(
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart_rounded,
      label: "Statistik",
    ),
    _NavItem(
      icon: Icons.notifications_none_rounded,
      activeIcon: Icons.notifications_active_rounded,
      label: "Alert",
    ),
    _NavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: "Profil",
    ),
  ];

  /// Indeks tab yang TERLIHAT, sesuai status login.
  /// Guest: hanya index 0 (Peta). Petugas: semua index 0-3.
  /// Ini satu-satunya sumber kebenaran untuk filter tab — dipakai baik
  /// untuk merender bottom nav maupun untuk menerjemahkan posisi tab
  /// yang di-tap kembali ke index asli di `_screens`.
  List<int> get _visibleIndexes =>
      widget.isGuest ? const [0] : const [0, 1, 2, 3];

  @override
  void initState() {
    super.initState();
    // Memuat riwayat notifikasi dari memori internal (logic tidak diubah)
    AlertManager.loadAlerts().then((_) {
      setState(() {}); // Memastikan UI ter-refresh setelah data dimuat
    });
  }

  void _onTap(int realIndex) {
    // Tidak perlu guard guest lagi di sini — tab yang guest tidak boleh
    // akses memang sudah tidak dirender sama sekali di bottom nav.
    setState(() {
      _currentIndex = realIndex;
    });
  }

  /// Mengarahkan guest balik ke LoginScreen.
  /// pushReplacement dipakai (bukan pop) karena LoginScreen sudah
  /// dihapus dari stack sejak _loginAsGuest() dipanggil sebelumnya —
  /// jadi tidak ada halaman utk di-pop, harus dibuat ulang.
  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppRadius.sm - 2),
              ),
              child: const Icon(
                Icons.local_parking_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              "Smart Parking PNP",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (widget.isGuest) _buildGuestBanner(),
          Expanded(
            child:
                _screens[_currentIndex], // Menampilkan halaman sesuai index (tidak diubah)
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Banner "Anda masuk sebagai Tamu" dengan tombol Login ──
  Widget _buildGuestBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.warningSoft,
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppColors.warning,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              "Anda masuk sebagai Tamu",
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.warning,
              ),
            ),
          ),
          TextButton(
            onPressed: _goToLogin,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              "Login →",
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom nav — hanya merender tab yang ada di _visibleIndexes ──
  Widget _buildBottomNav() {
    final visible = _visibleIndexes;

    // Kalau guest dan hanya 1 tab terlihat, tidak perlu nav bar sama sekali —
    // tidak ada gunanya menampilkan nav dengan 1 tombol yang sudah aktif.
    if (visible.length <= 1) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: visible.map((realIndex) {
              final item = _allNavItems[realIndex];
              final isActive = _currentIndex == realIndex;

              return Expanded(
                child: InkWell(
                  onTap: () => _onTap(realIndex),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isActive ? item.activeIcon : item.icon,
                        color: isActive
                            ? AppColors.primary
                            : AppColors.textMuted,
                        size: 23,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isActive
                              ? AppColors.primary
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
