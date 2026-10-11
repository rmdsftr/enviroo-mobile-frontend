import 'package:enviroo/models/konten_model.dart';
import 'package:enviroo/providers/konten_provider.dart';
import 'package:enviroo/screens/informasi_screen.dart';
import 'package:enviroo/screens/list_informasi_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:enviroo/core/theme/app_colors.dart';
import 'package:enviroo/core/theme/app_text.dart';

class InformasiSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<KontenProvider>(
      builder: (context, konten, _) {
        final kontenList = konten.kontenList;

        if (konten.isLoading && kontenList.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(30),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (kontenList.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 13),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Informasi",
                      style: AppText.w600(15),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ListInformasiScreen()),
                      ),
                      child: Text(
                        "Lihat Semua",
                        style: AppText.w500(12, AppColors.dark),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                height: 195,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: kontenList.length,
                  itemBuilder: (context, index) {
                    final item = kontenList[index];
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => InformasiScreen(kontenId: item.kontenId),
                        ),
                      ),
                      child: _buildInfoCard(item),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(KontenModel info) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              height: 100,
              width: double.infinity,
              color: AppColors.green.withValues(alpha: 0.1),
              child: info.thumbnail.isNotEmpty
                  ? Image.network(
                      info.thumbnail,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info.judul,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.p(11, weight: FontWeight.w600, color: AppColors.dark, height: 1.3),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    info.deskripsi,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.p(10, color: AppColors.dark.withValues(alpha: 0.45), height: 1.3),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Center(
      child: Icon(
        Icons.image_outlined,
        size: 36,
        color: AppColors.green.withValues(alpha: 0.3),
      ),
    );
  }
}
