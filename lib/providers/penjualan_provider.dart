import 'dart:io';

import 'package:flutter/material.dart';

import '../models/penjualan_model.dart';
import '../services/penjualan_service.dart';
import '../services/reward_service.dart';

/// Status fetch generik
enum FetchStatus { idle, loading, success, error }

/// Provider yang menampung seluruh state untuk fitur Penjualan Eksternal.
///
/// Bertindak sebagai "wadah lintas-screen" agar form yang terbagi ke
/// beberapa halaman (Jenis Transaksi → Pilih Sampah → Barter Sembako →
/// Bukti Foto) tetap konsisten datanya tanpa harus di-pass manual.
class PenjualanProvider extends ChangeNotifier {
  // ── Riwayat ────────────────────────────────────────────────────────────────
  FetchStatus _riwayatStatus = FetchStatus.idle;
  String? _riwayatError;
  List<RiwayatPenjualanModel> _riwayat = [];

  FetchStatus get riwayatStatus => _riwayatStatus;
  String? get riwayatError => _riwayatError;
  List<RiwayatPenjualanModel> get riwayat => _riwayat;

  // ── Detail ─────────────────────────────────────────────────────────────────
  FetchStatus _detailStatus = FetchStatus.idle;
  String? _detailError;
  DetailPenjualanModel? _detail;

  FetchStatus get detailStatus => _detailStatus;
  String? get detailError => _detailError;
  DetailPenjualanModel? get detail => _detail;

  // ── Form (lintas-screen) ───────────────────────────────────────────────────
  RewardModel? _selectedReward;
  String _identitasPembeli = '';
  final List<ItemSampahPilihan> _itemsSampah = [];
  final List<ItemSembakoPilihan> _itemsSembako = [];
  File? _buktiFoto;

  RewardModel? get selectedReward => _selectedReward;
  String get identitasPembeli => _identitasPembeli;
  List<ItemSampahPilihan> get itemsSampah => _itemsSampah;
  List<ItemSembakoPilihan> get itemsSembako => _itemsSembako;
  File? get buktiFoto => _buktiFoto;
  bool get isSembako => _selectedReward?.isSembako ?? false;

  double get totalPoin {
    double total = 0;
    for (final item in _itemsSampah) {
      total += item.qty * item.hargaEksternal;
    }
    return total;
  }

  double get totalPoinSembako {
    double total = 0;
    for (final item in _itemsSembako) {
      total += item.qty * item.hargaEksternal;
    }
    return total;
  }

  // ── Submit ─────────────────────────────────────────────────────────────────
  bool _submitting = false;
  String? _submitError;

  bool get submitting => _submitting;
  String? get submitError => _submitError;

  // ───────────────────────────────────────────────────────────────────────────
  // Form mutations
  // ───────────────────────────────────────────────────────────────────────────

  void setReward(RewardModel? reward) {
    _selectedReward = reward;
    notifyListeners();
  }

  void setIdentitasPembeli(String value) {
    _identitasPembeli = value;
    // Tidak perlu notify — biasanya dipakai di TextField yang sudah re-render sendiri.
  }

  void toggleSampah(ItemSampahPilihan item, {bool? selected, double? qty}) {
    final idx = _itemsSampah.indexWhere((e) => e.sampahId == item.sampahId);
    final isSelected = selected ?? idx == -1;

    if (!isSelected) {
      if (idx != -1) _itemsSampah.removeAt(idx);
    } else {
      if (idx == -1) {
        _itemsSampah.add(ItemSampahPilihan(
          sampahId: item.sampahId,
          namaSampah: item.namaSampah,
          satuan: item.satuan,
          hargaEksternal: item.hargaEksternal,
          stokTersedia: item.stokTersedia,
          qty: qty ?? 0,
        ));
      } else if (qty != null) {
        _itemsSampah[idx].qty = qty;
      }
    }
    notifyListeners();
  }

  void updateQtySampah(String sampahId, double qty) {
    final idx = _itemsSampah.indexWhere((e) => e.sampahId == sampahId);
    if (idx == -1) return;
    final maxStok = _itemsSampah[idx].stokTersedia;
    _itemsSampah[idx].qty = qty.clamp(0, maxStok).toDouble();
    notifyListeners();
  }

  bool isSampahSelected(String sampahId) =>
      _itemsSampah.any((e) => e.sampahId == sampahId);

  double qtySampahOf(String sampahId) {
    final idx = _itemsSampah.indexWhere((e) => e.sampahId == sampahId);
    return idx == -1 ? 0 : _itemsSampah[idx].qty;
  }

  void toggleSembako(ItemSembakoPilihan item, {bool? selected, double? qty}) {
    final idx =
        _itemsSembako.indexWhere((e) => e.sembakoId == item.sembakoId);
    final isSelected = selected ?? idx == -1;

    if (!isSelected) {
      if (idx != -1) _itemsSembako.removeAt(idx);
    } else {
      if (idx == -1) {
        _itemsSembako.add(ItemSembakoPilihan(
          sembakoId: item.sembakoId,
          namaSembako: item.namaSembako,
          hargaEksternal: item.hargaEksternal,
          qty: qty ?? 0,
        ));
      } else if (qty != null) {
        _itemsSembako[idx].qty = qty;
      }
    }
    notifyListeners();
  }

  void updateQtySembako(String sembakoId, double qty) {
    final idx = _itemsSembako.indexWhere((e) => e.sembakoId == sembakoId);
    if (idx == -1) return;
    _itemsSembako[idx].qty = qty < 0 ? 0 : qty;
    notifyListeners();
  }

