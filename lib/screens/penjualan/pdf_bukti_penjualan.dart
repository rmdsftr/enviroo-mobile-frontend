import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/penjualan_model.dart';
import '../../providers/penjualan_provider.dart';

// ── Color Palette ─────────────────────────────────────────────────────────────
// Sama persis kayak yang dipakai di DetailPenjualanScreen — biar temanya nyambung.
class _C {
  static const dark = Color(0xFF013236);
  static const green = Color(0xFF4EA771);
  static const danger = Color(0xFFD94848);
}

// ── Skala tipografi ───────────────────────────────────────────────────────────
// Cuma 5 tingkat, dipakai konsisten di seluruh dokumen. Beda antar tingkat
// sengaja lebar biar hierarkinya kebaca (bukan beda 0.5px yang gak ada artinya).
class _T {
  static const title = 16.0;    // judul dokumen
  static const emphasis = 15.0; // satu angka utama: total penjualan
  static const section = 13.0;  // judul section di tiap kartu
  static const value = 12.0;    // isi/value
  static const label = 11.0;    // label kiri
  static const caption = 10.5;  // keterangan pendukung
}

// ── Screen ───────────────────────────────────────────────────────────────────
// Template unduhan bukti penjualan (PDF) buat petugas. Diakses lewat tombol
// "Unduh Bukti Penjualan" di paling bawah DetailPenjualanScreen. Kartu-kartunya
// niru gaya DetailPenjualanScreen (putih rounded, header ikon+judul, divider
// tipis), cuma isinya disusun ulang biar kebaca kayak struk kasir.
// Screen ini murni template tampilannya — gak ada aksi unduh di sini.
class PdfBuktiPenjualanScreen extends StatefulWidget {
  final String penjualanId;

  const PdfBuktiPenjualanScreen({super.key, required this.penjualanId});

  @override
  State<PdfBuktiPenjualanScreen> createState() => _PdfBuktiPenjualanScreenState();
}

class _PdfBuktiPenjualanScreenState extends State<PdfBuktiPenjualanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await context.read<PenjualanProvider>().fetchDetail(widget.penjualanId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg_struk.webp'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Consumer<PenjualanProvider>(
                  builder: (_, prov, __) {
                    if (prov.detailStatus == FetchStatus.loading) {
                      return const Center(
                        child: CircularProgressIndicator(color: _C.green),
                      );
                    }
                    if (prov.detailStatus == FetchStatus.error ||
                        prov.detail == null) {
                      return _buildError(prov.detailError ?? 'Gagal memuat bukti penjualan');
                    }
                    return _buildBody(prov.detail!);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Error State ─────────────────────────────────────────────────────────────
  Widget _buildError(String msg) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 40, color: _C.danger.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              Text(
                msg,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: _C.dark.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _load,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.dark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Coba Lagi', style: TextStyle(fontFamily: 'Poppins')),
              ),
            ],
          ),
        ),
      );

  // ── Main Content ─────────────────────────────────────────────────────────────
  Widget _buildBody(DetailPenjualanModel d) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: BuktiPenjualanTemplate(detail: d),
    );
  }
}

// ─── Template bukti penjualan ─────────────────────────────────────────────────
// Dipakai di dua tempat: preview di screen atas, dan sumber render buat file
// PDF-nya (lihat BuktiPenjualanPdfService). Satu sumber layout, jadi isi PDF
// dijamin sama persis kayak yang keliatan di preview.
class BuktiPenjualanTemplate extends StatelessWidget {
  final DetailPenjualanModel detail;

