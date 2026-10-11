import 'package:enviroo/screens/lihat_foto_screen.dart';
import 'package:flutter/material.dart';

class FotoThumbnail extends StatelessWidget {
  final String photoUrl;

  final String nama;

  final IconData fallbackIcon;

  final Color accent;

  final double size;

  const FotoThumbnail({
    super.key,
    required this.photoUrl,
    required this.nama,
    required this.fallbackIcon,
    required this.accent,
    this.size = 44,
  });

  bool get _adaFoto => photoUrl.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(
      fallbackIcon,
      color: accent.withValues(alpha: 0.4),
      size: size / 2,
    );

    return GestureDetector(
      onTap: _adaFoto
          ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      LihatFotoScreen(photoUrl: photoUrl, nama: nama),
                ),
              )
          : null,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFFF2F2F2),
              ),
              clipBehavior: Clip.antiAlias,
              child: _adaFoto
                  ? Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => fallback,
                    )
                  : fallback,
            ),

            if (_adaFoto)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Color(0x8C000000),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(6),
                      bottomRight: Radius.circular(11),
                    ),
                  ),
                  child: const Icon(
                    Icons.zoom_out_map_rounded,
                    size: 9,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
