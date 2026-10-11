import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:enviroo/widgets/custom_snackbar.dart';
import 'package:flutter/services.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';

class InAppCameraScreen extends StatefulWidget {
  final String? hint;

  const InAppCameraScreen({
    super.key,
    this.hint,
  });

  @override
  State<InAppCameraScreen> createState() => _InAppCameraScreenState();
}

class _InAppCameraScreenState extends State<InAppCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isCapturing = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      ctrl.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() => _errorMsg = 'Tidak ada kamera yang tersedia.');
        return;
      }

      final backCamera = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      _controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      if (!mounted) return;

      setState(() => _isInitialized = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMsg = 'Gagal membuka kamera: ${e.toString()}');
    }
  }

  Future<void> _capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) {
      return;
    }

    setState(() => _isCapturing = true);
    HapticFeedback.mediumImpact();

    try {
      final XFile xFile = await _controller!.takePicture();
      final File fotoFile = File(xFile.path);

      if (!mounted) return;
      Navigator.pop(context, fotoFile);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCapturing = false);
      showCustomSnackBar(context, 'Gagal mengambil foto: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_errorMsg != null)
            _buildError()
          else if (!_isInitialized)
            const Center(
              child: CircularProgressIndicator(color: AppColors.green),
            )
          else
            _buildCameraPreview(),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, null),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha:0.45),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                if (widget.hint != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha:0.45),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.hint!,
                          textAlign: TextAlign.center,
                          style: AppText.r(12, Colors.white),
                        ),
                      ),
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Center(
                    child: GestureDetector(
                      onTap: _isCapturing ? null : _capturePhoto,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: _isCapturing ? 64 : 72,
                        height: _isCapturing ? 64 : 72,
                        decoration: BoxDecoration(
                          color: _isCapturing
                              ? AppColors.green.withValues(alpha:0.6)
                              : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.green,
                            width: 3.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.green.withValues(alpha:0.35),
                              blurRadius: 20,
                              spreadRadius: 4,
                            )
                          ],
                        ),
                        child: _isCapturing
                            ? const Padding(
                                padding: EdgeInsets.all(18),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt_rounded,
                                color: AppColors.dark,
                                size: 28,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    final previewSize = _controller!.value.previewSize;
    if (previewSize == null) return const SizedBox.shrink();

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: previewSize.height,
          height: previewSize.width,
          child: CameraPreview(_controller!),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_rounded,
                color: Colors.white54, size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMsg!,
              textAlign: TextAlign.center,
              style: AppText.r(13, Colors.white70),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text(
                'Kembali',
                style: TextStyle(
                  color: AppColors.green,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
