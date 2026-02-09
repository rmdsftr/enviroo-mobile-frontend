// Enum untuk status penarikan uang
enum PenarikanUangStatus {
  selesai,
  ditolak,
  menungguPersetujuan,
  dibatalkan,
}

// Enum untuk status penarikan poin
enum PenarikanPoinStatus {
  selesai,
  ditolak,
  menungguPersetujuan,
  menungguPenjemputan,
  dibatalkan,
}

// Model untuk barang sembako yang di-redeem
class SembakoItem {
  final String nama;
  final int qty;
  final int poin;

  SembakoItem({
    required this.nama,
    required this.qty,
    required this.poin,
  });
}

// Model untuk penarikan saldo uang
class PenarikanUang {
  final String id;
  final PenarikanUangStatus status;
  final DateTime tanggalDiajukan;
  final DateTime? tanggalDisetujui;
  final DateTime? tanggalDitolak;
  final DateTime? tanggalDibatalkan;
  final int saldoDicairkan;
  final String metodeTransfer;
  final String? buktiTransfer;
  final String? adminName;
  final String? alasanPenolakan;

  PenarikanUang({
    required this.id,
    required this.status,
    required this.tanggalDiajukan,
    this.tanggalDisetujui,
    this.tanggalDitolak,
    this.tanggalDibatalkan,
    required this.saldoDicairkan,
    required this.metodeTransfer,
    this.buktiTransfer,
    this.adminName,
    this.alasanPenolakan,
  });
}

// Model untuk penarikan saldo poin
class PenarikanPoin {
  final String id;
  final PenarikanPoinStatus status;
  final DateTime tanggalDiajukan;
  final DateTime? tanggalDisetujui;
  final DateTime? tanggalDitolak;
  final DateTime? tanggalDibatalkan;
  final List<SembakoItem> items;
  final String? adminName;
  final String? pesanAdmin;

  PenarikanPoin({
    required this.id,
    required this.status,
    required this.tanggalDiajukan,
    this.tanggalDisetujui,
    this.tanggalDitolak,
    this.tanggalDibatalkan,
    required this.items,
    this.adminName,
    this.pesanAdmin,
  });

  // Getter untuk total poin keseluruhan
  int get totalPoin => items.fold(0, (sum, item) => sum + (item.qty * item.poin));
}

// Dummy data untuk penarikan saldo uang
List<PenarikanUang> getDummyPenarikanUangData() {
  return [
    // Selesai
    PenarikanUang(
      id: 'pu1',
      status: PenarikanUangStatus.selesai,
      tanggalDiajukan: DateTime(2026, 2, 1, 10, 0),
      tanggalDisetujui: DateTime(2026, 2, 2, 14, 30),
      saldoDicairkan: 150000,
      metodeTransfer: 'BCA - 1234567890',
      buktiTransfer: 'assets/images/bukti_transfer.png',
      adminName: 'Admin BSI',
    ),
    PenarikanUang(
      id: 'pu2',
      status: PenarikanUangStatus.selesai,
      tanggalDiajukan: DateTime(2026, 1, 20, 9, 15),
      tanggalDisetujui: DateTime(2026, 1, 21, 11, 0),
      saldoDicairkan: 75000,
      metodeTransfer: 'Mandiri - 0987654321',
      buktiTransfer: 'assets/images/bukti_transfer.png',
      adminName: 'Admin BSI',
    ),
    // Menunggu Persetujuan
    PenarikanUang(
      id: 'pu3',
      status: PenarikanUangStatus.menungguPersetujuan,
      tanggalDiajukan: DateTime(2026, 2, 8, 15, 30),
      saldoDicairkan: 100000,
      metodeTransfer: 'BRI - 1122334455',
    ),
    // Ditolak
    PenarikanUang(
      id: 'pu4',
      status: PenarikanUangStatus.ditolak,
      tanggalDiajukan: DateTime(2026, 1, 15, 8, 0),
      tanggalDitolak: DateTime(2026, 1, 16, 10, 30),
      saldoDicairkan: 200000,
      metodeTransfer: 'BNI - 5566778899',
      adminName: 'Admin BSI',
      alasanPenolakan: 'Saldo tidak mencukupi untuk penarikan. Silakan cek kembali saldo Anda.',
    ),
    // Dibatalkan
    PenarikanUang(
      id: 'pu5',
      status: PenarikanUangStatus.dibatalkan,
      tanggalDiajukan: DateTime(2026, 2, 5, 12, 0),
      tanggalDibatalkan: DateTime(2026, 2, 5, 14, 0),
      saldoDicairkan: 50000,
      metodeTransfer: 'DANA - 081234567890',
    ),
  ];
}

// Dummy data untuk penarikan saldo poin
List<PenarikanPoin> getDummyPenarikanPoinData() {
  return [
    // Selesai (barang sudah dijemput)
    PenarikanPoin(
      id: 'pp1',
      status: PenarikanPoinStatus.selesai,
      tanggalDiajukan: DateTime(2026, 1, 25, 9, 0),
      tanggalDisetujui: DateTime(2026, 1, 26, 10, 0),
      items: [
        SembakoItem(nama: 'Beras 5kg', qty: 1, poin: 500),
        SembakoItem(nama: 'Minyak Goreng 2L', qty: 2, poin: 150),
        SembakoItem(nama: 'Gula Pasir 1kg', qty: 1, poin: 100),
      ],
      adminName: 'Admin BSI',
    ),
    // Menunggu Persetujuan Admin
    PenarikanPoin(
      id: 'pp2',
      status: PenarikanPoinStatus.menungguPersetujuan,
      tanggalDiajukan: DateTime(2026, 2, 8, 11, 30),
      items: [
        SembakoItem(nama: 'Beras 5kg', qty: 2, poin: 500),
        SembakoItem(nama: 'Telur 1 Tray', qty: 1, poin: 200),
      ],
    ),
    // Menunggu Penjemputan
    PenarikanPoin(
      id: 'pp3',
      status: PenarikanPoinStatus.menungguPenjemputan,
      tanggalDiajukan: DateTime(2026, 2, 6, 14, 0),
      tanggalDisetujui: DateTime(2026, 2, 7, 9, 30),
      items: [
        SembakoItem(nama: 'Minyak Goreng 2L', qty: 1, poin: 150),
        SembakoItem(nama: 'Tepung Terigu 1kg', qty: 2, poin: 80),
        SembakoItem(nama: 'Gula Pasir 1kg', qty: 1, poin: 100),
      ],
      adminName: 'Admin BSI',
    ),
    // Ditolak
    PenarikanPoin(
      id: 'pp4',
      status: PenarikanPoinStatus.ditolak,
      tanggalDiajukan: DateTime(2026, 1, 18, 16, 0),
      tanggalDitolak: DateTime(2026, 1, 19, 10, 0),
      items: [
        SembakoItem(nama: 'Beras 10kg', qty: 1, poin: 900),
      ],
      adminName: 'Admin BSI',
      pesanAdmin: 'Poin tidak mencukupi untuk menukar barang ini. Saldo poin Anda: 750',
    ),
    // Dibatalkan
    PenarikanPoin(
      id: 'pp5',
      status: PenarikanPoinStatus.dibatalkan,
      tanggalDiajukan: DateTime(2026, 2, 3, 10, 0),
      tanggalDibatalkan: DateTime(2026, 2, 3, 12, 30),
      items: [
        SembakoItem(nama: 'Gula Pasir 1kg', qty: 2, poin: 100),
        SembakoItem(nama: 'Kecap Manis 500ml', qty: 1, poin: 75),
      ],
    ),
  ];
}
