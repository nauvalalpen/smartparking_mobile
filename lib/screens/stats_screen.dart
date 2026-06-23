import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  List<dynamic> stats = [];
  bool isLoading = true;
  double maxValue = 0; // Untuk tinggi maksimal grafik

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  // ── LOGIC TIDAK DIUBAH — kalkulasi maxValue & sumber data tetap sama ──
  Future<void> _loadStats() async {
    final data = await ApiService.getTrafficStats();
    if (data != null && data.isNotEmpty) {
      // Mencari nilai tertinggi agar grafik dinamis
      double maxMasuk = data
          .map((e) => (e['kendaraan_masuk'] as num).toDouble())
          .reduce((a, b) => a > b ? a : b);
      double maxKeluar = data
          .map((e) => (e['kendaraan_keluar'] as num).toDouble())
          .reduce((a, b) => a > b ? a : b);

      setState(() {
        stats = data;
        maxValue = max(maxMasuk, maxKeluar) + 20; // Tambah ruang 20 di atas
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  // ── Total ringkas untuk header (murni presentasional, dihitung dari data yang sama) ──
  int get _totalMasuk {
    if (stats.isEmpty) return 0;
    return stats.fold<int>(
      0,
      (sum, e) => sum + (e['kendaraan_masuk'] as num).toInt(),
    );
  }

  int get _totalKeluar {
    if (stats.isEmpty) return 0;
    return stats.fold<int>(
      0,
      (sum, e) => sum + (e['kendaraan_keluar'] as num).toInt(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : stats.isEmpty
            ? _buildEmptyState()
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _loadStats,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildSummaryRow(),
                    const SizedBox(height: 20),
                    _buildChartCard(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Statistik", style: AppText.h1),
          SizedBox(height: 4),
          Text("Lalu lintas kendaraan 7 hari terakhir", style: AppText.body),
        ],
      ),
    );
  }

  Widget _buildSummaryRow() {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: "Total Masuk",
            value: _totalMasuk,
            color: AppColors.primary,
            bgColor: AppColors.primarySoft,
            icon: Icons.login_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: "Total Keluar",
            value: _totalKeluar,
            color: AppColors.danger,
            bgColor: AppColors.dangerSoft,
            icon: Icons.logout_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildChartCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadow.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text("Grafik Harian", style: AppText.h2),
              const Spacer(),
              _buildLegendDot(AppColors.primary, "Masuk"),
              const SizedBox(width: 14),
              _buildLegendDot(AppColors.danger, "Keluar"),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 260,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxValue == 20
                    ? 100
                    : maxValue, // Fallback jika data 0 — tidak diubah
                barGroups: stats.asMap().entries.map((entry) {
                  int index = entry.key;
                  var data = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: data['kendaraan_masuk'].toDouble(),
                        color: AppColors.primary,
                        width: 13,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      BarChartRodData(
                        toY: data['kendaraan_keluar'].toDouble(),
                        color: AppColors.danger,
                        width: 13,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        int i = value.toInt();
                        if (i >= 0 && i < stats.length) {
                          // Ambil Tgl & Bulan (Misal: "11/05") — tidak diubah
                          List<String> dateParts = stats[i]['tanggal'].split(
                            '-',
                          );
                          return Padding(
                            padding: const EdgeInsets.only(top: 10.0),
                            child: Text(
                              "${dateParts[2]}/${dateParts[1]}",
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      interval: (maxValue / 5)
                          .ceilToDouble(), // Interval dinamis — tidak diubah
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxValue / 5).ceilToDouble(),
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: AppColors.border, strokeWidth: 1),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.textPrimary,
                    tooltipBorderRadius: BorderRadius.circular(8),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        rod.toY.toInt().toString(),
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: const Icon(
              Icons.bar_chart_rounded,
              size: 44,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            "Belum ada data statistik",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Data akan muncul setelah aktivitas tercatat.",
            style: AppText.body.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Kartu ringkasan total masuk/keluar.
/// Murni presentasional — angka dihitung dari `stats` yang sama, tidak ada fetch baru.
class _SummaryCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final Color bgColor;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadow.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: AppText.body.copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}
