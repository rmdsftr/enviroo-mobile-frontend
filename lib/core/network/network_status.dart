import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import 'api_failure.dart';

class NetworkStatus extends ChangeNotifier {
  static final NetworkStatus instance = NetworkStatus._();
  NetworkStatus._();

  bool _offline = false;
  bool get offline => _offline;

  int _recoveryToken = 0;
  int get recoveryToken => _recoveryToken;

  void reportFailure(ApiFailureKind kind) {
    if (kind != ApiFailureKind.offline) return;

    if (_offline) {
      notifyListeners();
      return;
    }

    _buktikanOffline();
  }

  bool _sedangMembuktikan = false;

  Future<void> _buktikanOffline() async {
    if (_sedangMembuktikan) return;
    _sedangMembuktikan = true;
    try {
      if (await _dnsHidup(const Duration(seconds: 2))) return;
      if (_offline) return;
      _offline = true;
      _mulaiProbe();
      notifyListeners();
    } finally {
      _sedangMembuktikan = false;
    }
  }

  void reportSuccess() {
    if (!_offline) return;
    _offline = false;
    _recoveryToken++;
    _hentikanProbe();
    notifyListeners();
  }

  static const Duration _jedaProbe = Duration(seconds: 3);
  static final String _host = Uri.parse(ApiConfig.baseUrl).host;

  Timer? _timerProbe;

  void _mulaiProbe() {
    if (_timerProbe != null) return;
    _timerProbe = Timer.periodic(_jedaProbe, (_) => probeSekarang());
  }

  void _hentikanProbe() {
    _timerProbe?.cancel();
    _timerProbe = null;
  }

  Future<bool> probeSekarang() async {
    if (!await _dnsHidup(const Duration(seconds: 5))) return false;
    reportSuccess();
    return true;
  }

  Future<bool> _dnsHidup(Duration timeout) async {
    try {
      final hasil = await InternetAddress.lookup(_host).timeout(timeout);
      return hasil.isNotEmpty && hasil.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
