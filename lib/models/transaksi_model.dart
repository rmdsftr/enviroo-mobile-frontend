enum NilaiType { uang, poin }

class TransaksiItem {
  final String nama;
  final String jumlah;
  final int nilai;
  final NilaiType nilaiType; // uang atau poin

  TransaksiItem({
    required this.nama,
    required this.jumlah,
    required this.nilai,
    required this.nilaiType,
  });
}

class Transaksi {
  final String id;
  final bool isSuccess;
  final DateTime tanggal;
  final String type; // "setoran" atau "penarikan"
  final String? petugasName;
  final List<TransaksiItem> items;

  Transaksi({
    required this.id,
    required this.isSuccess,
    required this.tanggal,
    required this.type,
    this.petugasName,
    required this.items,
  });

  // Calculate total uang from items with nilaiType = uang
  int get totalUang => items
      .where((item) => item.nilaiType == NilaiType.uang)
      .fold(0, (sum, item) => sum + item.nilai);

  // Calculate total poin from items with nilaiType = poin
  int get totalPoin => items
      .where((item) => item.nilaiType == NilaiType.poin)
      .fold(0, (sum, item) => sum + item.nilai);
}

// Dummy data untuk testing
List<Transaksi> getDummySetoranData() {
  return [
    // Desember 2025
    Transaksi(
      id: '1',
      isSuccess: false,
      tanggal: DateTime(2025, 12, 17, 11, 28),
      type: 'setoran',
      petugasName: null,
      items: [],
    ),
    Transaksi(
      id: '2',
      isSuccess: true,
      tanggal: DateTime(2025, 12, 19, 11, 28),
      type: 'setoran',
      petugasName: 'Ramadhani Safitri',
      items: [
        TransaksiItem(nama: 'Botol aqua', jumlah: '1 kg', nilai: 5000, nilaiType: NilaiType.uang),
        TransaksiItem(nama: 'Kertas telur', jumlah: '25 pcs', nilai: 150, nilaiType: NilaiType.poin),
        TransaksiItem(nama: 'Botol plastik', jumlah: '2 kg', nilai: 10000, nilaiType: NilaiType.uang),
      ],
    ),
    Transaksi(
      id: '3',
      isSuccess: true,
      tanggal: DateTime(2025, 12, 25, 14, 30),
      type: 'setoran',
      petugasName: 'Ahmad Fauzi',
      items: [
        TransaksiItem(nama: 'Kardus', jumlah: '3 kg', nilai: 6000, nilaiType: NilaiType.uang),
        TransaksiItem(nama: 'Kaleng aluminium', jumlah: '10 pcs', nilai: 2500, nilaiType: NilaiType.uang),
        TransaksiItem(nama: 'Styrofoam', jumlah: '500 g', nilai: 50, nilaiType: NilaiType.poin),
      ],
    ),
    Transaksi(
      id: '4',
      isSuccess: false,
      tanggal: DateTime(2025, 12, 28, 9, 15),
      type: 'setoran',
      petugasName: null,
      items: [],
    ),
    
    // Januari 2026
    Transaksi(
      id: '5',
      isSuccess: false,
      tanggal: DateTime(2026, 1, 5, 9, 15),
      type: 'setoran',
      petugasName: null,
      items: [],
    ),
    Transaksi(
      id: '6',
      isSuccess: true,
      tanggal: DateTime(2026, 1, 10, 16, 45),
      type: 'setoran',
      petugasName: 'Siti Aminah',
      items: [
        TransaksiItem(nama: 'Botol kaca', jumlah: '5 pcs', nilai: 7500, nilaiType: NilaiType.uang),
        TransaksiItem(nama: 'Kertas HVS', jumlah: '2 kg', nilai: 4000, nilaiType: NilaiType.uang),
        TransaksiItem(nama: 'Plastik kresek', jumlah: '1.5 kg', nilai: 75, nilaiType: NilaiType.poin),
      ],
    ),
    Transaksi(
      id: '7',
      isSuccess: true,
      tanggal: DateTime(2026, 1, 18, 10, 0),
      type: 'setoran',
      petugasName: 'Budi Santoso',
      items: [
        TransaksiItem(nama: 'Besi tua', jumlah: '2 kg', nilai: 15000, nilaiType: NilaiType.uang),
        TransaksiItem(nama: 'Koran bekas', jumlah: '3 kg', nilai: 150, nilaiType: NilaiType.poin),
      ],
    ),
    Transaksi(
      id: '8',
      isSuccess: false,
      tanggal: DateTime(2026, 1, 22, 14, 20),
      type: 'setoran',
      petugasName: null,
      items: [],
    ),
    
    // Februari 2026
    Transaksi(
      id: '9',
      isSuccess: true,
      tanggal: DateTime(2026, 2, 3, 10, 20),
      type: 'setoran',
      petugasName: 'Budi Santoso',
      items: [
        TransaksiItem(nama: 'Aluminium', jumlah: '500 g', nilai: 5000, nilaiType: NilaiType.uang),
        TransaksiItem(nama: 'Botol plastik', jumlah: '20 pcs', nilai: 100, nilaiType: NilaiType.poin),
      ],
    ),
    Transaksi(
      id: '10',
      isSuccess: true,
      tanggal: DateTime(2026, 2, 5, 11, 30),
      type: 'setoran',
      petugasName: 'Ramadhani Safitri',
      items: [
        TransaksiItem(nama: 'Kardus besar', jumlah: '5 kg', nilai: 12500, nilaiType: NilaiType.uang),
        TransaksiItem(nama: 'Kertas campur', jumlah: '2 kg', nilai: 3000, nilaiType: NilaiType.uang),
        TransaksiItem(nama: 'Galon bekas', jumlah: '2 pcs', nilai: 200, nilaiType: NilaiType.poin),
      ],
    ),
    Transaksi(
      id: '11',
      isSuccess: false,
      tanggal: DateTime(2026, 2, 7, 15, 45),
      type: 'setoran',
      petugasName: null,
      items: [],
    ),
  ];
}

