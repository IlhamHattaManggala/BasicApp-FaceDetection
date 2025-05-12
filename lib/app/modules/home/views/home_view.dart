import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deteksi Gerakan Kepala'),
        centerTitle: true,
      ),
      body: Obx(() {
        if (!controller.isCameraReady.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Stack(
          children: [
            // Kamera Preview
            if (controller.cameraController != null)
              CameraPreview(controller.cameraController!),

            // ✅ Overlay Gambar Wajah Transparan
            Positioned.fill(
              child: IgnorePointer(
                child: Image.asset(
                  'assets/face_guide.png', // Tambahkan gambar ini ke assets
                  fit: BoxFit.contain,
                  color: Colors.white.withOpacity(0.4),
                ),
              ),
            ),

            // ✅ Teks Instruksi
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.only(top: 80),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Posisikan wajah Anda di dalam area',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),

            // ✅ Gesture yang Terdeteksi
            Align(
              alignment: Alignment.bottomCenter,
              child: Obx(() => Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      controller.gesture.value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                  )),
            ),

            // ✅ Tombol Switch Kamera
            Positioned(
              top: 16,
              right: 16,
              child: FloatingActionButton(
                heroTag: "switchCamera",
                onPressed: controller.switchCamera,
                backgroundColor: Colors.white,
                child: const Icon(Icons.cameraswitch, color: Colors.black),
              ),
            ),
          ],
        );
      }),
    );
  }
}