  const BuktiPenjualanTemplate({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final d = detail;
    final isRupiah = d.satuanReward.toLowerCase() == 'rp';
    final fmtRibuan = NumberFormat('#,##0', 'id_ID');
    final fmtQty = NumberFormat('#,##0.##########', 'id_ID');

    String fmtNominal(double val) =>
        isRupiah ? 'Rp${fmtRibuan.format(val)}' : '${fmtRibuan.format(val)} ${d.satuanReward}';

    final tanggal = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(d.createdAt);
    final jam = DateFormat('HH.mm', 'id_ID').format(d.createdAt);
    final terbilangStr =
        _capitalize('${terbilang(d.totalPenjualan.round())} ${isRupiah ? 'rupiah' : d.satuanReward}');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 30),
      child: Column(
        // Wajib min: pas dirender buat PDF, tingginya dikasih longgar. Kalau
        // max, kolomnya bakal melar ngisi ruang kosong sampai bawah.
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Kop dokumen ─────────────────────────────────────────────────
          _plainCard(
            child: Column(
              children: [
                Image.asset(
                  'assets/images/logo-fix.png',
                  height: 38,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 10),
                Text(
                  'Bukti Penjualan Sampah'.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: _T.title,
                    letterSpacing: 0.4,
                    color: _C.dark,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  d.namaBank,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: _T.value,
                    color: _C.dark.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Informasi penjualan ─────────────────────────────────────────
          _card(
            title: 'Informasi Penjualan',
            children: [
              _kv('ID Penjualan', d.penjualanId),
              _kv('Tanggal Penjualan', '$tanggal $jam WIB'),
              _kv('Mitra Pengepul', d.namaMitra),
              _kv('Jenis Insentif', d.namaReward),
            ],
          ),
          const SizedBox(height: 12),

          // ── Item sampah ─────────────────────────────────────────────────
          _card(
            title: 'Item Sampah Terjual',
            children: [
              if (d.itemsSampah.isEmpty)
                Text(
                  'Tidak ada item sampah.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: _T.value,
                    color: _C.dark.withValues(alpha: 0.4),
                  ),
                )
              else
                ...d.itemsSampah.asMap().entries.map((entry) {
                  final isLast = entry.key == d.itemsSampah.length - 1;
                  final item = entry.value;
                  // Tiap item dibungkus kotaknya sendiri biar jelas beda level
                  // sama judul kartunya.
                  return Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(top: 6, bottom: isLast ? 2 : 0),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: _C.green.withValues(alpha: 0.075),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item.namaSampah,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  fontSize: _T.value,
                                  color: _C.dark,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              fmtNominal(item.subtotalPenjualan),
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                fontSize: _T.value,
                                color: _C.dark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${fmtQty.format(item.qty)} ${item.satuan} x ${fmtNominal(item.hargaJual)}',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: _T.caption,
                            color: _C.dark.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
          const SizedBox(height: 12),

          // ── Ringkasan total ─────────────────────────────────────────────
          _card(
            title: 'Total Penjualan',
            children: [
              _kv(
                'Nominal',
                fmtNominal(d.totalPenjualan),
                valueColor: _C.green,
                valueSize: _T.emphasis,
                valueWeight: FontWeight.w700,
              ),
              _kv('Terbilang', terbilangStr, italic: true),
            ],
          ),
          const SizedBox(height: 12),

          // ── Tanda tangan petugas ────────────────────────────────────────
          // Blok tanda tangan harus kebaca sebagai satu kesatuan, jadi gak
          // pakai anatomi judul+garis kayak kartu section di atas.
          _plainCard(
            child: Align(
              alignment: Alignment.centerRight,
              child: Column(
                children: [
                  Text(
                    'Petugas yang Melayani,',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: _T.label,
                      color: _C.dark.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 46),
                  Text(
                    d.adminName,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: _T.value,
                      color: _C.dark,
                      decoration: TextDecoration.underline,
                      decorationColor: _C.dark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    d.namaBank,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: _T.caption,
                      color: _C.dark.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Cangkang kartu polos: dipakai blok pembingkai (kop & tanda tangan) ─────
  Widget _plainCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          width: 1,
          color: const Color(0xFF013236).withOpacity(0.1), // Brand color dengan opacity cuma 10%
        ),
      ),
      child: child,
    );
  }

  // ── Anatomi kartu section: judul → garis → isi. Dipakai semua kartu data. ──
  Widget _card({required String title, required List<Widget> children}) {
    return _plainCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: _T.section,
              color: _C.dark,
            ),
          ),
          const SizedBox(height: 7),
          Divider(color: _C.dark.withValues(alpha: 0.1), height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _kv(
    String label,
    String value, {
    Color? valueColor,
    double valueSize = _T.value,
    FontWeight valueWeight = FontWeight.w600,
    bool italic = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: _T.label,
                color: _C.dark.withValues(alpha: 0.5),
              ),
            ),
          ),
          Text(
            ': ',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: _T.label,
              color: _C.dark.withValues(alpha: 0.5),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: valueWeight,
                fontStyle: italic ? FontStyle.italic : FontStyle.normal,
                fontSize: valueSize,
                color: valueColor ?? _C.dark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

// ─── Terbilang (angka → kata, Bahasa Indonesia) ─────────────────────────────
String terbilang(int n) {
  if (n == 0) return 'nol';
  if (n < 0) return 'minus ${terbilang(-n)}';

  const satuan = [
    '', 'satu', 'dua', 'tiga', 'empat', 'lima',
    'enam', 'tujuh', 'delapan', 'sembilan', 'sepuluh', 'sebelas',
  ];

  if (n < 12) return satuan[n];
  if (n < 20) return '${terbilang(n - 10)} belas';
  if (n < 100) {
    final sisa = n % 10;
    return '${terbilang(n ~/ 10)} puluh${sisa != 0 ? ' ${terbilang(sisa)}' : ''}';
  }
  if (n < 200) {
    final sisa = n % 100;
    return 'seratus${sisa != 0 ? ' ${terbilang(sisa)}' : ''}';
  }
  if (n < 1000) {
    final sisa = n % 100;
    return '${terbilang(n ~/ 100)} ratus${sisa != 0 ? ' ${terbilang(sisa)}' : ''}';
  }
  if (n < 2000) {
    final sisa = n % 1000;
    return 'seribu${sisa != 0 ? ' ${terbilang(sisa)}' : ''}';
  }
  if (n < 1000000) {
    final sisa = n % 1000;
    return '${terbilang(n ~/ 1000)} ribu${sisa != 0 ? ' ${terbilang(sisa)}' : ''}';
  }
  if (n < 1000000000) {
    final sisa = n % 1000000;
    return '${terbilang(n ~/ 1000000)} juta${sisa != 0 ? ' ${terbilang(sisa)}' : ''}';
  }
  if (n < 1000000000000) {
    final sisa = n % 1000000000;
    return '${terbilang(n ~/ 1000000000)} miliar${sisa != 0 ? ' ${terbilang(sisa)}' : ''}';
  }
  final sisa = n % 1000000000000;
  return '${terbilang(n ~/ 1000000000000)} triliun${sisa != 0 ? ' ${terbilang(sisa)}' : ''}';
}
