import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';

class LihatFotoScreen extends StatefulWidget {
  final String? photoUrl;
  final File? photoFile;
  final String nama;

  const LihatFotoScreen({
    super.key,
    this.photoUrl,
    this.photoFile,
    required this.nama,
  });

  @override
  State<LihatFotoScreen> createState() => _LihatFotoScreenState();
}

class _LihatFotoScreenState extends State<LihatFotoScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              panEnabled: true,
              scaleEnabled: true,
              minScale: 0.8,
              maxScale: 5.0,
              child: widget.photoFile != null
                  ? Image.file(
                      widget.photoFile!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image_rounded,
                              color: Colors.white54, size: 64),
                          SizedBox(height: 12),
                          Text(
                            'Gagal memuat foto',
                            style: TextStyle(color: Colors.white54, fontFamily: 'Poppins'),
                          ),
                        ],
                      ),
                    )
                  : (widget.photoUrl != null && widget.photoUrl!.isNotEmpty)
                      ? Image.network(
                          widget.photoUrl!,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                color: AppColors.green,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.broken_image_rounded,
                                  color: Colors.white54, size: 64),
                              const SizedBox(height: 12),
                              const Text(
                                'Gagal memuat foto',
                                style: TextStyle(color: Colors.white54, fontFamily: 'Poppins'),
                              ),
                            ],
                          ),
                        )
                      : Image.asset(
                          'assets/images/profile.png',
                          fit: BoxFit.contain,
                        ),
            ),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        widget.nama,
                        style: AppText.w600(15, Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
