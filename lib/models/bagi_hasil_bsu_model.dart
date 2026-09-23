class DistribusiSisaBsuItem {
  final String penerimaSisaId;
  final String distribusiId;
  final String bagiHasilId;
  final double nominalDiterima;
  final String satuanNominal;
  final String diantarOleh;
  final DateTime tanggalDistribusi;

  DistribusiSisaBsuItem({
    required this.penerimaSisaId,
    required this.distribusiId,
    required this.bagiHasilId,
    required this.nominalDiterima,
    required this.satuanNominal,
    required this.diantarOleh,
    required this.tanggalDistribusi,
  });

  factory DistribusiSisaBsuItem.fromJson(Map<String, dynamic> j) =>
      DistribusiSisaBsuItem(
        penerimaSisaId: j['penerima_sisa_id'] ?? '',
        distribusiId: j['distribusi_id'] ?? '',
        bagiHasilId: j['bagi_hasil_id'] ?? '',
        nominalDiterima: (j['nominal_diterima'] as num?)?.toDouble() ?? 0.0,
        satuanNominal: j['satuan_nominal'] ?? '',
        diantarOleh: j['diantar_oleh'] ?? '',
        tanggalDistribusi:
            DateTime.tryParse(j['tanggal_distribusi'] ?? '')?.toLocal() ??
                DateTime.now(),
      );
}

class PerhitunganSisaItem {
  final String tabunganId;
  final String namaSampah;
  final double qtyDipakai;
  final String satuan;

  PerhitunganSisaItem({
    required this.tabunganId,
    required this.namaSampah,
    required this.qtyDipakai,
    required this.satuan,
  });

  factory PerhitunganSisaItem.fromJson(Map<String, dynamic> j) =>
      PerhitunganSisaItem(
        tabunganId: j['tabungan_id'] ?? '',
        namaSampah: j['nama_sampah'] ?? '',
        qtyDipakai: (j['qty_dipakai'] as num?)?.toDouble() ?? 0.0,
        satuan: j['satuan'] ?? '',
      );
}

class DistribusiSisaBsuDetail {
  final String penerimaSisaId;
  final String distribusiId;
  final String bagiHasilId;
  final String bankId;
  final String namaBank;
  final double nominalDiterima;
  final double porsi;
  final double transportasi;
  final String satuanNominal;
  final String diantarOleh;
  final DateTime tanggalDistribusi;
  final List<PerhitunganSisaItem> perhitunganSisa;

  DistribusiSisaBsuDetail({
    required this.penerimaSisaId,
    required this.distribusiId,
    required this.bagiHasilId,
    required this.bankId,
    required this.namaBank,
    required this.nominalDiterima,
    required this.porsi,
    required this.transportasi,
    required this.satuanNominal,
    required this.diantarOleh,
    required this.tanggalDistribusi,
    required this.perhitunganSisa,
  });

  factory DistribusiSisaBsuDetail.fromJson(Map<String, dynamic> j) =>
      DistribusiSisaBsuDetail(
        penerimaSisaId: j['penerima_sisa_id'] ?? '',
        distribusiId: j['distribusi_id'] ?? '',
        bagiHasilId: j['bagi_hasil_id'] ?? '',
        bankId: j['bank_id'] ?? '',
        namaBank: j['nama_bank'] ?? '',
        nominalDiterima: (j['nominal_diterima'] as num?)?.toDouble() ?? 0.0,
        porsi: (j['porsi'] as num?)?.toDouble() ?? 0.0,
        transportasi: (j['transportasi'] as num?)?.toDouble() ?? 0.0,
        satuanNominal: j['satuan_nominal'] ?? '',
        diantarOleh: j['diantar_oleh'] ?? '',
        tanggalDistribusi:
            DateTime.tryParse(j['tanggal_distribusi'] ?? '')?.toLocal() ??
                DateTime.now(),
        perhitunganSisa: (j['perhitungan_sisa'] as List? ?? [])
            .map((e) =>
                PerhitunganSisaItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
