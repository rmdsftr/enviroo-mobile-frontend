import 'package:flutter/foundation.dart';
import '../models/jadwal_model.dart';
import '../services/jadwal_service.dart';
import '../providers/auth_provider.dart';
import '../screens/admin_bsu/jadwal_screen.dart'; // import for JadwalRutin & JadwalCustom

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
    final token = authProvider.currentUser?.accessToken;
    if (token == null || authProvider.bankId == null) {
      _error = 'Anda belum login atau bank tidak ditemukan.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await JadwalService.getJadwalByBankId(
        authProvider.bankId!,
        token,
      );

      if (response['success']) {
        final Map<String, dynamic> data = response['data'];
        
        final List<dynamic> pNimbang = data['penimbangan'] ?? [];
        final List<dynamic> pAngkut = data['pengangkutan'] ?? [];

        _penimbanganList = pNimbang.map((json) => JadwalModel.fromJson(json)).toList();
        _pengangkutanList = pAngkut.map((json) => JadwalModel.fromJson(json)).toList();
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

  // ── Helper Getters for Screen ──

  List<JadwalRutin> get rutinPenimbangan {
    final list = _penimbanganList.where((j) => j.isRutin).toList();
    return _mapToRutin(list);
  }

  List<JadwalCustom> get customPenimbangan {
    final list = _penimbanganList.where((j) => !j.isRutin).toList();
    return _mapToCustom(list);
  }

  List<JadwalRutin> get rutinPengangkutan {
    final list = _pengangkutanList.where((j) => j.isRutin).toList();
    return _mapToRutin(list);
  }

  List<JadwalCustom> get customPengangkutan {
    final list = _pengangkutanList.where((j) => !j.isRutin).toList();
    return _mapToCustom(list);
  }

  List<JadwalRutin> _mapToRutin(List<JadwalModel> models) {
    // Kelompokkan berdasarkan waktu & minggu_ke agar tidak duplikat baris
    final map = <String, JadwalRutin>{};
    for (var m in models) {
      final key = '${m.jamMulai}-${m.jamSelesai}-${m.mingguKe}';
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
