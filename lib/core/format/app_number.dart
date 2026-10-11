import 'package:intl/intl.dart';

abstract final class AppNumber {
  static const String _locale = 'id_ID';

  static const int presisiSistem = 4;

  static NumberFormat _pola(int maksDesimal) => NumberFormat(
        maksDesimal <= 0 ? '#,##0' : '#,##0.${'#' * maksDesimal}',
        _locale,
      );

  static String rupiah(num v, {int maksDesimal = 0}) =>
      'Rp ${_pola(maksDesimal).format(v)}';

  static String desimal(num v, {int maksDesimal = presisiSistem}) =>
      _pola(maksDesimal).format(v);

  static String denganSatuan(num v, String satuan,
          {int maksDesimal = presisiSistem}) =>
      '${_pola(maksDesimal).format(v)} ${satuan.isEmpty ? 'poin' : satuan}';

  static String persen(num v, {int maksDesimal = presisiSistem}) =>
      '${_pola(maksDesimal).format(v)}%';

  static String nominal(
    num v, {
    required String satuan,
    required bool isUang,
    int maksDesimal = presisiSistem,
  }) =>
      isUang
          ? rupiah(v, maksDesimal: maksDesimal)
          : denganSatuan(v, satuan, maksDesimal: maksDesimal);

  static String nominalSatuan(num v, String satuan,
          {bool? isUang, int maksDesimal = presisiSistem}) =>
      (isUang ?? tampakRupiah(satuan))
          ? rupiah(v)
          : denganSatuan(v, satuan, maksDesimal: maksDesimal);

  static bool tampakRupiah(String satuan) {
    final s = satuan.toLowerCase();
    return s.contains('rp') ||
        s.contains('rupiah') ||
        s.contains('uang') ||
        s.contains('idr');
  }
}
