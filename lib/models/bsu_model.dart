class BsuModel {
  final String nama;
  final String alamat;
  final String fotoUrl;
  final double latitude;
  final double longitude;
  final List<Map<String, String>> jadwalPenimbangan;

  const BsuModel({
    required this.nama,
    required this.alamat,
    required this.fotoUrl,
    required this.latitude,
    required this.longitude,
    required this.jadwalPenimbangan,
  });
}

List<BsuModel> getDummyBsuData() {
  return [
    BsuModel(
      nama: 'BSU Mawar Indah',
      alamat: 'Jl. Kenanga No. 15, RT 05/RW 02, Padang',
      fotoUrl: 'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?w=400',
      latitude: -0.9135,
      longitude: 100.3530,
      jadwalPenimbangan: [
        {'hari': 'Senin', 'jam': '08:00 - 12:00'},
        {'hari': 'Rabu', 'jam': '08:00 - 12:00'},
        {'hari': 'Sabtu', 'jam': '08:00 - 14:00'},
      ],
    ),
    BsuModel(
      nama: 'BSU Melati Sejahtera',
      alamat: 'Jl. Anggrek No. 8, Limau Manis, Padang',
      fotoUrl: 'https://images.unsplash.com/photo-1562077981-4d7eafd44932?w=400',
      latitude: -0.9180,
      longitude: 100.3600,
      jadwalPenimbangan: [
        {'hari': 'Selasa', 'jam': '09:00 - 13:00'},
        {'hari': 'Kamis', 'jam': '09:00 - 13:00'},
      ],
    ),
    BsuModel(
      nama: 'BSU Cempaka Lestari',
      alamat: 'Jl. Dahlia No. 22, Air Tawar, Padang',
      fotoUrl: 'https://images.unsplash.com/photo-1605600659908-0ef719419d41?w=400',
      latitude: -0.9050,
      longitude: 100.3480,
      jadwalPenimbangan: [
        {'hari': 'Senin', 'jam': '07:30 - 11:30'},
        {'hari': 'Jumat', 'jam': '08:00 - 12:00'},
        {'hari': 'Sabtu', 'jam': '09:00 - 13:00'},
      ],
    ),
    BsuModel(
      nama: 'BSU Anggrek Bersih',
      alamat: 'Jl. Flamboyan No. 5, Pauh, Padang',
      fotoUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=400',
      latitude: -0.9220,
      longitude: 100.3650,
      jadwalPenimbangan: [
        {'hari': 'Rabu', 'jam': '08:00 - 12:00'},
        {'hari': 'Sabtu', 'jam': '08:00 - 14:00'},
      ],
    ),
    BsuModel(
      nama: 'BSU Fakultas Teknologi Informasi',
      alamat: 'Gedung Fasilkom-TI, Kampus Unand Limau Manis',
      fotoUrl: 'https://images.unsplash.com/photo-1571902943202-507ec2618e8f?w=400',
      latitude: -0.9145,
      longitude: 100.3560,
      jadwalPenimbangan: [
        {'hari': 'Selasa', 'jam': '10:00 - 14:00'},
        {'hari': 'Kamis', 'jam': '10:00 - 14:00'},
        {'hari': 'Sabtu', 'jam': '09:00 - 12:00'},
      ],
    ),
  ];
}
