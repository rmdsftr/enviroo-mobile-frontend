import 'package:enviroo/screens/lihat_foto_screen.dart';
import 'package:flutter/material.dart';

/// Thumbnail foto persegi yang bisa diketuk untuk membukanya penuh lewat
/// [LihatFotoScreen].
///
/// Dipakai header `DetailSampahSheet` dan `DetailBarangSheet`. Ditaruh di satu
/// tempat supaya perilakunya — termasuk kapan boleh diketuk — tidak diam-diam
/// berbeda di antara kedua sheet itu.
class FotoThumbnail extends StatelessWidget {
  /// Url foto. Kosong berarti tidak ada foto: yang tampil [fallbackIcon], dan
  /// thumbnail-nya tidak bisa diketuk — percuma membuka layar foto kosong.
  final String photoUrl;

  /// Judul yang tampil di layar foto penuh.
  final String nama;

  /// Ikon pengganti saat foto tidak ada atau gagal dimuat.
  final IconData fallbackIcon;

  /// Warna ikon pengganti. Diminta eksplisit karena tiap sheet punya palet
  /// `_C` sendiri.
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

            // Penanda kecil bahwa gambarnya bisa dibuka penuh. Tanpa ini
            // thumbnail 44px tidak memberi isyarat apa pun bahwa ia bisa
            // diketuk, jadi fiturnya ada tapi tidak pernah ketemu.
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