  bool isSembakoSelected(String sembakoId) =>
      _itemsSembako.any((e) => e.sembakoId == sembakoId);

  double qtySembakoOf(String sembakoId) {
    final idx = _itemsSembako.indexWhere((e) => e.sembakoId == sembakoId);
    return idx == -1 ? 0 : _itemsSembako[idx].qty;
  }

  void setBuktiFoto(File? file) {
    _buktiFoto = file;
    notifyListeners();
  }

  /// Bersihkan seluruh state form. Dipanggil setelah submit sukses
  /// atau ketika user keluar dari alur input.
  void resetForm() {
    _selectedReward = null;
    _identitasPembeli = '';
    _itemsSampah.clear();
    _itemsSembako.clear();
    _buktiFoto = null;
    _submitError = null;
    _submitting = false;
    notifyListeners();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Network calls
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> fetchRiwayat(String bankId, String token) async {
    _riwayatStatus = FetchStatus.loading;
    _riwayatError = null;
    notifyListeners();

    final res = await PenjualanService.getRiwayatEksternal(bankId, token);
    if (res['success'] == true) {
      final List data = res['data'] ?? [];
      _riwayat = data.map((e) => RiwayatPenjualanModel.fromJson(e)).toList();
      _riwayatStatus = FetchStatus.success;
    } else {
      _riwayatError = res['message'];
      _riwayatStatus = FetchStatus.error;
    }
    notifyListeners();
  }

  Future<void> fetchDetail(String penjualanId, String token) async {
    _detailStatus = FetchStatus.loading;
    _detailError = null;
    _detail = null;
    notifyListeners();

    final res = await PenjualanService.getDetailEksternal(penjualanId, token);
    if (res['success'] == true && res['data'] != null) {
      _detail = DetailPenjualanModel.fromJson(res['data']);
      _detailStatus = FetchStatus.success;
    } else {
      _detailError = res['message'];
      _detailStatus = FetchStatus.error;
    }
    notifyListeners();
  }

  // ── List Reward (Dropdown Screen 2) ─────────────────────────────────────────
  FetchStatus _rewardStatus = FetchStatus.idle;
  List<RewardModel> _rewards = [];
  String? _rewardError;
  FetchStatus get rewardStatus => _rewardStatus;
  List<RewardModel> get rewards => _rewards;
  String? get rewardError => _rewardError;

  Future<void> fetchRewards(String token) async {
    _rewardStatus = FetchStatus.loading;
    _rewardError = null;
    notifyListeners();

    final res = await RewardService.getAllReward(token);
    if (res['success'] == true) {
      final List data = res['data'] ?? [];
      _rewards = data.map((e) => RewardModel.fromJson(e)).toList();
      _rewardStatus = FetchStatus.success;
    } else {
      _rewardError = res['message'];
      _rewardStatus = FetchStatus.error;
    }
    notifyListeners();
  }

  // ── Nilai Reward Bank (Card Konversi Screen 3) ─────────────────────────────
  FetchStatus _nilaiStatus = FetchStatus.idle;
  List<NilaiRewardBankModel> _nilaiRewards = [];
  String? _nilaiError;
  FetchStatus get nilaiStatus => _nilaiStatus;
  List<NilaiRewardBankModel> get nilaiRewards => _nilaiRewards;
  String? get nilaiError => _nilaiError;

  /// Cari nilai konversi untuk reward yang sedang dipilih.
  NilaiRewardBankModel? get nilaiUntukRewardTerpilih {
    if (_selectedReward == null) return null;
    for (final n in _nilaiRewards) {
      if (n.rewardId == _selectedReward!.rewardId) return n;
    }
    return null;
  }

  Future<void> fetchNilaiReward(String bankId, String token) async {
    _nilaiStatus = FetchStatus.loading;
    _nilaiError = null;
    notifyListeners();

    final res = await RewardService.getNilaiReward(bankId, token);
    if (res['success'] == true) {
      final List data = res['data'] ?? [];
      _nilaiRewards =
          data.map((e) => NilaiRewardBankModel.fromJson(e)).toList();
      _nilaiStatus = FetchStatus.success;
    } else {
      _nilaiError = res['message'];
      _nilaiStatus = FetchStatus.error;
    }
    notifyListeners();
  }

  // ── Submit Penjualan ──────────────────────────────────────────────────────
  Future<bool> submitPenjualan({
    required String bankId,
    required String adminId,
    required String token,
  }) async {
    if (_selectedReward == null ||
        _identitasPembeli.isEmpty ||
        _itemsSampah.isEmpty ||
        _buktiFoto == null) {
      _submitError = 'Data belum lengkap';
      notifyListeners();
      return false;
    }

    _submitting = true;
    _submitError = null;
    notifyListeners();

    final res = await PenjualanService.submitPenjualanEksternal(
      bankId: bankId,
      adminId: adminId,
      token: token,
      rewardId: _selectedReward!.rewardId,
      identitasPembeli: _identitasPembeli,
      itemsSampah: _itemsSampah.map((e) => e.toPayload()).toList(),
      itemsSembako: isSembako
          ? _itemsSembako.map((e) => e.toPayload()).toList()
          : null,
      buktiFoto: _buktiFoto!,
    );

    _submitting = false;
    if (res['success'] == true) {
      notifyListeners();
      return true;
    } else {
      _submitError = res['message'];
      notifyListeners();
      return false;
    }
  }
}
