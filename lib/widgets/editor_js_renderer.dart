import 'dart:convert';
import 'package:flutter/material.dart';

class EditorJsRenderer extends StatelessWidget {
  final String jsonString;

  const EditorJsRenderer({Key? key, required this.jsonString}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (jsonString.isEmpty) return const SizedBox.shrink();

    try {
      final dynamic decoded = jsonDecode(jsonString);
      
      if (decoded is! List) {
        return _buildPlainTextFallback(jsonString);
      }
      
      final List<dynamic> blocks = decoded;

      if (blocks.isEmpty) {
        return _buildPlainTextFallback(jsonString);
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: blocks.map((block) {
          if (block is Map<String, dynamic>) {
            return _renderBlock(block);
          }
          return const SizedBox.shrink();
        }).toList(),
      );
    } catch (e) {
      // Return original string if it is not valid JSON
      return _buildPlainTextFallback(jsonString);
    }
  }

  Widget _buildPlainTextFallback(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 12,
        height: 1.6,
        color: Color(0xFF013236),
      ),
      textAlign: TextAlign.justify,
    );
  }

  Widget _renderBlock(Map<String, dynamic> block) {
    final String type = block['type'] ?? '';

    switch (type) {
      case 'text':
      case 'paragraph':
        final String textContent = block['content'] ?? block['text'] ?? '';
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: _renderHtmlText(textContent),
        );
      
      case 'image':
        final String url = block['media_url'] ?? block['url'] ?? '';
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (url.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.image_not_supported, color: Colors.grey),
                    ),
                  ),
                ),
            ],
          ),
        );

      default:
        // Ignore unknown blocks
        return const SizedBox.shrink();
    }
  }

  // Sangat sederhana untuk strip common html tags seperti <b>, <i> dari editor js
  String _stripHtml(String htmlString) {
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return htmlString.replaceAll(exp, '').replaceAll('&nbsp;', ' ');
  }

  // Tries to render basic bold/italic using regex
  Widget _renderHtmlText(String htmlString) {
    if (!htmlString.contains('<')) {
      return Text(
        _stripHtml(htmlString),
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          height: 1.6,
          color: Color(0xFF013236),
        ),
        textAlign: TextAlign.justify,
      );
    }
    
    // For complete HTML parsing we would need flutter_html, 
    // but building a simple striped fallback for now.
    return Text(
      _stripHtml(htmlString),
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 12,
        height: 1.6,
        color: Color(0xFF013236),
      ),
      textAlign: TextAlign.justify,
    );
  }
}
