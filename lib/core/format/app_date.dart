import 'package:intl/intl.dart';

abstract final class AppDate {
  static const String _locale = 'id_ID';

  static String apiDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  static String apiAwalBulan(DateTime bulan) =>
      apiDate(DateTime(bulan.year, bulan.month, 1));

  static String apiAkhirBulan(DateTime bulan) =>
      apiDate(DateTime(bulan.year, bulan.month + 1, 0));

  static String tanggalSingkat(DateTime d) => _f('dd MMM yyyy', d);

  static String tanggalSingkatJam(DateTime d) => _f('dd MMM yyyy, HH:mm', d);

  static String tanggalPanjang(DateTime d) => _f('d MMMM yyyy', d);

  static String tanggalPenuh(DateTime d) => _f('EEEE, dd MMMM yyyy', d);

  static String tanggalPenuhJam(DateTime d) => _f('EEEE, dd MMMM yyyy · HH:mm', d);

  static String hariTanggal(DateTime d) => _f('EEEE, d MMMM', d);

  static String jam(DateTime d) => _f('HH:mm', d);

  static String jamWib(DateTime d) => '${_f('HH.mm', d)} WIB';

  static String bulanTahun(DateTime d) => _f('MMMM yyyy', d);

  static String bulanSingkat(DateTime d) => _f('MMM', d);

  static String namaHari(DateTime d) => _f('EEEE', d);

  static const List<String> labelHariSingkat = [
    'Sen',
    'Sel',
    'Rab',
    'Kam',
    'Jum',
    'Sab',
    'Min',
  ];

  static String labelRelatif(DateTime d) {
    final sekarang = DateTime.now();
    final hariIni = DateTime(sekarang.year, sekarang.month, sekarang.day);
    final target = DateTime(d.year, d.month, d.day);
    final selisih = hariIni.difference(target).inDays;
    if (selisih == 0) return 'Hari ini';
    if (selisih == 1) return 'Kemarin';
    return tanggalPanjang(d);
  }

  static String rentangJam(String mulai, String selesai) =>
      '${jamDariString(mulai)} - ${jamDariString(selesai)}';

  static String jamDariString(String jam) =>
      jam.length >= 5 ? jam.substring(0, 5) : jam;

  static String _f(String pola, DateTime d) => DateFormat(pola, _locale).format(d);
}
