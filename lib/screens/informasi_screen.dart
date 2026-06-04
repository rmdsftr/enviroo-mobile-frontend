import 'package:enviroo/services/konten_service.dart';
import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:enviroo/models/konten_model.dart';
import 'package:enviroo/widgets/editor_js_renderer.dart';

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

  String _formatDate(DateTime date) {
    return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFFFFFFFF),
        child: SafeArea(
          child: Column(
            children: [
              const TopBarBack(title: "Informasi"),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Color(0xFF4EA771)),
                      )
                    : _error != null
                        ? Center(
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                color: Color(0xFF013236),
                              ),
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
          // Judul
          const SizedBox(height: 10),
          Text(
            konten.judul,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF013236),
              height: 1.3,
            ),
          ),

          // Deskripsi
          if (konten.deskripsi.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              konten.deskripsi,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Color(0xFF5A7A6A),
                height: 1.5,
              ),
            ),
          ],

          // Thumbnail
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              height: 200,
              color: const Color(0xFF94DF0C).withValues(alpha: 0.12),
              child: konten.thumbnail.isNotEmpty
                  ? Image.network(
                      konten.thumbnail,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholderIcon(),
                    )
                  : _buildPlaceholderIcon(),
            ),
          ),

          // Body
          const SizedBox(height: 20),
          EditorJsRenderer(jsonString: konten.body),

          // Footer
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFE0EDE6), thickness: 1),
          const SizedBox(height: 10),
          if (konten.nama_instansi.isNotEmpty)
            _footerRow(Icons.account_balance_outlined, konten.nama_instansi, color : Color(0xFF4EA771)),
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
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            color: color,
            fontStyle: italic ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderIcon() {
    return Icon(
      Icons.image_outlined,
      size: 48,
      color: const Color(0xFF94DF0C).withOpacity(0.4),
    );
  }
}
