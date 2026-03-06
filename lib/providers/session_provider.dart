// ============================================================
//  GRADE MASTER — Session Provider (State Management)
// ============================================================

import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/session_storage_service.dart';

enum LoadState { idle, loading, success, error }

class SessionProvider extends ChangeNotifier {
  List<GradeSession> _sessions = [];
  GradeSession? _currentSession;
  LoadState _loadState = LoadState.idle;
  String? _errorMessage;

  List<GradeSession> get sessions => _sessions;
  GradeSession? get currentSession => _currentSession;
  LoadState get loadState => _loadState;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _loadState == LoadState.loading;

  final _storage = SessionStorageService.instance;

  // ── Load all sessions
  Future<void> loadSessions() async {
    _loadState = LoadState.loading;
    notifyListeners();
    try {
      _sessions = await _storage.loadSessions();
      _loadState = LoadState.success;
    } catch (e) {
      _errorMessage = e.toString();
      _loadState = LoadState.error;
    }
    notifyListeners();
  }

  // ── Create new session
  Future<GradeSession> createSession({
    required String name,
    String? description,
    String? semester,
    String? academicYear,
    String? institution,
    GpaScale gpaScale = GpaScale.scale4,
  }) async {
    final session = GradeSession(
      name: name,
      description: description,
      semester: semester,
      academicYear: academicYear,
      institution: institution,
      defaultGpaScale: gpaScale,
    );
    await _storage.upsertSession(session);
    _sessions.insert(0, session);
    _currentSession = session;
    notifyListeners();
    return session;
  }

  // ── Open existing session
  Future<void> openSession(GradeSession session) async {
    _currentSession = session;
    await _storage.setLastOpened(session.id);
    notifyListeners();
  }

  void closeSession() {
    _currentSession = null;
    notifyListeners();
  }

  // ── Add students to current session
  Future<void> addStudentsToSession(List<Student> students) async {
    final current = _currentSession;
    if (current == null) return;
    current.students.addAll(students);
    await _saveCurrentSession();
  }

  // ── Update a student's GPA scale
  Future<void> updateStudentGpaScale(String studentId, GpaScale scale) async {
    final current = _currentSession;
    if (current == null) return;
    final idx = current.students.indexWhere((s) => s.id == studentId);
    if (idx < 0) return;
    final old = current.students[idx];
    current.students[idx] = Student(
      id: old.id,
      name: old.name,
      studentId: old.studentId,
      department: old.department,
      level: old.level,
      subjects: old.subjects,
      gpaScale: scale,
    );
    await _saveCurrentSession();
  }

  // ── Remove student
  Future<void> removeStudent(String studentId) async {
    final current = _currentSession;
    if (current == null) return;
    current.students.removeWhere((s) => s.id == studentId);
    await _saveCurrentSession();
  }

  // ── Lock/unlock session
  Future<void> toggleSessionLock() async {
    final current = _currentSession;
    if (current == null) return;
    current.isLocked = !current.isLocked;
    await _saveCurrentSession();
  }

  // ── Delete session
  Future<void> deleteSession(String sessionId) async {
    await _storage.deleteSession(sessionId);
    _sessions.removeWhere((s) => s.id == sessionId);
    if (_currentSession?.id == sessionId) _currentSession = null;
    notifyListeners();
  }

  // ── Update session metadata
  Future<void> updateSessionMeta({
    required String sessionId,
    String? name,
    String? semester,
    String? academicYear,
    String? institution,
    GpaScale? gpaScale,
  }) async {
    final idx = _sessions.indexWhere((s) => s.id == sessionId);
    if (idx < 0) return;
    final s = _sessions[idx];
    if (name != null) s.name = name;
    if (gpaScale != null) s.defaultGpaScale = gpaScale;
    if (semester != null) s.semester = semester;
    if (academicYear != null) s.academicYear = academicYear;
    if (institution != null) s.institution = institution;
    await _saveCurrentSession();
  }

  // ── Internal save
  Future<void> _saveCurrentSession() async {
    final current = _currentSession;
    if (current == null) return;
    final idx = _sessions.indexWhere((s) => s.id == current.id);
    if (idx >= 0) _sessions[idx] = current;
    await _storage.upsertSession(current);
    notifyListeners();
  }

  // ── Apply global GPA scale change to all students in session
  Future<void> applyGpaScaleToAll(GpaScale scale) async {
    final current = _currentSession;
    if (current == null) return;
    current.defaultGpaScale = scale;
    for (int i = 0; i < current.students.length; i++) {
      final s = current.students[i];
      current.students[i] = Student(
        id: s.id,
        name: s.name,
        studentId: s.studentId,
        department: s.department,
        level: s.level,
        subjects: s.subjects,
        gpaScale: scale,
      );
    }
    await _saveCurrentSession();
  }
}
