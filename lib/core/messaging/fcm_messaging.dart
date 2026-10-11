import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../providers/auth_provider.dart';
import '../../providers/notifikasi_provider.dart';
import 'notif_payload.dart';

typedef NotifDeepLink = void Function(NotifPayload payload);

class FcmMessaging {
  FcmMessaging({
    required AuthProvider auth,
    required NotifikasiProvider notif,
    required NotifDeepLink onDeepLink,
    FirebaseMessaging? messaging,
  })  : _auth = auth,
        _notif = notif,
        _onDeepLink = onDeepLink,
        _messaging = messaging ?? FirebaseMessaging.instance;

  final AuthProvider _auth;
  final NotifikasiProvider _notif;
  final NotifDeepLink _onDeepLink;
  final FirebaseMessaging _messaging;

  final List<StreamSubscription<RemoteMessage>> _subs = [];
  StreamSubscription<String>? _tokenSub;
  bool _started = false;

  NotifPayload? _pendingDeepLink;

  NotifPayload? takePendingDeepLink() {
    final payload = _pendingDeepLink;
    _pendingDeepLink = null;
    return payload;
  }

  void start() {
    if (_started) return;
    _started = true;

    _tokenSub = _messaging.onTokenRefresh.listen((newToken) {
      sendToken(explicitToken: newToken);
    });

    _subs.add(FirebaseMessaging.onMessage.listen((msg) {
      debugPrint('[FCM] onMessage received: ${msg.notification?.title}');
      refreshNotifikasi();
    }));

    _subs.add(FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      debugPrint('[FCM] onMessageOpenedApp: ${msg.notification?.title}');
      refreshNotifikasi();
      _dispatchDeepLink(msg);
    }));

    _messaging.getInitialMessage().then((msg) {
      if (!_started || msg == null) return;
      debugPrint('[FCM] getInitialMessage: ${msg.notification?.title}');
      refreshNotifikasi();
      _pendingDeepLink = NotifPayload.from(msg);
    });
  }

  Future<void> dispose() async {
    _started = false;
    _pendingDeepLink = null;
    await _tokenSub?.cancel();
    _tokenSub = null;
    for (final sub in _subs) {
      await sub.cancel();
    }
    _subs.clear();
  }

  Future<void> onAppResumed() async {
    if (!_auth.isLoggedIn) return;
    await _auth.refreshToken();
    sendToken();
    refreshNotifikasi();
  }

  void onLogin({String tag = 'Auth'}) {
    _notif.fetchNotifikasi(role: _auth.role);

    _messaging.requestPermission();

    _registerToken(logTag: tag);
  }

  Future<void> sendToken({String? explicitToken}) =>
      _registerToken(explicitToken: explicitToken);

  Future<void> _registerToken({String? explicitToken, String? logTag}) async {
    if (!_auth.isLoggedIn) return;
    final fcmToken = explicitToken ?? await _messaging.getToken();
    if (fcmToken == null || fcmToken.isEmpty) {
      if (logTag != null) {
        debugPrint('[$logTag] FCM token null/kosong, skip register.');
      }
      return;
    }
    if (logTag != null) {
      debugPrint('[$logTag] FCM token diperoleh, mendaftarkan ke backend...');
    }
    _notif.registerFcmToken(fcmToken: fcmToken);
  }

  void refreshNotifikasi({int retryCount = 0}) {
    if (!_auth.isLoggedIn) {
      debugPrint('[Notif] refreshNotifikasi: user belum login, skip.');
      return;
    }
    final token = _auth.currentUser?.accessToken ?? '';
    if (token.isEmpty) {
      if (retryCount < 3) {
        debugPrint(
            '[Notif] refreshNotifikasi: token kosong, retry ke-${retryCount + 1}...');
        Future.delayed(const Duration(milliseconds: 500), () {
          refreshNotifikasi(retryCount: retryCount + 1);
        });
      } else {
        debugPrint(
            '[Notif] refreshNotifikasi: token tetap kosong setelah 3x retry, abort.');
      }
      return;
    }
    debugPrint('[Notif] refreshNotifikasi: fetching untuk role=${_auth.role}');
    _notif.fetchNotifikasi(role: _auth.role);
  }

  void _dispatchDeepLink(RemoteMessage msg) {
    final payload = NotifPayload.from(msg);
    if (payload == null) return;
    _onDeepLink(payload);
  }
}
