import 'package:flutter/foundation.dart';

class PengangkutanProvider with ChangeNotifier {
  int _refreshToken = 0;
  int get refreshToken => _refreshToken;

  String? _pendingHighlightId;
  String? get pendingHighlightId => _pendingHighlightId;

  void refresh() {
    _refreshToken++;
    notifyListeners();
  }

  void setHighlight(String id) {
    _pendingHighlightId = id;
    notifyListeners();
  }

  void clearHighlight() {
    if (_pendingHighlightId == null) return;
    _pendingHighlightId = null;
    notifyListeners();
  }
}
