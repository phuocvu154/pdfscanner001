import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

enum ScanMode { passport, idCard, document }

class ScanCameraViewModel extends ChangeNotifier {
  CameraController? controller;
  ScanMode mode = ScanMode.document;

  Future<void> initCamera() async {
    final cameras = await availableCameras();
    controller = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );
    await controller!.initialize();
    notifyListeners();
  }

  void changeMode(ScanMode newMode) {
    mode = newMode;
    notifyListeners();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
