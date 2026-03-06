// ============================================================
//  GRADE MASTER — Core Domain Models
//  Author: Senior Dart/Flutter Engineer
// ============================================================

import 'dart:convert';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

// ─────────────────────────────────────────────
//  GPA Scale Enum
// ─────────────────────────────────────────────
enum GpaScale {
  scale4(maxGpa: 4.0, label: '4.0 Scale (US Standard)'),
  scale5(maxGpa: 5.0, label: '5.0 Scale (Nigeria/West Africa)'),
  scale10(maxGpa: 10.0, label: '10.0 Scale (India/Europe)'),
  scale20(maxGpa: 20.0, label: '20.0 Scale (France/Francophone)');

  const GpaScale({required this.maxGpa, required this.label});
  final double maxGpa;
  final String label;
}

enum ExcelOrientation { studentsInRows, studentsInColumns }

// ─────────────────────────────────────────────
//  Letter Grade with Cutoffs
// ─────────────────────────────────────────────
class LetterGrade {
  final String letter; // A+, A, A-, B+, B, etc.
  final double minPercent; // e.g. 90.0
  final double maxPercent; // e.g. 100.0
  final double gpaPoint4; // 4.0 equivalent
  final double gpaPoint5; // 5.0 equivalent
  final double gpaPoint10; // 10.0 equivalent
  final double gpaPoint20; // 20.0 equivalent
  final String remark; // Excellent, Very Good, etc.

  const LetterGrade({
    required this.letter,
    required this.minPercent,
    required this.maxPercent,
    required this.gpaPoint4,
    required this.gpaPoint5,
    required this.gpaPoint10,
    required this.gpaPoint20,
    required this.remark,
  });

  double gpaForScale(GpaScale scale) {
    switch (scale) {
      case GpaScale.scale4:
        return gpaPoint4;
      case GpaScale.scale5:
        return gpaPoint5;
      case GpaScale.scale10:
        return gpaPoint10;
      case GpaScale.scale20:
        return gpaPoint20;
    }
  }

  Map<String, dynamic> toJson() => {
        'letter': letter,
        'minPercent': minPercent,
        'maxPercent': maxPercent,
        'gpaPoint4': gpaPoint4,
        'gpaPoint5': gpaPoint5,
        'gpaPoint10': gpaPoint10,
        'gpaPoint20': gpaPoint20,
        'remark': remark,
      };
}

