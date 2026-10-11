import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';

class EditorJsRenderer extends StatelessWidget {
  final String jsonString;
  final void Function(String url)? onImageTap;

  const EditorJsRenderer({Key? key, required this.jsonString, this.onImageTap}) : super(key: key);

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
      return _buildPlainTextFallback(jsonString);
    }
  }

  Widget _buildPlainTextFallback(String text) {
    return Text(
      text,
      style: AppText.p(12, color: AppColors.dark, height: 1.6),
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
          child: url.isEmpty
              ? const SizedBox.shrink()
              : GestureDetector(
                  onTap: onImageTap != null ? () => onImageTap!(url) : null,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.image_not_supported, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  String _stripHtml(String htmlString) {
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return htmlString.replaceAll(exp, '').replaceAll('&nbsp;', ' ');
  }

  Widget _renderHtmlText(String htmlString) {
    if (!htmlString.contains('<')) {
      return Text(
        _stripHtml(htmlString),
        style: AppText.p(12, color: AppColors.dark, height: 1.6),
        textAlign: TextAlign.justify,
      );
    }
    
    return Text(
      _stripHtml(htmlString),
      style: AppText.p(12, color: AppColors.dark, height: 1.6),
      textAlign: TextAlign.justify,
    );
  }
}
