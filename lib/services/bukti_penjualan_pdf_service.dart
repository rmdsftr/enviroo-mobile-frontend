import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:screenshot/screenshot.dart';

import '../models/penjualan_model.dart';
import '../screens/penjualan/pdf_bukti_penjualan.dart';

class BuktiPenjualanPdfService {
  static const double _lebarTemplate = 460;

  static const double _pixelRatio = 3;

  static final double _lebarHalamanPt = PdfPageFormat.a4.width;
  static const double _marginPt = 20;

  static Future<Uint8List> generate(
    DetailPenjualanModel detail, {
    required BuildContext context,
  }) async {
    await precacheImage(const AssetImage('assets/images/logo-fix.png'), context);
    if (!context.mounted) throw StateError('Halaman keburu ditutup');
    await precacheImage(const AssetImage('assets/images/bg_struk.webp'), context);
    if (!context.mounted) throw StateError('Halaman keburu ditutup');

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

  static String namaFile(DetailPenjualanModel detail) =>
      'bukti-penjualan-${detail.penjualanId}.pdf';
}
