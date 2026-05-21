import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import '../services/api_service.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : stats.isEmpty
          ? const Center(child: Text("Belum ada data statistik."))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Statistik 7 Hari Terakhir",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 4),
                      const Text("Masuk", style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 16),
                      Container(
                        width: 12,
                        height: 12,
                        color: Colors.red.shade700,
                      ),
                      const SizedBox(width: 4),
                      const Text("Keluar", style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Expanded(
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maxValue == 20
                            ? 100
                            : maxValue, // Fallback jika data 0
                        barGroups: stats.asMap().entries.map((entry) {
                          int index = entry.key;
                          var data = entry.value;
                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: data['kendaraan_masuk'].toDouble(),
                                color: Colors.blue.shade700,
                                width: 14,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              BarChartRodData(
                                toY: data['kendaraan_keluar'].toDouble(),
                                color: Colors.red.shade700,
                                width: 14,
                                borderRadius: BorderRadius.circular(2),
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
                                  // Ambil Tgl & Bulan (Misal: "11 May")
                                  List<String> dateParts = stats[i]['tanggal']
                                      .split('-');
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      "${dateParts[2]}/${dateParts[1]}",
                                      style: const TextStyle(fontSize: 10),
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
                              reservedSize: 40,
                              interval: (maxValue / 5)
                                  .ceilToDouble(), // Interval dinamis agar rapi
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
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