// ─────────────────────────────────────────────
//  Default Grade Tables
// ─────────────────────────────────────────────
class GradeTable {
  static const List<LetterGrade> standard = [
    LetterGrade(
      letter: 'A+',
      minPercent: 97,
      maxPercent: 100,
      gpaPoint4: 4.0,
      gpaPoint5: 5.0,
      gpaPoint10: 10.0,
      gpaPoint20: 20.0,
      remark: 'Exceptional',
    ),
    LetterGrade(
      letter: 'A',
      minPercent: 93,
      maxPercent: 96.9,
      gpaPoint4: 4.0,
      gpaPoint5: 5.0,
      gpaPoint10: 9.5,
      gpaPoint20: 19.0,
      remark: 'Excellent',
    ),
    LetterGrade(
      letter: 'A-',
      minPercent: 90,
      maxPercent: 92.9,
      gpaPoint4: 3.7,
      gpaPoint5: 4.7,
      gpaPoint10: 9.0,
      gpaPoint20: 18.0,
      remark: 'Excellent',
    ),
    LetterGrade(
      letter: 'B+',
      minPercent: 87,
      maxPercent: 89.9,
      gpaPoint4: 3.3,
      gpaPoint5: 4.3,
      gpaPoint10: 8.5,
      gpaPoint20: 17.0,
      remark: 'Very Good',
    ),
    LetterGrade(
      letter: 'B',
      minPercent: 83,
      maxPercent: 86.9,
      gpaPoint4: 3.0,
      gpaPoint5: 4.0,
      gpaPoint10: 8.0,
      gpaPoint20: 16.0,
      remark: 'Good',
    ),
    LetterGrade(
      letter: 'B-',
      minPercent: 80,
      maxPercent: 82.9,
      gpaPoint4: 2.7,
      gpaPoint5: 3.7,
      gpaPoint10: 7.5,
      gpaPoint20: 15.0,
      remark: 'Good',
    ),
    LetterGrade(
      letter: 'C+',
      minPercent: 77,
      maxPercent: 79.9,
      gpaPoint4: 2.3,
      gpaPoint5: 3.3,
      gpaPoint10: 7.0,
      gpaPoint20: 14.0,
      remark: 'Above Average',
    ),
    LetterGrade(
      letter: 'C',
      minPercent: 73,
      maxPercent: 76.9,
      gpaPoint4: 2.0,
      gpaPoint5: 3.0,
      gpaPoint10: 6.5,
      gpaPoint20: 13.0,
      remark: 'Average',
    ),
    LetterGrade(
      letter: 'C-',
      minPercent: 70,
      maxPercent: 72.9,
      gpaPoint4: 1.7,
      gpaPoint5: 2.7,
      gpaPoint10: 6.0,
      gpaPoint20: 12.0,
      remark: 'Average',
    ),
    LetterGrade(
      letter: 'D+',
      minPercent: 67,
      maxPercent: 69.9,
      gpaPoint4: 1.3,
      gpaPoint5: 2.3,
      gpaPoint10: 5.5,
      gpaPoint20: 11.0,
      remark: 'Below Average',
    ),
    LetterGrade(
      letter: 'D',
      minPercent: 63,
      maxPercent: 66.9,
      gpaPoint4: 1.0,
      gpaPoint5: 2.0,
      gpaPoint10: 5.0,
      gpaPoint20: 10.0,
      remark: 'Pass',
    ),
    LetterGrade(
      letter: 'D-',
      minPercent: 60,
      maxPercent: 62.9,
      gpaPoint4: 0.7,
      gpaPoint5: 1.0,
      gpaPoint10: 4.5,
      gpaPoint20: 9.0,
      remark: 'Marginal Pass',
    ),
    LetterGrade(
      letter: 'F',
      minPercent: 0,
      maxPercent: 59.9,
      gpaPoint4: 0.0,
      gpaPoint5: 0.0,
      gpaPoint10: 0.0,
      gpaPoint20: 0.0,
      remark: 'Fail',
    ),
  ];

  static LetterGrade resolve(double percentage) {
    for (final g in standard) {
      if (percentage >= g.minPercent && percentage <= g.maxPercent) return g;
    }
    return standard.last; // F
  }
}

// ─────────────────────────────────────────────
//  Academic Standing / Honors Remark
// ─────────────────────────────────────────────
class AcademicStanding {
  final String title;
  final String latinHonor;
  final double minGpa4;
  final double minGpa5;
  final double minGpa10;
  final double minGpa20;
  final int color; // ARGB

  const AcademicStanding({
    required this.title,
    required this.latinHonor,
    required this.minGpa4,
    required this.minGpa5,
    required this.minGpa10,
    required this.minGpa20,
    required this.color,
  });

  static AcademicStanding resolve(double gpa, GpaScale scale) {
    double gpa4Equiv;
    switch (scale) {
      case GpaScale.scale4:
        gpa4Equiv = gpa;
      case GpaScale.scale5:
        gpa4Equiv = (gpa / 5.0) * 4.0;
      case GpaScale.scale10:
        gpa4Equiv = (gpa / 10.0) * 4.0;
      case GpaScale.scale20:
        gpa4Equiv = (gpa / 20.0) * 4.0;
    }

    for (final s in standings) {
      if (gpa4Equiv >= s.minGpa4) return s;
    }
    return standings.last;
  }