List<Transaksi> getDummyPenarikanData() {
  return [
    // Desember 2025
    Transaksi(
      id: 'p1',
      isSuccess: true,
      tanggal: DateTime(2025, 12, 20, 10, 0),
      type: 'penarikan',
      petugasName: 'Admin BSU',
      items: [],
    ),
    Transaksi(
      id: 'p2',
      isSuccess: false,
      tanggal: DateTime(2025, 12, 27, 14, 30),
      type: 'penarikan',
      petugasName: null,
      items: [],
    ),
    
    // Januari 2026
    Transaksi(
      id: 'p3',
      isSuccess: false,
      tanggal: DateTime(2026, 1, 8, 14, 30),
      type: 'penarikan',
      petugasName: null,
      items: [],
    ),
    Transaksi(
      id: 'p4',
      isSuccess: true,
      tanggal: DateTime(2026, 1, 15, 11, 45),
      type: 'penarikan',
      petugasName: 'Admin BSU',
      items: [],
    ),
    Transaksi(
      id: 'p5',
      isSuccess: true,
      tanggal: DateTime(2026, 1, 25, 9, 30),
      type: 'penarikan',
      petugasName: 'Admin BSU',
      items: [],
    ),
    
    // Februari 2026
    Transaksi(
      id: 'p6',
      isSuccess: true,
      tanggal: DateTime(2026, 2, 1, 9, 0),
      type: 'penarikan',
      petugasName: 'Admin BSU',
      items: [],
    ),
    Transaksi(
      id: 'p7',
      isSuccess: false,
      tanggal: DateTime(2026, 2, 6, 16, 15),
      type: 'penarikan',
      petugasName: null,
      items: [],
    ),
  ];
}

// Helper untuk mendapatkan jumlah penarikan (untuk display)
int getPenarikanAmount(Transaksi transaksi) {
  // Dummy amounts for penarikan
  switch (transaksi.id) {
    case 'p1': return 50000;
    case 'p2': return 25000;
    case 'p3': return 25000;
    case 'p4': return 100000;
    case 'p5': return 75000;
    case 'p6': return 75000;
    case 'p7': return 30000;
    default: return 0;
  }
}
