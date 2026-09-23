import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:screenshot/screenshot.dart';

import '../models/penjualan_model.dart';
import '../screens/penjualan/pdf_bukti_penjualan.dart';

/// Bikin file PDF bukti penjualan dari template yang sama persis dipakai
/// PdfBuktiPenjualanScreen — jadi hasil unduhannya gak akan beda sama preview.
///
/// Caranya: widget [BuktiPenjualanTemplate] dirender di luar layar dengan lebar
/// tetap tapi TINGGI GAK DIBATASI, jadi gambar hasilnya persis setinggi konten
/// aslinya (gak ada spasi kosong, gak kepotong walau isinya panjang). Halaman
/// PDF-nya juga dibikin ngikutin rasio gambar itu — bukan dipaksa masuk A4 —
/// jadi kontennya selalu penuh selebar halaman, gak ada margin kiri-kanan yang
/// nganga gara-gara rasio gambar vs halaman gak nyambung.
class BuktiPenjualanPdfService {
  /// Lebar template pas dirender (logical px). Dipatok biar hasilnya konsisten,
  /// gak ikut-ikutan lebar layar HP yang dipakai.
  static const double _lebarTemplate = 460;

  /// Dinaikin biar teksnya tetap tajam pas di-zoom / dicetak.
  static const double _pixelRatio = 3;

  /// Lebar halaman PDF dipatok selebar A4 (satuan point) — tingginya
  /// menyesuaikan rasio gambar, dihitung di bawah.
  static final double _lebarHalamanPt = PdfPageFormat.a4.width;
  static const double _marginPt = 20;

  static Future<Uint8List> generate(
    DetailPenjualanModel detail, {
    required BuildContext context,
  }) async {
    // Gambar aset harus udah masuk cache dulu — kalau belum, render offscreen-nya
    // keburu jalan sebelum gambarnya siap dan hasilnya jadi kosong.
    await precacheImage(const AssetImage('assets/images/logo-fix.png'), context);
    if (!context.mounted) throw StateError('Halaman keburu ditutup');
    await precacheImage(const AssetImage('assets/images/bg_struk.webp'), context);
    if (!context.mounted) throw StateError('Halaman keburu ditutup');

    // targetSize dikasih tinggi infinity — screenshot cuma nge-render setinggi
    // yang bener-bener dibutuhin kontennya (Column di template-nya udah
    // MainAxisSize.min), bukan dipatok ke satu angka tebakan.
    final gambar = await ScreenshotController.widgetToUiImage(
      MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Theme(
            data: ThemeData(fontFamily: 'Poppins'),
            child: Container(
              width: _lebarTemplate,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/bg_struk.webp'),
                  fit: BoxFit.cover,
                ),
              ),
              child: BuktiPenjualanTemplate(detail: detail),
            ),
          ),
        ),
      ),
      context: context,
      pixelRatio: _pixelRatio,
      targetSize: const Size(_lebarTemplate, double.infinity),
      delay: const Duration(milliseconds: 250),
    );

    final byteData = await gambar.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();
    final rasioTinggiLebar = gambar.height / gambar.width;
    gambar.dispose();

    final dokumen = pw.Document();
    final halaman = pw.MemoryImage(pngBytes);

    // Tinggi halaman ngikutin rasio gambar aslinya, jadi kontennya selalu
    // penuh selebar halaman — panjang atau pendek isinya, gak masalah.
    final tinggiHalamanPt = _lebarHalamanPt * rasioTinggiLebar + (_marginPt * 2);

    dokumen.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(_lebarHalamanPt, tinggiHalamanPt),
        margin: const pw.EdgeInsets.all(_marginPt),
        build: (_) => pw.Image(halaman, fit: pw.BoxFit.fill),
      ),
    );

    return dokumen.save();
  }

  /// Nama file yang diusulkan ke dialog simpan.
  static String namaFile(DetailPenjualanModel detail) =>
      'bukti-penjualan-${detail.penjualanId}.pdf';
}
