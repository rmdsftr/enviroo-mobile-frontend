import 'package:flutter/foundation.dart';
import '../models/jadwal_model.dart';
import '../services/jadwal_service.dart';
import '../providers/auth_provider.dart';
import '../screens/admin_bsu/jadwal_screen.dart';

class JadwalProvider with ChangeNotifier {
  List<JadwalModel> _penimbanganList = [];
  List<JadwalModel> _pengangkutanList = [];

  bool _isLoading = false;
  String _error = '';

  List<JadwalModel> get penimbanganList => _penimbanganList;
  List<JadwalModel> get pengangkutanList => _pengangkutanList;
  bool get isLoading => _isLoading;
  String get error => _error;

  Future<void> fetchJadwal(AuthProvider authProvider) async {
    if (authProvider.bankId == null) {
      _error = 'Anda belum login atau bank tidak ditemukan.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await JadwalService.getJadwalByBankId(authProvider.bankId!);
      if (response['success'] == true) {
        final Map<String, dynamic> data = response['data'];
        _penimbanganList = (data['penimbangan'] as List? ?? [])
            .map((json) => JadwalModel.fromJson(json))
            .toList();
        _pengangkutanList = (data['pengangkutan'] as List? ?? [])
            .map((json) => JadwalModel.fromJson(json))
            .toList();

        // BSU hanya perlu lihat jadwal pengangkutan yang menargetkan BSU mereka.
        if (authProvider.role == 'petugas_bsu') {
          _pengangkutanList = _pengangkutanList
              .where((j) => j.targetBankId == authProvider.bankId)
              .toList();
        }
      } else {
        _error = response['message'] ?? 'Gagal memuat data jadwal';
      }
    } catch (e) {
      _error = 'Terjadi kesalahan: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<JadwalRutin> get rutinPenimbangan => _mapToRutin(_penimbanganList.where((j) => j.isRutin).toList());
  List<JadwalCustom> get customPenimbangan => _mapToCustom(_penimbanganList.where((j) => !j.isRutin).toList());
  List<JadwalRutin> get rutinPengangkutan => _mapToRutin(_pengangkutanList.where((j) => j.isRutin).toList());
  List<JadwalCustom> get customPengangkutan => _mapToCustom(_pengangkutanList.where((j) => !j.isRutin).toList());

  List<JadwalRutin> _mapToRutin(List<JadwalModel> models) {
    final map = <String, JadwalRutin>{};
    for (var m in models) {
      // Sertakan targetBankId di key agar jadwal pengangkutan ke BSU berbeda
      // tidak digabung menjadi satu baris.
      final key = '${m.jamMulai}-${m.jamSelesai}-${m.mingguKe}-${m.targetBankId}';
      if (map.containsKey(key)) {
        if (!map[key]!.days.contains(m.dayIndex)) {
          map[key]!.days.add(m.dayIndex);
          map[key]!.days.sort();
        }
      } else {
        map[key] = JadwalRutin(
          days: [m.dayIndex],
          weeks: m.mingguKe > 0 ? [m.mingguKe] : [],
          waktu: m.formattedWaktu,
          targetBankName: m.targetBankName,
        );
      }
    }
    return map.values.toList();
  }

  List<JadwalCustom> _mapToCustom(List<JadwalModel> models) {
    return models.map((m) => JadwalCustom(
      tanggal: m.tanggal ?? DateTime.now(),
      waktu: m.formattedWaktu,
      pesan: m.namaJadwalSpesial,
    )).toList();
  }
}
