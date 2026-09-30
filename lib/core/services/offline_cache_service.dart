import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class OfflineCacheService {
  static const _eventsKey = 'offline_cache_events';
  static const _announcementsKey = 'offline_cache_announcements';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> saveEvents(List<dynamic> rawJson) async {
    await _storage.write(key: _eventsKey, value: jsonEncode(rawJson));
  }

  Future<List<dynamic>?> loadEvents() async {
    final json = await _storage.read(key: _eventsKey);
    if (json == null) return null;
    return jsonDecode(json) as List<dynamic>;
  }

  Future<void> saveAnnouncements(List<dynamic> rawJson) async {
    await _storage.write(key: _announcementsKey, value: jsonEncode(rawJson));
  }

  Future<List<dynamic>?> loadAnnouncements() async {
    final json = await _storage.read(key: _announcementsKey);
    if (json == null) return null;
    return jsonDecode(json) as List<dynamic>;
  }
}
