import 'package:enviroo/core/format/app_date.dart';
import 'package:enviroo/screens/lihat_foto_screen.dart';
import 'package:enviroo/services/konten_service.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:enviroo/models/konten_model.dart';
import 'package:enviroo/widgets/editor_js_renderer.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';

class InformasiScreen extends StatefulWidget {
  final String kontenId;

  const InformasiScreen({Key? key, required this.kontenId}) : super(key: key);

  @override
  State<InformasiScreen> createState() => _InformasiScreenState();
}

class _InformasiScreenState extends State<InformasiScreen> {
  KontenModel? _konten;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchKonten();
  }

  Future<void> _fetchKonten() async {
    final res = await KontenService.getKontenDetail(widget.kontenId);
    if (!mounted) return;
    if (res['success'] == true) {
      setState(() {
        _konten = KontenModel.fromJson(res['data'] as Map<String, dynamic>);
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = res['message'] ?? 'Gagal memuat informasi';
        _isLoading = false;
      });
    }
  }

  void _openFoto(String url, String nama) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LihatFotoScreen(photoUrl: url, nama: nama),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return AppDate.tanggalPenuh(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              const TopBarBack(title: "Informasi"),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.green),
                      )
                    : _error != null
                        ? Center(
                            child: Text(
                              _error!,
                              style: AppText.r(13, AppColors.dark),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : SingleChildScrollView(
                            child: _buildInformasiSection(_konten!),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInformasiSection(KontenModel konten) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Text(
            konten.judul,
            style: AppText.p(18, weight: FontWeight.w700, color: AppColors.dark, height: 1.3),
          ),

          if (konten.deskripsi.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              konten.deskripsi,
              style: AppText.p(13, weight: FontWeight.w400, color: Color(0xFF5A7A6A), height: 1.5),
            ),
          ],

          const SizedBox(height: 20),
          GestureDetector(
            onTap: konten.thumbnail.isNotEmpty
                ? () => _openFoto(konten.thumbnail, konten.judul)
                : null,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                height: 200,
                color: AppColors.neon.withValues(alpha: 0.12),
                child: konten.thumbnail.isNotEmpty
                    ? Image.network(
                        konten.thumbnail,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholderIcon(),
                      )
                    : _buildPlaceholderIcon(),
              ),
            ),
          ),

          const SizedBox(height: 20),
          EditorJsRenderer(
            jsonString: konten.body,
            onImageTap: (url) => _openFoto(url, konten.judul),
          ),

          const SizedBox(height: 16),
          const Divider(color: Color(0xFFE0EDE6), thickness: 1),
          const SizedBox(height: 10),
          if (konten.nama_instansi.isNotEmpty)
            _footerRow(Icons.account_balance_outlined, konten.nama_instansi, color : AppColors.green),
          if (konten.namaAdmin.isNotEmpty) ...[
            const SizedBox(height: 4),
            _footerRow(Icons.person_outline_rounded, 'dibuat oleh ${konten.namaAdmin}', color: Color(0xFF7A9E8A), italic: true),
          ],
          const SizedBox(height: 4),
          _footerRow(Icons.calendar_today_outlined, _formatDate(konten.createdAt)),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _footerRow(IconData icon, String text, {Color color = const Color(0xFF7A9E8A), bool italic = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 6),
        Text(
          text,
          style: AppText.p(11, color: color, fontStyle: italic ? FontStyle.italic : FontStyle.normal),
        ),
      ],
    );
  }

  Widget _buildPlaceholderIcon() {
    return Icon(
      Icons.image_outlined,
      size: 48,
      color: AppColors.neon.withValues(alpha: 0.4),
    );
  }
}
