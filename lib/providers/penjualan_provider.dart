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
  File? _buktiFoto;

  RewardModel? get selectedReward => _selectedReward;
  String get identitasPembeli => _identitasPembeli;
  List<ItemSampahPilihan> get itemsSampah => _itemsSampah;
  File? get buktiFoto => _buktiFoto;

  /// Total harga penjualan real-time: jumlah (qty × hargaJual) tiap item.
  double get totalHarga {
    double total = 0;
    for (final item in _itemsSampah) {
      total += item.qty * item.hargaJual;
    }
    return total;
  }


  // ── Preview ────────────────────────────────────────────────────────────────
  FetchStatus _previewStatus = FetchStatus.idle;
  String? _previewError;
  PreviewPenjualanModel? _preview;

  FetchStatus get previewStatus => _previewStatus;
  String? get previewError => _previewError;
  PreviewPenjualanModel? get preview => _preview;

  // ── Submit ─────────────────────────────────────────────────────────────────
  bool _submitting = false;
  String? _submitError;
  String? _lastPenjualanId;

  bool get submitting => _submitting;
  String? get submitError => _submitError;
  String? get lastPenjualanId => _lastPenjualanId;

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

  void toggleSampah(ItemSampahPilihan item, {bool? selected}) {
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
          stokTersedia: item.stokTersedia,
          qty: 0,
          hargaJual: 0,
        ));
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

  void updateHargaJualSampah(String sampahId, double harga) {
    final idx = _itemsSampah.indexWhere((e) => e.sampahId == sampahId);
    if (idx == -1) return;
    _itemsSampah[idx].hargaJual = harga < 0 ? 0 : harga;
    notifyListeners();
  }

  bool isSampahSelected(String sampahId) =>
      _itemsSampah.any((e) => e.sampahId == sampahId);

  double qtySampahOf(String sampahId) {
    final idx = _itemsSampah.indexWhere((e) => e.sampahId == sampahId);
    return idx == -1 ? 0 : _itemsSampah[idx].qty;
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
    _buktiFoto = null;
    _submitError = null;
    _submitting = false;
    _preview = null;
    _previewStatus = FetchStatus.idle;
    _previewError = null;
    _lastPenjualanId = null;
    notifyListeners();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Network calls
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> fetchRiwayat(String bankId) async {
    _riwayatStatus = FetchStatus.loading;
    _riwayatError = null;
    notifyListeners();

    final res = await PenjualanService.getRiwayatEksternal(bankId);
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

  Future<void> fetchDetail(String penjualanId) async {
    _detailStatus = FetchStatus.loading;
    _detailError = null;
    _detail = null;
    notifyListeners();

    final res = await PenjualanService.getDetailEksternal(penjualanId);
    if (res['success'] == true && res['data'] != null) {
      _detail = DetailPenjualanModel.fromJson(res['data']);
      _detailStatus = FetchStatus.success;
    } else {
      _detailError = res['message'];
      _detailStatus = FetchStatus.error;
    }
    notifyListeners();
  }

  // ── Mitra Penjualan ─────────────────────────────────────────────────────────
  FetchStatus _mitraStatus = FetchStatus.idle;
  List<String> _mitraList = [];
  String? _mitraError;

  FetchStatus get mitraStatus => _mitraStatus;
  List<String> get mitraList => _mitraList;
  String? get mitraError => _mitraError;

  Future<void> fetchMitra(String bankId) async {
    _mitraStatus = FetchStatus.loading;
    _mitraError = null;
    notifyListeners();

    final res = await PenjualanService.getMitraEksternal(bankId);
    if (res['success'] == true) {
      final List data = res['data'] ?? [];
      _mitraList = data.map((e) => (e['nama'] ?? '').toString()).toList();
      _mitraStatus = FetchStatus.success;
    } else {
      _mitraError = res['message'];
      _mitraStatus = FetchStatus.error;
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

  Future<void> fetchRewards() async {
    _rewardStatus = FetchStatus.loading;
    _rewardError = null;
    notifyListeners();

    final res = await RewardService.getAllReward();
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


  // ── Preview Penjualan ─────────────────────────────────────────────────────
  Future<bool> fetchPreview({required String bankId}) async {
    if (_selectedReward == null || _itemsSampah.isEmpty) {
      _previewError = 'Data belum lengkap';
      _previewStatus = FetchStatus.error;
      notifyListeners();
      return false;
    }

    _previewStatus = FetchStatus.loading;
    _previewError = null;
    _preview = null;
    notifyListeners();

    final res = await PenjualanService.previewPenjualanEksternal(
      bankId: bankId,
      rewardId: _selectedReward!.rewardId,
      itemsSampah: _itemsSampah.map((e) => e.toPayload()).toList(),
    );

    if (res['success'] == true && res['data'] != null) {
      _preview = PreviewPenjualanModel.fromJson(
          res['data'] as Map<String, dynamic>);
      _previewStatus = FetchStatus.success;
      notifyListeners();
      return true;
    } else {
      _previewError = res['message']?.toString();
      _previewStatus = FetchStatus.error;
      notifyListeners();
      return false;
    }
  }

  // ── Submit Penjualan ──────────────────────────────────────────────────────
  Future<bool> submitPenjualan({
    required String bankId,
    required String adminId,
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
      rewardId: _selectedReward!.rewardId,
      identitasPembeli: _identitasPembeli,
      itemsSampah: _itemsSampah.map((e) => e.toPayload()).toList(),
      buktiFoto: _buktiFoto!,
    );

    _submitting = false;
    if (res['success'] == true) {
      _lastPenjualanId = res['penjualan_id']?.toString();
      notifyListeners();
      return true;
    } else {
      _submitError = res['message']?.toString();
      notifyListeners();
      return false;
    }
  }
}
