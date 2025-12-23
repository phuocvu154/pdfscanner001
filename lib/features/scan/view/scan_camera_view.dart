import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';

import '../viewmodel/scan_camera_viewmodel.dart';

class ScanCameraView extends StatelessWidget {
  const ScanCameraView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ScanCameraViewModel()..initCamera(),
      child: const _ScanCameraContent(),
    );
  }
}

class _ScanCameraContent extends StatelessWidget {
  const _ScanCameraContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ScanCameraViewModel>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: vm.controller == null || !vm.controller!.value.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                CameraPreview(vm.controller!),

                // 🔹 TOP BAR
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Icon(Icons.flash_off, color: Colors.white),
                      ],
                    ),
                  ),
                ),

                // 🔹 GUIDE TEXT
                Positioned(
                  top: 100,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Please bring the machine into the frame.',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),

                // 🔹 BOTTOM CONTROLS
                Positioned(
                  bottom: 32,
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ScanModeSelector(vm),
                      const SizedBox(height: 20),
                      _CaptureButton(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _ScanModeSelector extends StatelessWidget {
  final ScanCameraViewModel vm;

  const _ScanModeSelector(this.vm);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _item('Passport', ScanMode.passport, vm),
        _item('ID card', ScanMode.idCard, vm),
        _item('Document', ScanMode.document, vm),
      ],
    );
  }

  Widget _item(String text, ScanMode mode, ScanCameraViewModel vm) {
    final selected = vm.mode == mode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        text,
        style: TextStyle(
          color: selected ? Colors.yellow : Colors.white,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}
class _CaptureButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
      ),
      child: const Center(
        child: CircleAvatar(
          radius: 26,
          backgroundColor: Colors.white,
        ),
      ),
    );
  }
}
