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

  Map<String, String> cameraNamesMap = {};
  List<String> listKameraIds = [];
  String? selectedKameraId;

  Timer? _timer;
  bool isAlertTriggered = false;

  // VARIABEL UNTUK AUTO-DETECT RESOLUSI
  double currentWebWidth =
      1280.0; // Angka sementara, akan di-overwrite otomatis
  double currentWebHeight = 720.0;
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

  // === FUNGSI SAKTI: MENDETEKSI RESOLUSI GAMBAR ASLI DARI SERVER ===
  void _updateImageResolution(String url) {
    if (url == lastLoadedImageUrl)
      return; // Mencegah proses deteksi berulang kali

    final ImageProvider imageProvider = NetworkImage(url);
    imageProvider
        .resolve(const ImageConfiguration())
        .addListener(
          ImageStreamListener((ImageInfo info, bool _) {
            if (mounted) {
              setState(() {
                // Mengambil Width dan Height ASLI dari gambar CCTV
                currentWebWidth = info.image.width.toDouble();
                currentWebHeight = info.image.height.toDouble();
                lastLoadedImageUrl = url;
                print(
                  "RESOLUSI TERDETEKSI: $currentWebWidth x $currentWebHeight",
                );
              });
            }
          }),
        );
  }

  Future<void> _fetchData() async {
    final data = await ApiService.getPublicSlots();
    if (data != null && data['status'] == 'success') {
      List<dynamic> slots = data['data'];

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

    // Panggil Auto-Detect Resolusi
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
                  // MENGHITUNG RASIO DARI RESOLUSI ASLI GAMBAR
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
                            fit: BoxFit.fill,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade800,
                                child: const Center(
                                  child: Text(
                                    "Menunggu Feed Kamera...",
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                ),
                              );
                            },
                          ),

                          // Kanvas Poligon (Langsung menggunakan resolusi asli gambar)
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
    // Jika data belum lengkap, batalkan menggambar agar tidak error
    if (webWidth == 0 || webHeight == 0) return;

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
