// ============================================================
//  GRADE MASTER — Session Storage Service
//  Handles persistent storage of all sessions using SharedPreferences
// ============================================================

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class SessionStorageService {
  static const String _sessionsKey = 'grade_master_sessions';
  static const String _lastOpenedKey = 'grade_master_last_opened';

  static SessionStorageService? _instance;
  SessionStorageService._();
  static SessionStorageService get instance =>
      _instance ??= SessionStorageService._();

  // ── Load all sessions from storage
  Future<List<GradeSession>> loadSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_sessionsKey);
      if (raw == null) return [];
      final List<dynamic> list = jsonDecode(raw);
      return list.map((j) => GradeSession.fromJson(j)).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (e) {
      return [];
    }
  }

  // ── Save all sessions
  Future<bool> saveSessions(List<GradeSession> sessions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(sessions.map((s) => s.toJson()).toList());
      return prefs.setString(_sessionsKey, encoded);
    } catch (e) {
      return false;
    }
  }

  // ── Upsert a single session
  Future<bool> upsertSession(GradeSession session) async {
    final sessions = await loadSessions();
    final idx = sessions.indexWhere((s) => s.id == session.id);
    session.updatedAt = DateTime.now();
    if (idx >= 0) {
      sessions[idx] = session;
    } else {
      sessions.add(session);
    }
    return saveSessions(sessions);
  }

  // ── Delete session by ID
  Future<bool> deleteSession(String id) async {
    final sessions = await loadSessions();
    sessions.removeWhere((s) => s.id == id);
    return saveSessions(sessions);
  }

  // ── Track last opened session
  Future<void> setLastOpened(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastOpenedKey, sessionId);
  }

  Future<String?> getLastOpened() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastOpenedKey);
  }

  // ── Clear all data (for dev/testing)
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionsKey);
    await prefs.remove(_lastOpenedKey);
  }
}
