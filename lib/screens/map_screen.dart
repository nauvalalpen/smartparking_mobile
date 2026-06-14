import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/alert_manager.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  int totalSlot = 0;
  int sisaSlot = 0;
  List<dynamic> allSlotData = [];
  List<dynamic> filteredSlotData = [];

  Map<String, String> cameraNamesMap = {}; // Map untuk id_kamera -> nama_kamera
  List<String> listKameraIds = ["semua"]; // ID Kamera untuk dropdown value
  String selectedKameraId = "semua"; // ID Kamera yang dipilih

  Timer? _timer;
  bool isAlertTriggered = false; // Mencegah spam snackbar

  @override
  void initState() {
    super.initState();
    _fetchData();
    _timer = Timer.periodic(
      const Duration(seconds: 3),
      (timer) => _fetchData(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    final data = await ApiService.getPublicSlots();
    if (data != null && data['status'] == 'success') {
      List<dynamic> slots = data['data'];

      // Ambil daftar Kamera secara dinamis dengan nama camera
      Map<String, String> tempCameraNamesMap = {};
      Set<String> kamIds = {"semua"};

      for (var s in slots) {
        String camId = s['id_kamera'].toString();
        String camName = s['camera'] != null
            ? s['camera']['nama_kamera'] ?? "Kamera $camId"
            : "Kamera $camId";

        tempCameraNamesMap[camId] = camName;
        kamIds.add(camId);
      }

      setState(() {
        cameraNamesMap = tempCameraNamesMap;
        allSlotData = slots;
        listKameraIds = kamIds.toList();

        // Eksekusi Filter
        if (selectedKameraId == "semua") {
          filteredSlotData = allSlotData;
        } else {
          filteredSlotData = allSlotData
              .where((s) => s['id_kamera'].toString() == selectedKameraId)
              .toList();
        }

        totalSlot = filteredSlotData.length;
        sisaSlot = filteredSlotData
            .where((s) => s['status'] == 'kosong')
            .length;

        // LOGIKA SMART ALERT
        if (sisaSlot == 0 && totalSlot > 0) {
          String camDisplayName = _getCameraDisplayName(selectedKameraId);
          AlertManager.addAlert("Area $camDisplayName telah penuh!");
          if (!isAlertTriggered) {
            isAlertTriggered = true;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("ALERT: $camDisplayName Penuh!"),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          isAlertTriggered = false; // Reset jika sudah ada yang kosong
        }
      });
    }
  }

  String _getCameraDisplayName(String cameraId) {
    if (cameraId == "semua") {
      return "Semua Kamera";
    }
    return cameraNamesMap[cameraId] ?? "Kamera $cameraId";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // DROPDOWN FILTER
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
          child: Row(
            children: [
              const Icon(Icons.camera_alt, color: Colors.blue),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButton<String>(
                  value: selectedKameraId,
                  isExpanded: true,
                  items: listKameraIds.map((String camId) {
                    String displayName = _getCameraDisplayName(camId);
                    return DropdownMenuItem<String>(
                      value: camId,
                      child: Text(displayName),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      selectedKameraId = newValue!;
                      _fetchData(); // Panggil ulang untuk re-filter
                    });
                  },
                ),
              ),
            ],
          ),
        ),

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
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade400, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CustomPaint(
                size: Size.infinite,
                painter: ParkingPainter(slots: filteredSlotData),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// === CLASS CUSTOM PAINTER (Tetap sama seperti sebelumnya) ===
class ParkingPainter extends CustomPainter {
  final List<dynamic> slots;
  ParkingPainter({required this.slots});

  @override
  void paint(Canvas canvas, Size size) {
    for (var slot in slots) {
      if (slot['koordinat_roi'] == null || slot['koordinat_roi'] == "")
        continue;

      List<dynamic> coords = jsonDecode(slot['koordinat_roi']);
      if (coords.isEmpty) continue;

      Path path = Path();
      path.moveTo(coords[0]['x'].toDouble(), coords[0]['y'].toDouble());
      for (int i = 1; i < coords.length; i++) {
        path.lineTo(coords[i]['x'].toDouble(), coords[i]['y'].toDouble());
      }
      path.close();

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

      canvas.drawPath(path, paintFill);
      canvas.drawPath(path, paintStroke);

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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
