import 'package:firebase_messaging/firebase_messaging.dart';

/// Data deep-link yang dibawa sebuah push notification.
///
/// Ini batas bertipe antara FcmMessaging dan sisa aplikasi: hanya FcmMessaging
/// yang menyentuh [RemoteMessage] mentah, konsumen di luar `core/` cukup
/// menerima payload yang sudah didekode.
class NotifPayload {
  final String refType;
  final String refId;
  final Map<String, dynamic> data;

  const NotifPayload({
    required this.refType,
    required this.refId,
    required this.data,
  });

  /// Mengembalikan null bila message tidak membawa `ref_type`/`ref_id` yang
  /// bisa dipakai — pemanggil tinggal mengabaikannya.
  static NotifPayload? from(RemoteMessage message) {
    final data = message.data;
    final refType = data['ref_type'] as String?;
    final refId = data['ref_id'] as String?;
    if (refType == null || refType.isEmpty) return null;
    if (refId == null || refId.isEmpty) return null;
    return NotifPayload(refType: refType, refId: refId, data: data);
  }
}
