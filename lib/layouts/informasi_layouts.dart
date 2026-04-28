import 'package:enviroo/models/konten_model.dart';
import 'package:enviroo/providers/konten_provider.dart';
import 'package:enviroo/screens/informasi_screen.dart';
import 'package:enviroo/screens/list_informasi_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

        if (kontenList.isEmpty) {
          return const SizedBox.shrink(); // Hide section if no content
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
          child: Column(
            children: [
              // Header dengan "Lihat Semua"
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Informasi",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ListInformasiScreen()));
                    },
                    child: const Text(
                      "Lihat Semua",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF013236),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              // Horizontal scroll cards
              SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: kontenList.length,
                  itemBuilder: (context, index) {
                    final item = kontenList[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => InformasiScreen(konten: item)));
                      },
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
      width: 140,
      margin: const EdgeInsets.only(right: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF013236).withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder or Network Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Container(
              height: 100,
              width: double.infinity,
              color: const Color(0xFF94DF0C).withOpacity(0.15),
              child: info.thumbnail.isNotEmpty
                  ? Image.network(
                      info.thumbnail,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholderIcon(),
                    )
                  : _buildPlaceholderIcon(),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              info.judul,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF013236),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Icon(
      Icons.image_outlined,
      size: 40,
      color: const Color(0xFF94DF0C).withOpacity(0.4),
    );
  }
}