  static const List<AcademicStanding> standings = [
    AcademicStanding(
      title: 'Summa Cum Laude',
      latinHonor: 'With Highest Distinction',
      minGpa4: 3.90,
      minGpa5: 4.88,
      minGpa10: 9.75,
      minGpa20: 19.5,
      color: 0xFFFFD700,
    ),
    AcademicStanding(
      title: 'Magna Cum Laude',
      latinHonor: 'With Great Distinction',
      minGpa4: 3.70,
      minGpa5: 4.63,
      minGpa10: 9.25,
      minGpa20: 18.5,
      color: 0xFFC0C0C0,
    ),
    AcademicStanding(
      title: 'Cum Laude',
      latinHonor: 'With Distinction',
      minGpa4: 3.50,
      minGpa5: 4.38,
      minGpa10: 8.75,
      minGpa20: 17.5,
      color: 0xFFCD7F32,
    ),
    AcademicStanding(
      title: 'Upper Class Honours',
      latinHonor: 'First Class',
      minGpa4: 3.00,
      minGpa5: 3.75,
      minGpa10: 7.50,
      minGpa20: 15.0,
      color: 0xFF4CAF50,
    ),
    AcademicStanding(
      title: 'Second Class Upper',
      latinHonor: '2:1',
      minGpa4: 2.50,
      minGpa5: 3.13,
      minGpa10: 6.25,
      minGpa20: 12.5,
      color: 0xFF2196F3,
    ),
    AcademicStanding(
      title: 'Second Class Lower',
      latinHonor: '2:2',
      minGpa4: 2.00,
      minGpa5: 2.50,
      minGpa10: 5.00,
      minGpa20: 10.0,
      color: 0xFFFF9800,
    ),
    AcademicStanding(
      title: 'Third Class',
      latinHonor: 'Pass',
      minGpa4: 1.00,
      minGpa5: 1.25,
      minGpa10: 2.50,
      minGpa20: 5.0,
      color: 0xFFFF5722,
    ),
    AcademicStanding(
      title: 'Fail',
      latinHonor: 'Not Passed',
      minGpa4: 0.00,
      minGpa5: 0.00,
      minGpa10: 0.00,
      minGpa20: 0.0,
      color: 0xFFF44336,
    ),
  ];
}

// ─────────────────────────────────────────────
//  Subject / Course Model
// ─────────────────────────────────────────────
class Subject {
  final String id;
  final String name;
  final String code;
  final int creditHours;
  double score; // raw score (0-100)
  double maxScore; // max possible score
  late LetterGrade grade;

  Subject({
    String? id,
    required this.name,
    required this.code,
    required this.creditHours,
    required this.score,
    this.maxScore = 100.0,
  }) : id = id ?? _uuid.v4() {
    grade = GradeTable.resolve(percentage);
  }

  double get percentage => (score / maxScore) * 100.0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'creditHours': creditHours,
        'score': score,
        'maxScore': maxScore,
      };

  factory Subject.fromJson(Map<String, dynamic> j) => Subject(
        id: j['id'],
        name: j['name'],
        code: j['code'],
        creditHours: j['creditHours'],
        score: j['score'].toDouble(),
        maxScore: (j['maxScore'] ?? 100.0).toDouble(),
      );
}

// ─────────────────────────────────────────────
//  Student Model
// ─────────────────────────────────────────────
class Student {
  final String id;
  final String name;
  final String studentId;
  final String? department;
  final String? level; // Year 1, Year 2, etc.
  final List<Subject> subjects;
  final GpaScale gpaScale;
  final int emptyFieldsCount;

  Student({
    String? id,
    required this.name,
    required this.studentId,
    this.department,
    this.level,
    required this.subjects,
    this.gpaScale = GpaScale.scale4,
    this.emptyFieldsCount = 0,
  }) : id = id ?? _uuid.v4();

  // ── GPA Calculation (weighted by credit hours)
  double get gpa {
    if (subjects.isEmpty) return 0.0;
    double totalPoints = 0;
    int totalCredits = 0;
    for (final s in subjects) {
      totalPoints += s.grade.gpaForScale(gpaScale) * s.creditHours;
      totalCredits += s.creditHours;
    }
    return totalCredits == 0 ? 0.0 : totalPoints / totalCredits;
  }

  double get averagePercentage {
    if (subjects.isEmpty) return 0.0;
    return subjects.map((s) => s.percentage).reduce((a, b) => a + b) /
        subjects.length;
  }

  AcademicStanding get standing => AcademicStanding.resolve(gpa, gpaScale);

