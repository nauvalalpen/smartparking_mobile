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
  double currentWebWidth = 1280.0;
  double currentWebHeight = 720.0;
  List<dynamic> listDataKamera = [];

  Map<String, String> cameraNamesMap = {};
  List<String> listKameraIds = []; // Dikosongkan di awal
  String? selectedKameraId; // Dibuat nullable

  Timer? _timer;
  bool isAlertTriggered = false;

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
      List<dynamic> kameras = data['kameras'];

      Map<String, String> tempCameraNamesMap = {};
      Set<String> kamIds = {};

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
        listDataKamera = kameras;

        // Otomatis pilih kamera pertama jika belum ada yang dipilih
        if (selectedKameraId == null && listKameraIds.isNotEmpty) {
          selectedKameraId = listKameraIds.first;
        }

        // Filter berdasarkan kamera yang dipilih
        if (selectedKameraId != null) {
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
          String camDisplayName = _getCameraDisplayName(selectedKameraId!);
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
          isAlertTriggered = false;
        }

        var kameraTerpilih = listDataKamera.firstWhere(
          (k) => k['id_kamera'].toString() == selectedKameraId,
          orElse: () => null,
        );

        if (kameraTerpilih != null) {
          // Ambil dari database, jika null pakai default
          currentWebWidth = (kameraTerpilih['resolusi_x'] ?? 1280).toDouble();
          currentWebHeight = (kameraTerpilih['resolusi_y'] ?? 720).toDouble();
        }
      });
    }
  }

  String _getCameraDisplayName(String cameraId) {
    return cameraNamesMap[cameraId] ?? "Kamera $cameraId";
  }

  @override
  Widget build(BuildContext context) {
    String currentCamId = selectedKameraId ?? "1";
    String imageUrl =
        "${ApiService.baseUrl.replaceAll('/api', '')}/snapshots/kamera_$currentCamId.jpg";

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
                  value: listKameraIds.contains(selectedKameraId)
                      ? selectedKameraId
                      : null,
                  isExpanded: true,
                  hint: const Text("Pilih Kamera..."),
                  items: listKameraIds.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(_getCameraDisplayName(value)),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedKameraId = newValue;
                        _fetchData();
                      });
                    }
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
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
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
              color: Colors.black87,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade400, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      // 1. Gambar Asli
                      // 1. Gambar Asli
                      Image.network(
                        imageUrl,
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                        fit: BoxFit.fill,
                        // Menambahkan loading builder agar tidak timeout mendadak
                        loadingBuilder:
                            (
                              BuildContext context,
                              Widget child,
                              ImageChunkEvent? loadingProgress,
                            ) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                        errorBuilder: (context, error, stackTrace) {
                          // Gunakan gambar placeholder yang ukurannya kecil (resolusi di bawah 1MB)
                          return Image.network(
                            'https://via.placeholder.com/1280x720.png?text=Frame+Kamera+Belum+Tersedia',
                            width: constraints.maxWidth,
                            height: constraints.maxHeight,
                            fit: BoxFit.fill,
                          );
                        },
                      ),

                      // 2. Kanvas Poligon
                      CustomPaint(
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                        painter: ParkingPainter(
                          slots: filteredSlotData,
                          webWidth: currentWebWidth, // <-- Sekarang DINAMIS!
                          webHeight: currentWebHeight, // <-- Sekarang DINAMIS!
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class ParkingPainter extends CustomPainter {
  final List<dynamic> slots;
  final double webWidth;
  final double webHeight;

  ParkingPainter({
    required this.slots,
    required this.webWidth,
    required this.webHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double scaleX = size.width / webWidth;
    double scaleY = size.height / webHeight;

    for (var slot in slots) {
      if (slot['koordinat_roi'] == null || slot['koordinat_roi'] == "")
        continue;

      List<dynamic> coords = jsonDecode(slot['koordinat_roi']);
      if (coords.isEmpty) continue;

      Path path = Path();
      path.moveTo(
        coords[0]['x'].toDouble() * scaleX,
        coords[0]['y'].toDouble() * scaleY,
      );
      for (int i = 1; i < coords.length; i++) {
        path.lineTo(
          coords[i]['x'].toDouble() * scaleX,
          coords[i]['y'].toDouble() * scaleY,
        );
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
        Offset(
          (coords[0]['x'].toDouble() * scaleX) + 5,
          (coords[0]['y'].toDouble() * scaleY) + 5,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
