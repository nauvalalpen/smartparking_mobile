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
  List<String> listKameraIds = [];
  String? selectedKameraId;

  Timer? _timer;
  bool isAlertTriggered = false;
  String lastLoadedImageUrl = "";

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

  void _updateImageResolution(String url) {
    if (url == lastLoadedImageUrl) return;

    final ImageProvider imageProvider = NetworkImage(url);
    imageProvider
        .resolve(const ImageConfiguration())
        .addListener(
          ImageStreamListener((ImageInfo info, bool _) {
            if (mounted) {
              setState(() {
                currentWebWidth = info.image.width.toDouble();
                currentWebHeight = info.image.height.toDouble();
                lastLoadedImageUrl = url;
              });
            }
          }),
        );
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

        if (selectedKameraId == null && listKameraIds.isNotEmpty) {
          selectedKameraId = listKameraIds.first;
        }

        if (selectedKameraId != null) {
          filteredSlotData = allSlotData
              .where((s) => s['id_kamera'].toString() == selectedKameraId)
              .toList();
        }

        totalSlot = filteredSlotData.length;
        sisaSlot = filteredSlotData
            .where((s) => s['status'] == 'kosong')
            .length;

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

    _updateImageResolution(imageUrl);

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

        // 🌟 FITUR BARU: CANVAS PETA DENGAN ZOOM & TANPA BLACK BORDER
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade200, // Warna soft pengganti hitam
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              // 🌟 INTERACTIVE VIEWER UNTUK PINCH-TO-ZOOM
              child: InteractiveViewer(
                panEnabled: true, // Bisa digeser
                scaleEnabled: true, // Bisa di-zoom
                minScale: 1.0,
                maxScale: 4.0, // Maksimal zoom 4x
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    double imageRatio = currentWebWidth / currentWebHeight;

                    return Center(
                      child: AspectRatio(
                        aspectRatio: imageRatio,
                        child: Stack(
                          children: [
                            Image.network(
                              imageUrl,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit
                                  .cover, // Cover agar lebih penuh jika di-zoom
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(
                                    Icons.videocam_off,
                                    color: Colors.grey,
                                    size: 50,
                                  ),
                                );
                              },
                            ),

                            CustomPaint(
                              size: Size.infinite,
                              painter: ParkingPainter(
                                slots: filteredSlotData,
                                webWidth: currentWebWidth,
                                webHeight: currentWebHeight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// === CLASS CUSTOM PAINTER BARU ===
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
    if (webWidth == 0 || webHeight == 0) return;

    double scaleX = size.width / webWidth;
    double scaleY = size.height / webHeight;

    for (var slot in slots) {
      if (slot['koordinat_roi'] == null || slot['koordinat_roi'] == "")
        continue;

      List<dynamic> coords = jsonDecode(slot['koordinat_roi']);
      if (coords.isEmpty) continue;

      Path path = Path();

      // Variabel untuk menghitung titik tengah (Centroid)
      double sumX = 0;
      double sumY = 0;

      path.moveTo(
        coords[0]['x'].toDouble() * scaleX,
        coords[0]['y'].toDouble() * scaleY,
      );

      for (int i = 0; i < coords.length; i++) {
        double scaledX = coords[i]['x'].toDouble() * scaleX;
        double scaledY = coords[i]['y'].toDouble() * scaleY;

        if (i > 0) path.lineTo(scaledX, scaledY);

        sumX += scaledX;
        sumY += scaledY;
      }
      path.close();

      // 🌟 RUMUS CENTROID: Total X dan Y dibagi jumlah titik
      double centerX = sumX / coords.length;
      double centerY = sumY / coords.length;

      bool isTerisi = slot['status'] == 'terisi';
      Paint paintFill = Paint()
        ..color = isTerisi
            ? Colors.red.withOpacity(0.4)
            : Colors.green.withOpacity(0.4)
        ..style = PaintingStyle.fill;
      Paint paintStroke = Paint()
        ..color = isTerisi ? Colors.red.shade700 : Colors.green.shade700
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;

      canvas.drawPath(path, paintFill);
      canvas.drawPath(path, paintStroke);

      // 🌟 TEKS DI TENGAH POLIGON (Lebih kecil dan pakai shadow agar terbaca)
      TextSpan span = TextSpan(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12, // Font dikecilkan
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(color: Colors.black87, blurRadius: 4),
          ], // Efek bayangan
        ),
        text: slot['nama_slot'],
      );

      TextPainter tp = TextPainter(
        text: span,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      tp.layout();

      // Menempatkan teks persis di tengah poligon dikurangi setengah ukuran teksnya
      tp.paint(
        canvas,
        Offset(centerX - (tp.width / 2), centerY - (tp.height / 2)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
