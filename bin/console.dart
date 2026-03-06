import 'dart:io';

import 'package:grade_master/models/models.dart';

void main(List<String> args) {
  stdout.writeln('Grade Master Console');
  stdout.writeln('--------------------');

  final scale = _promptForScale();
  final students = <Student>[];

  while (true) {
    stdout.writeln('');
    stdout.writeln('Enter student details');
    final name = _readRequired('Name');
    final studentId = _readRequired('Student ID');
    final department = _readOptional('Department');
    final level = _readOptional('Level');

    final subjects = <Subject>[];
    stdout.writeln('');
    stdout.writeln('Add subjects (leave Subject Name empty to finish).');
    while (true) {
      final subjectName = _readOptional('Subject Name');
      if (subjectName == null || subjectName.isEmpty) {
        break;
      }

      final code = _readRequired('Subject Code');
      final creditHours = _readInt('Credit Hours', min: 1);
      final score = _readDouble('Score', min: 0);
      final maxScore = _readDouble('Max Score', min: 0.0001, defaultValue: 100);

      subjects.add(
        Subject(
          name: subjectName,
          code: code,
          creditHours: creditHours,
          score: score,
          maxScore: maxScore,
        ),
      );
    }

    final student = Student(
      name: name,
      studentId: studentId,
      department: department?.isEmpty == true ? null : department,
      level: level?.isEmpty == true ? null : level,
      subjects: subjects,
      gpaScale: scale,
    );

    students.add(student);
    _printStudentReport(student);

    final addAnother =
        _readYesNo('Add another student? (y/n)', defaultYes: true);
    if (!addAnother) break;
  }

  _printSummary(students, scale);
}

GpaScale _promptForScale() {
  stdout.writeln('');
  stdout.writeln('Choose GPA scale:');
  for (var i = 0; i < GpaScale.values.length; i++) {
    final scale = GpaScale.values[i];
    stdout.writeln('${i + 1}. ${scale.label}');
  }

  while (true) {
    stdout.write('Selection [1-${GpaScale.values.length}] (default 1): ');
    final raw = stdin.readLineSync()?.trim();
    if (raw == null || raw.isEmpty) return GpaScale.values.first;

    final selected = int.tryParse(raw);
    if (selected != null &&
        selected >= 1 &&
        selected <= GpaScale.values.length) {
      return GpaScale.values[selected - 1];
    }

    stdout.writeln('Invalid selection.');
  }
}

String _readRequired(String label) {
  while (true) {
    stdout.write('$label: ');
    final value = stdin.readLineSync()?.trim();
    if (value != null && value.isNotEmpty) return value;
    stdout.writeln('$label is required.');
  }
}

String? _readOptional(String label) {
  stdout.write('$label: ');
  return stdin.readLineSync()?.trim();
}

int _readInt(String label, {required int min}) {
  while (true) {
    stdout.write('$label: ');
    final value = int.tryParse(stdin.readLineSync()?.trim() ?? '');
    if (value != null && value >= min) return value;
    stdout.writeln('Enter a whole number >= $min.');
  }
}

double _readDouble(
  String label, {
  required double min,
  double? defaultValue,
}) {
  while (true) {
    if (defaultValue != null) {
      stdout.write('$label (default ${defaultValue.toStringAsFixed(0)}): ');
    } else {
      stdout.write('$label: ');
    }

    final raw = stdin.readLineSync()?.trim() ?? '';
    if (raw.isEmpty && defaultValue != null) return defaultValue;

    final value = double.tryParse(raw);
    if (value != null && value >= min) return value;
    stdout.writeln('Enter a number >= $min.');
  }
}

bool _readYesNo(String label, {required bool defaultYes}) {
  while (true) {
    stdout.write('$label ');
    final raw = stdin.readLineSync()?.trim().toLowerCase();
    if (raw == null || raw.isEmpty) return defaultYes;
    if (raw == 'y' || raw == 'yes') return true;
    if (raw == 'n' || raw == 'no') return false;
    stdout.writeln('Please enter y or n.');
  }
}

void _printStudentReport(Student student) {
  stdout.writeln('');
  stdout.writeln('Student Report');
  stdout.writeln('--------------');
  stdout.writeln('${student.name} (${student.studentId})');
  stdout.writeln(
    'GPA: ${student.gpa.toStringAsFixed(2)} / ${student.gpaScale.maxGpa.toStringAsFixed(1)}',
  );
  stdout.writeln('Average: ${student.averagePercentage.toStringAsFixed(2)}%');
  stdout.writeln(
      'Standing: ${student.standing.title} (${student.standing.latinHonor})');
  stdout.writeln(
      'Passed: ${student.passedSubjects} | Failed: ${student.failedSubjects}');

  if (student.subjects.isEmpty) {
    stdout.writeln('No subjects entered.');
    return;
  }

  stdout.writeln('');
  stdout.writeln('Subjects:');
  for (final subject in student.subjects) {
    stdout.writeln(
      '- ${subject.code} ${subject.name}: '
      '${subject.score}/${subject.maxScore} '
      '(${subject.percentage.toStringAsFixed(1)}%) '
      'Grade ${subject.grade.letter}',
    );
  }
}

void _printSummary(List<Student> students, GpaScale scale) {
  stdout.writeln('');
  stdout.writeln('Session Summary');
  stdout.writeln('---------------');
  stdout.writeln('Students: ${students.length}');
  stdout.writeln('Scale: ${scale.label}');

  if (students.isEmpty) {
    stdout.writeln('No students were entered.');
    return;
  }

  final avgGpa =
      students.map((s) => s.gpa).reduce((a, b) => a + b) / students.length;
  final avgPercent =
      students.map((s) => s.averagePercentage).reduce((a, b) => a + b) /
          students.length;

  stdout.writeln(
    'Average GPA: ${avgGpa.toStringAsFixed(2)} / ${scale.maxGpa.toStringAsFixed(1)}',
  );
  stdout.writeln('Average Percentage: ${avgPercent.toStringAsFixed(2)}%');
}