  int get totalCreditHours => subjects.fold(0, (sum, s) => sum + s.creditHours);

  int get passedSubjects => subjects.where((s) => s.grade.letter != 'F').length;
  int get failedSubjects => subjects.where((s) => s.grade.letter == 'F').length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'studentId': studentId,
        'department': department,
        'level': level,
        'subjects': subjects.map((s) => s.toJson()).toList(),
        'gpaScale': gpaScale.name,
        'emptyFieldsCount': emptyFieldsCount,
      };

  factory Student.fromJson(Map<String, dynamic> j) => Student(
        id: j['id'],
        name: j['name'],
        studentId: j['studentId'],
        department: j['department'],
        level: j['level'],
        gpaScale: GpaScale.values.firstWhere(
          (e) => e.name == j['gpaScale'],
          orElse: () => GpaScale.scale4,
        ),
        emptyFieldsCount: j['emptyFieldsCount'] ?? 0,
        subjects:
            (j['subjects'] as List).map((s) => Subject.fromJson(s)).toList(),
      );
}

// ─────────────────────────────────────────────
//  Session Model
// ─────────────────────────────────────────────
class GradeSession {
  final String id;
  String name;
  String? description;
  final DateTime createdAt;
  DateTime updatedAt;
  final List<Student> students;
  GpaScale defaultGpaScale;
  String? semester;
  String? academicYear;
  String? institution;
  bool isLocked;

  GradeSession({
    String? id,
    required this.name,
    this.description,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Student>? students,
    this.defaultGpaScale = GpaScale.scale4,
    this.semester,
    this.academicYear,
    this.institution,
    this.isLocked = false,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        students = students ?? [];

  int get totalStudents => students.length;

  double get sessionAverageGpa {
    if (students.isEmpty) return 0.0;
    return students.map((s) => s.gpa).reduce((a, b) => a + b) / students.length;
  }

  double get sessionAveragePercentage {
    if (students.isEmpty) return 0.0;
    return students.map((s) => s.averagePercentage).reduce((a, b) => a + b) /
        students.length;
  }

  Map<String, int> get standingDistribution {
    final dist = <String, int>{};
    for (final s in students) {
      final title = s.standing.title;
      dist[title] = (dist[title] ?? 0) + 1;
    }
    return dist;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'students': students.map((s) => s.toJson()).toList(),
        'defaultGpaScale': defaultGpaScale.name,
        'semester': semester,
        'academicYear': academicYear,
        'institution': institution,
        'isLocked': isLocked,
      };

  factory GradeSession.fromJson(Map<String, dynamic> j) => GradeSession(
        id: j['id'],
        name: j['name'],
        description: j['description'],
        createdAt: DateTime.parse(j['createdAt']),
        updatedAt: DateTime.parse(j['updatedAt']),
        defaultGpaScale: GpaScale.values.firstWhere(
          (e) => e.name == j['defaultGpaScale'],
          orElse: () => GpaScale.scale4,
        ),
        semester: j['semester'],
        academicYear: j['academicYear'],
        institution: j['institution'],
        isLocked: j['isLocked'] ?? false,
        students:
            (j['students'] as List).map((s) => Student.fromJson(s)).toList(),
      );

  String toJsonString() => jsonEncode(toJson());
  factory GradeSession.fromJsonString(String s) =>
      GradeSession.fromJson(jsonDecode(s));
}

// ─────────────────────────────────────────────
//  Excel Column Mapping Config
// ─────────────────────────────────────────────
class ExcelMapping {
  final int nameCol;
  final int studentIdCol;
  final int departmentCol;
  final int levelCol;
  final int firstSubjectCol;
  final int headerRow;
  final List<String> subjectHeaders;
  final ExcelOrientation orientation;

  const ExcelMapping({
    this.nameCol = 0,
    this.studentIdCol = 1,
    this.departmentCol = 2,
    this.levelCol = 3,
    this.firstSubjectCol = 4,
    this.headerRow = 0,
    this.subjectHeaders = const [],
    this.orientation = ExcelOrientation.studentsInRows,
  });
}
