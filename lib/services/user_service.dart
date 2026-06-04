import 'dart:convert';
import '../config/api_config.dart';
import 'api_client.dart';

class UserService {
  static Future<Map<String, dynamic>?> getActiveUser(String userId) async {
    try {
      final response = await ApiClient.get(Uri.parse('${ApiConfig.activeUserUrl}/$userId'));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['data'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
