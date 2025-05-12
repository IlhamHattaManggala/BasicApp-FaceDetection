import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeController extends GetxController {
  CameraController? cameraController;
  late FaceDetector faceDetector;

  final RxString gesture = 'Lurus'.obs;
  final RxBool isCameraReady = false.obs;
  final RxInt selectedCameraIndex = 0.obs;

  bool isDetecting = false;
  List<CameraDescription> cameras = [];

  @override
  void onInit() {
    super.onInit();
    initCameraAndDetector();
  }

  Future<void> initCameraAndDetector() async {
    await Permission.camera.request();

    cameras = await availableCameras();
    if (cameras.isEmpty) {
      debugPrint("No camera found");
      return;
    }

    // ✅ Pakai kamera belakang secara default
    selectedCameraIndex.value =
        cameras.indexWhere((c) => c.lensDirection == CameraLensDirection.front);
    if (selectedCameraIndex.value == -1) {
      selectedCameraIndex.value = 0; // fallback ke kamera pertama
    }

    await initializeCamera(cameras[selectedCameraIndex.value]);

    // ✅ Gunakan mode akurat
    faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        enableClassification: true,
        enableTracking: true,
      ),
    );
  }

  Future<void> initializeCamera(CameraDescription cameraDescription) async {
    isCameraReady.value = false;

    if (cameraController != null) {
      await cameraController!.dispose();
    }

    cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await cameraController!.initialize();
    isCameraReady.value = true;

    cameraController!.startImageStream((CameraImage image) {
      if (!isDetecting) {
        isDetecting = true;
        detectFace(image);
      }
    });
  }

  void switchCamera() async {
    selectedCameraIndex.value =
        (selectedCameraIndex.value + 1) % cameras.length;
    await initializeCamera(cameras[selectedCameraIndex.value]);
  }

  Future<void> detectFace(CameraImage image) async {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final InputImageRotation rotation =
          _rotationFromSensor(cameraController!.description.sensorOrientation);

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      final faces = await faceDetector.processImage(inputImage);
      debugPrint('Faces detected: ${faces.length}');

      if (faces.isNotEmpty) {
        final face = faces.first;
        final angleY = face.headEulerAngleY ?? 0.0;
        final angleX = face.headEulerAngleX ?? 0.0;
        final angleZ = face.headEulerAngleZ ?? 0.0;

        // ✅ Logging euler angle
        debugPrint('Euler X: $angleX');
        debugPrint('Euler Y: $angleY');
        debugPrint('Euler Z: $angleZ');

        // ✅ Ambang diturunkan agar lebih sensitif
        if (angleY > 5) {
          gesture.value = 'Geleng ke kanan';
        } else if (angleY < -5) {
          gesture.value = 'Geleng ke kiri';
        } else {
          gesture.value = 'Lurus';
        }

        debugPrint('Gesture: ${gesture.value}');
      }

      await Future.delayed(Duration(milliseconds: 200));
    } catch (e) {
      debugPrint('Error detecting face: $e');
    } finally {
      isDetecting = false;
    }
  }

  InputImageRotation _rotationFromSensor(int sensorOrientation) {
    switch (sensorOrientation) {
      case 0:
        return InputImageRotation.rotation0deg;
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  @override
  void onClose() {
    cameraController?.dispose();
    faceDetector.close();
    super.onClose();
  }
}
