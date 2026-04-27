import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  int totalSlot = 0;
  int sisaSlot = 0;
  List<dynamic> slotData = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchData(); // Tarik data pertama kali
    // Auto-Polling: Request API setiap 3 detik (Fitur Real-Time)
    _timer = Timer.periodic(
      const Duration(seconds: 3),
      (timer) => _fetchData(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel(); // Matikan timer jika pindah halaman
    super.dispose();
  }

  Future<void> _fetchData() async {
    final data = await ApiService.getPublicSlots();
    if (data != null && data['status'] == 'success') {
      setState(() {
        totalSlot = data['summary']['total_slot'];
        sisaSlot = data['summary']['sisa_slot'];
        slotData = data['data'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // KARTU INFORMASI SISA PARKIR
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: sisaSlot > 0 ? Colors.green.shade700 : Colors.red.shade700,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
          ),
          child: Column(
            children: [
              const Text(
                "SISA SLOT PARKIR",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "$sisaSlot / $totalSlot",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // CANVAS PETA POLIGON RoI
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade200, // Latar belakang aspal virtual
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade400, width: 2),
            ),
            // Menggunakan CustomPaint untuk menggambar koordinat X,Y dari Database
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CustomPaint(
                size: Size.infinite,
                painter: ParkingPainter(slots: slotData),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// === CLASS CUSTOM PAINTER (SIHIR MENGGAMBAR POLIGON) ===
class ParkingPainter extends CustomPainter {
  final List<dynamic> slots;
  ParkingPainter({required this.slots});

  @override
  void paint(Canvas canvas, Size size) {
    for (var slot in slots) {
      // Decode string JSON koordinat dari Database
      List<dynamic> coords = jsonDecode(slot['koordinat_roi']);

      if (coords.isEmpty) continue;

      Path path = Path();
      // Titik Awal
      path.moveTo(coords[0]['x'].toDouble(), coords[0]['y'].toDouble());
      // Tarik garis ke titik selanjutnya
      for (int i = 1; i < coords.length; i++) {
        path.lineTo(coords[i]['x'].toDouble(), coords[i]['y'].toDouble());
      }
      path.close(); // Tutup poligon

      // Tentukan Warna (Hijau = Kosong, Merah = Terisi)
      bool isTerisi = slot['status'] == 'terisi';
      Paint paintFill = Paint()
        ..color = isTerisi
            ? Colors.red.withOpacity(0.5)
            : Colors.green.withOpacity(0.5)
        ..style = PaintingStyle.fill;

      Paint paintStroke = Paint()
        ..color = isTerisi ? Colors.red.shade800 : Colors.green.shade800
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      // Gambar di Canvas
      canvas.drawPath(path, paintFill);
      canvas.drawPath(path, paintStroke);

      // Gambar Nama Slot di tengah poligon
      TextSpan span = TextSpan(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        text: slot['nama_slot'],
      );
      TextPainter tp = TextPainter(
        text: span,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(
        canvas,
        Offset(coords[0]['x'].toDouble() + 10, coords[0]['y'].toDouble() + 10),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true; // Selalu gambar ulang saat data API berubah
}
