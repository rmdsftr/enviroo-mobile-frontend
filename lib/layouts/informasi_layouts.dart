import 'package:flutter/material.dart';

class InformasiSection extends StatelessWidget {
  // Dummy data untuk informasi
  final List<Map<String, String>> informasiList = [
    {
      'title': 'Cara Memilah Sampah dengan Benar',
      'image': 'assets/images/info1.png',
    },
    {
      'title': 'Tips Daur Ulang Plastik di Rumah',
      'image': 'assets/images/info2.png',
    },
    {
      'title': 'Manfaat Bank Sampah untuk Lingkungan',
      'image': 'assets/images/info3.png',
    },
    {
      'title': 'Jadwal Pengangkutan Sampah Februari',
      'image': 'assets/images/info4.png',
    },
    {
      'title': 'Promo Tukar Poin Minggu Ini',
      'image': 'assets/images/info5.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 30),
      child: Column(
        children: [
          // Header dengan "Lihat Semua"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Informasi",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: () {
                  // TODO: Navigasi ke halaman semua informasi
                },
                child: Text(
                  "Lihat Semua",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF109F87),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 15),
          // Horizontal scroll cards
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: informasiList.length,
              itemBuilder: (context, index) {
                return _buildInfoCard(informasiList[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(Map<String, String> info) {
    return Container(
      width: 140,
      margin: EdgeInsets.only(right: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              height: 100,
              width: double.infinity,
              color: Color(0xFFE8F5E9),
              child: Icon(
                Icons.image,
                size: 40,
                color: Color(0xFF109F87).withOpacity(0.5),
              ),
            ),
          ),
          // Title
          Padding(
            padding: EdgeInsets.all(10),
            child: Text(
              info['title'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
