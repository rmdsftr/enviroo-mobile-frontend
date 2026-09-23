import 'package:flutter/material.dart';

import '../models/bagi_hasil_bank_model.dart';
import '../models/penarikan_model.dart';
import '../models/penjualan_model.dart';
import '../services/reward_service.dart';
import 'penjualan_provider.dart' show FetchStatus;

/// State untuk modul reward — menaungi `/reward` dan `/nilai-reward`.
///
/// Sebelum ada provider ini, `RewardService` dipanggil langsung oleh tiga
/// provider berbeda dan respons `/nilai-reward` di-parse dua kali jadi dua model
/// yang berbeda. Sekarang pemanggilan dan parsing-nya tinggal di satu tempat.
class RewardProvider extends ChangeNotifier {
  // ── Daftar jenis reward ──  /reward/get-all
  FetchStatus _allStatus = FetchStatus.idle;
  List<RewardModel> _allReward = [];
  String? _allError;

  FetchStatus get allStatus => _allStatus;
  List<RewardModel> get allReward => _allReward;
  String? get allError => _allError;

  // ── Nilai reward per bank ──  /nilai-reward/get/:bankId
  //
  // Satu respons, dua proyeksi: [nilaiReward] untuk konversi poin (dipakai alur
  // penarikan nasabah) dan [persenNasabah] untuk persentase bagi hasil (dipakai
  // layar petugas). Keduanya diisi sekali jalan supaya endpoint-nya tidak
  // dipanggil dua kali.
  //
  // ⚠️ Slot ini menyimpan data untuk SATU bankId. Aman karena dua konsumennya
  // beda peran — persen dibaca petugas, nilai konversi dibaca nasabah — jadi
  // tidak pernah hidup bersamaan. Jangan anggap aman untuk konsumen baru tanpa
  // mengecek ulang.
  FetchStatus _nilaiStatus = FetchStatus.idle;
  List<NilaiRewardBank> _nilaiReward = [];
  List<PersenBagiHasilReward> _persenNasabah = [];
  String? _nilaiError;

  FetchStatus get nilaiStatus => _nilaiStatus;
  List<NilaiRewardBank> get nilaiReward => _nilaiReward;
  List<PersenBagiHasilReward> get persenNasabah => _persenNasabah;
  String? get nilaiError => _nilaiError;

  // ───────────────────────────────────────────────────────────────────────────

  Future<void> fetchAllReward() async {
    _allStatus = FetchStatus.loading;
    _allError = null;
    notifyListeners();

    final res = await RewardService.getAllReward();

    if (res['success'] == true) {
      final data = res['data'] as List? ?? [];
      _allReward = data.map((e) => RewardModel.fromJson(e)).toList();
      _allStatus = FetchStatus.success;
    } else {
      _allError = res['message']?.toString();
      _allStatus = FetchStatus.error;
    }
    notifyListeners();
  }

  Future<void> fetchNilaiReward(String bankId) async {
    _nilaiStatus = FetchStatus.loading;
    _nilaiError = null;
    notifyListeners();

    final res = await RewardService.getNilaiReward(bankId);

    if (res['success'] == true) {
      final list = (res['data'] as List? ?? []).whereType<Map<String, dynamic>>();

      _nilaiReward = list.map((e) => NilaiRewardBank.fromJson(e)).toList();
      _persenNasabah = list
          .map((e) => PersenBagiHasilReward.fromJson(e))
          .where((e) => e.levelUser == 'nasabah')
          .toList();

      _nilaiStatus = FetchStatus.success;
    } else {
      _nilaiError = res['message']?.toString();
      _nilaiStatus = FetchStatus.error;
    }
    notifyListeners();
  }
}
