import 'dart:convert';
import 'dart:io';

import 'package:etribunals/core/constants/app_ai.dart';
import 'package:etribunals/data/model/bookmarked_case.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const _kOnboarding = 'onboarding_complete_v2';
  static const _kBookmarks = 'bookmarked_cases';
  static const _kRecents = 'recent_cases';
  static const _kFiles = 'last_opened_files';
  static const _kReminders = 'hearing_reminders_on';
  static const _kAiRetry = 'ai_retry_until_ms';
  static const _maxRecents = 20;
  static const _maxFiles = 8;

  static Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  static Future<bool> isOnboardingComplete() async {
    return (await _prefs).getBool(_kOnboarding) ?? false;
  }

  static Future<void> setOnboardingComplete() async {
    await (await _prefs).setBool(_kOnboarding, true);
  }

  static Future<List<BookmarkedCase>> getBookmarks() async {
    return _readList(_kBookmarks);
  }

  static Future<bool> isBookmarked(String id) async {
    final items = await getBookmarks();
    return items.any((e) => e.id == id);
  }

  static Future<void> toggleBookmark(BookmarkedCase item) async {
    final prefs = await _prefs;
    final items = await getBookmarks();
    final exists = items.any((e) => e.id == item.id);
    if (exists) {
      items.removeWhere((e) => e.id == item.id);
    } else {
      items.insert(0, item);
    }
    await prefs.setString(_kBookmarks, jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  static Future<void> upsertBookmark(BookmarkedCase item) async {
    final prefs = await _prefs;
    final items = await getBookmarks();
    items.removeWhere((e) => e.id == item.id);
    items.insert(0, item);
    await prefs.setString(_kBookmarks, jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  static Future<void> updateBookmark(BookmarkedCase item) async {
    final prefs = await _prefs;
    final items = await getBookmarks();
    final i = items.indexWhere((e) => e.id == item.id);
    if (i < 0) return;
    items[i] = item;
    await prefs.setString(_kBookmarks, jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  static Future<List<Map<String, String>>> getOpenedFiles() async {
    final raw = (await _prefs).getString(_kFiles);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => Map<String, String>.from((e as Map).map((k, v) => MapEntry('$k', '$v'))))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> addOpenedFile({required String title, required String path}) async {
    final prefs = await _prefs;
    final items = await getOpenedFiles();
    items.removeWhere((e) => e['path'] == path);
    items.insert(0, {'title': title, 'path': path});
    await prefs.setString(_kFiles, jsonEncode(items.take(_maxFiles).toList()));
  }

  static Future<bool> remindersEnabled() async {
    return (await _prefs).getBool(_kReminders) ?? true;
  }

  static Future<void> setRemindersEnabled(bool on) async {
    await (await _prefs).setBool(_kReminders, on);
  }

  static Future<void> clearAllBookmarks() async {
    await (await _prefs).remove(_kBookmarks);
  }

  static Future<int> clearSavedPdfs() async {
    final items = await getOpenedFiles();
    var removed = 0;
    for (final item in items) {
      final path = item['path'];
      if (path == null || path.isEmpty) continue;
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
          removed += 1;
        }
      } catch (_) {}
    }
    await (await _prefs).remove(_kFiles);
    return removed;
  }

  static Future<void> removeBookmark(String id) async {
    final prefs = await _prefs;
    final items = await getBookmarks();
    items.removeWhere((e) => e.id == id);
    await prefs.setString(_kBookmarks, jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  static Future<List<BookmarkedCase>> getRecents() async {
    return _readList(_kRecents);
  }

  static Future<void> addRecent(BookmarkedCase item) async {
    final prefs = await _prefs;
    final items = await getRecents();
    items.removeWhere((e) => e.id == item.id);
    items.insert(0, item);
    final trimmed = items.take(_maxRecents).toList();
    await prefs.setString(_kRecents, jsonEncode(trimmed.map((e) => e.toJson()).toList()));
  }

  static Future<List<BookmarkedCase>> _readList(String key) async {
    final raw = (await _prefs).getString(key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => BookmarkedCase.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<String> geminiApiKey() async => AppAi.geminiKey;

  static Future<DateTime?> aiRetryUntil() async {
    final ms = (await _prefs).getInt(_kAiRetry) ?? 0;
    if (ms <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  static Future<void> setAiRetryUntil(DateTime until) async {
    await (await _prefs).setInt(_kAiRetry, until.millisecondsSinceEpoch);
  }

  static Future<void> clearAiRetry() async {
    await (await _prefs).remove(_kAiRetry);
  }
}
