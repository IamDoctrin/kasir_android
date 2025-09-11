import 'package:shared_preferences/shared_preferences.dart';

class SyncManager {
  static const _lastKey = 'last_sync_time';

  // Menyimpan waktu saat ini sebagai waktu sinkronisasi terakhir
  static Future<void> setLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastKey, DateTime.now().millisecondsSinceEpoch);
  }

  // Waktu sinkronisasi terakhir yang tersimpan
  static Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastKey);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }
}
