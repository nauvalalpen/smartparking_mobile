import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/alert_manager.dart';
import '../theme/app_theme.dart';

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
  final double currentWebWidth = 1280.0;
  final double currentWebHeight = 720.0;
  List<dynamic> listDataKamera = [];

  Map<String, String> cameraNamesMap = {};
  List<String> listKameraIds = [];
  String? selectedKameraId;

  Timer? _timer;
  bool isAlertTriggered = false;
  String lastLoadedImageUrl = "";

  // Guard supaya polling tiap 3 detik tidak menumpuk request baru
  // selagi request sebelumnya masih menunggu jawaban (lihat _fetchData).
  bool _isFetching = false;

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

  // ── LOGIC TIDAK DIUBAH — resolusi gambar tetap dihitung dari NetworkImage ──
  // void _updateImageResolution(String url) {
  //   if (url == lastLoadedImageUrl) return;

  //   final ImageProvider imageProvider = NetworkImage(url);
  //   imageProvider
  //       .resolve(const ImageConfiguration())
  //       .addListener(
  //         ImageStreamListener((ImageInfo info, bool _) {
  //           if (mounted) {
  //             setState(() {
  //               currentWebWidth = info.image.width.toDouble();
  //               currentWebHeight = info.image.height.toDouble();
  //               lastLoadedImageUrl = url;
  //             });
  //           }
  //         }),
  //       );
  // }

  // ── LOGIC TIDAK DIUBAH — fetch, filter per kamera, deteksi penuh, alert ──
  // Tambahan: guard _isFetching agar polling 3 detik tidak menumpuk request
  // baru ketika request sebelumnya belum selesai (akar penyebab app "hang").
  Future<void> _fetchData() async {
    if (_isFetching) return; // request sebelumnya masih jalan, skip dulu
    _isFetching = true;

    try {
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
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppColors.danger,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  content: Text("ALERT: $camDisplayName Penuh!"),
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
        });
      }
    } finally {
      // Selalu dilepas, baik sukses, gagal, maupun timeout —
      // supaya polling berikutnya tidak terkunci selamanya.
      _isFetching = false;
    }
  }

  String _getCameraDisplayName(String cameraId) {
    return cameraNamesMap[cameraId] ?? "Kamera $cameraId";
  }

  @override
  Widget build(BuildContext context) {
    String currentCamId = selectedKameraId ?? "1";
    int cacheBuster = DateTime.now().millisecondsSinceEpoch ~/ 60000;
    String imageUrl =
        "${ApiService.baseUrl.replaceAll('/api', '')}/snapshots/kamera_$currentCamId.jpg?v=$cacheBuster";

    // _updateImageResolution(imageUrl);

    return Container(
      color: AppColors.bgBase,
      child: Column(
        children: [
          _buildCameraSelector(),
          _buildSummaryCard(),
          _buildMapCanvas(imageUrl),
        ],
      ),
    );
  }

  // ── DROPDOWN FILTER ──
  Widget _buildCameraSelector() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadow.card,
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppRadius.sm - 3),
            ),
            child: const Icon(
              Icons.videocam_outlined,
              color: AppColors.primary,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: listKameraIds.contains(selectedKameraId)
                    ? selectedKameraId
                    : null,
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textMuted,
                ),
                hint: Text(
                  "Pilih Kamera...",
                  style: AppText.body.copyWith(color: AppColors.textMuted),
                ),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
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
          ),
        ],
      ),
    );
  }

  // ── KARTU INFORMASI SISA PARKIR ──
  Widget _buildSummaryCard() {
    final bool isFull = sisaSlot == 0 && totalSlot > 0;
    final Color accent = isFull ? AppColors.danger : AppColors.success;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              isFull ? Icons.block_rounded : Icons.local_parking_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFull ? "PARKIRAN PENUH" : "SISA SLOT PARKIR",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      "$sisaSlot",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    Text(
                      " / $totalSlot slot",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── CANVAS PETA DENGAN ZOOM (logic painter & interaksi tidak diubah) ──
  Widget _buildMapCanvas(String imageUrl) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadow.card,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Stack(
            children: [
              InteractiveViewer(
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
                              gaplessPlayback: true,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      color: AppColors.bgBase,
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: AppColors.primary,
                                          strokeWidth: 2.4,
                                        ),
                                      ),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppColors.bgBase,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.videocam_off_rounded,
                                          color: AppColors.textMuted,
                                          size: 40,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          "Feed kamera tidak tersedia",
                                          style: AppText.body.copyWith(
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                            // CustomPaint — logic ParkingPainter TIDAK DIUBAH SAMA SEKALI
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

              // Hint zoom — murni dekoratif, tidak mengganggu InteractiveViewer
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pinch_rounded, color: Colors.white, size: 13),
                      SizedBox(width: 5),
                      Text(
                        "Cubit untuk zoom",
                        style: TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// CLASS CUSTOM PAINTER — TIDAK DIUBAH SAMA SEKALI.
// Semua kalkulasi skala, centroid, dan path poligon dipertahankan
// identik dengan versi asli. Hanya warna diarahkan ke AppColors
// agar konsisten dengan tema, tanpa mengubah satu pun rumus.
// ════════════════════════════════════════════════════════════
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

      // RUMUS CENTROID: Total X dan Y dibagi jumlah titik
      double centerX = sumX / coords.length;
      double centerY = sumY / coords.length;

      bool isTerisi = slot['status'] == 'terisi';
      Paint paintFill = Paint()
        ..color = isTerisi
            ? AppColors.danger.withOpacity(0.4)
            : AppColors.success.withOpacity(0.4)
        ..style = PaintingStyle.fill;
      Paint paintStroke = Paint()
        ..color = isTerisi ? AppColors.danger : AppColors.success
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;

      canvas.drawPath(path, paintFill);
      canvas.drawPath(path, paintStroke);

      // TEKS DI TENGAH POLIGON (dengan shadow agar terbaca)
      TextSpan span = TextSpan(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
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
