import 'package:enviroo/widgets/topbar_back.dart';
import 'package:flutter/material.dart';
import 'package:enviroo/models/konten_model.dart';
import 'package:enviroo/widgets/editor_js_renderer.dart';

class InformasiScreen extends StatelessWidget {
  final KontenModel konten;

  const InformasiScreen({Key? key, required this.konten}) : super(key: key);

  String _formatDate(DateTime date) {
    // Simple format, consider using intl package for complex formatting
    return "${date.day}-${date.month}-${date.year}";
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
                child: SingleChildScrollView(
                  child: _buildInformasiSection(),
                ),
              ),
            ],
          )
        ),
      ),
    );
  }

  Widget _buildInformasiSection(){
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Text(
            konten.judul,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF013236)
            ),
          ),
          const SizedBox(height: 7),
          Text(
            _formatDate(konten.createdAt),
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              color: Color(0xFF4EA771)
            ),
          ),
          const SizedBox(height: 20),
          
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFF94DF0C).withOpacity(0.15),
              ),
              child: konten.thumbnail.isNotEmpty
                  ? Image.network(
                      konten.thumbnail,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholderIcon(),
                    )
                  : _buildPlaceholderIcon(),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Body text rendered via EditorJsRenderer
          EditorJsRenderer(jsonString: konten.body.isNotEmpty ? konten.body : konten.deskripsi),
          const SizedBox(height: 30)
        ],
      ),
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
