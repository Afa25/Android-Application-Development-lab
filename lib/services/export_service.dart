// ============================================================
//  GRADE MASTER â€” Export Service
//  Exports session results as Excel (.xlsx) and PDF
// ============================================================

import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/models.dart';

class ExportService {
  static ExportService? _instance;
  ExportService._();
  static ExportService get instance => _instance ??= ExportService._();

  
  //  Export to Excel
 
  Future<File?> exportToExcel(GradeSession session) async {
    try {
      final excel = Excel.createExcel();

      // Summary Sheet
      _buildSummarySheet(excel, session);

      //  Detailed Sheet
      _buildDetailedSheet(excel, session);

      //  Per-Subject Stats
      _buildSubjectStatsSheet(excel, session);

      final bytes = excel.encode();
      if (bytes == null) return null;

      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File(
        '${dir.path}/GradeMaster_${session.name}_$timestamp.xlsx',
      );
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      return null;
    }
  }

  void _buildSummarySheet(Excel excel, GradeSession session) {
    final sheet = excel['Summary'];
    int row = 0;

    _writeHeader(sheet, row++, ['GRADE MASTER â€” SESSION SUMMARY']);
    _writeRow(sheet, row++, ['Session Name:', session.name]);
    _writeRow(sheet, row++, ['Academic Year:', session.academicYear ?? '-']);
    _writeRow(sheet, row++, ['Semester:', session.semester ?? '-']);
    _writeRow(sheet, row++, ['Institution:', session.institution ?? '-']);
    _writeRow(sheet, row++, ['GPA Scale:', session.defaultGpaScale.label]);
    _writeRow(sheet, row++, [
      'Generated:',
      DateFormat('dd MMM yyyy HH:mm').format(DateTime.now()),
    ]);
    row++;

    _writeHeader(sheet, row++, ['Student Summary']);
    _writeRow(sheet, row++, [
      'Student Name',
      'Student ID',
      'Department',
      'Level',
      'Avg %',
      'GPA',
      'Standing',
      'Latin Honor',
      'Passed',
      'Failed',
      'Total Credits',
    ]);

    for (final s in session.students) {
      _writeRow(sheet, row++, [
        s.name,
        s.studentId,
        s.department ?? '',
        s.level ?? '',
        s.averagePercentage.toStringAsFixed(2),
        s.gpa.toStringAsFixed(3),
        s.standing.title,
        s.standing.latinHonor,
        s.passedSubjects.toString(),
        s.failedSubjects.toString(),
        s.totalCreditHours.toString(),
      ]);
    }

    row++;
    _writeHeader(sheet, row++, ['Class Statistics']);
    _writeRow(sheet, row++, [
      'Total Students:',
      session.totalStudents.toString(),
    ]);
    _writeRow(sheet, row++, [
      'Class Average GPA:',
      session.sessionAverageGpa.toStringAsFixed(3),
    ]);
    _writeRow(sheet, row++, [
      'Class Average %:',
      session.sessionAveragePercentage.toStringAsFixed(2),
    ]);
  }

  void _buildDetailedSheet(Excel excel, GradeSession session) {
    final sheet = excel['Detailed Grades'];
    int row = 0;

    // Collect all subject names
    final subjectNames = <String>{};
    for (final s in session.students) {
      for (final sub in s.subjects) {
        subjectNames.add(sub.name);
      }
    }
    final subjects = subjectNames.toList();

    // Header
    _writeRow(sheet, row++, [
      'Student Name',
      'Student ID',
      ...subjects.map((s) => '$s (%)'),
      ...subjects.map((s) => '$s (Grade)'),
    ]);

    for (final student in session.students) {
      final scores = subjects.map((sName) {
        final sub = student.subjects.where((s) => s.name == sName).firstOrNull;
        return sub?.percentage.toStringAsFixed(1) ?? '-';
      }).toList();

      final grades = subjects.map((sName) {
        final sub = student.subjects.where((s) => s.name == sName).firstOrNull;
        return sub?.grade.letter ?? '-';
      }).toList();

      _writeRow(sheet, row++, [
        student.name,
        student.studentId,
        ...scores,
        ...grades,
      ]);
    }
  }

  void _buildSubjectStatsSheet(Excel excel, GradeSession session) {
    final sheet = excel['Subject Statistics'];
    int row = 0;

    _writeHeader(sheet, row++, ['Subject Performance Statistics']);
    _writeRow(sheet, row++, [
      'Subject',
      'Code',
      'Credits',
      'Avg Score',
      'Highest',
      'Lowest',
      'Pass Rate',
    ]);

    // Gather all subjects
    final subjectMap = <String, List<Subject>>{};
    for (final student in session.students) {
      for (final sub in student.subjects) {
        subjectMap.putIfAbsent(sub.name, () => []).add(sub);
      }
    }

    for (final entry in subjectMap.entries) {
      final subs = entry.value;
      final avg =
          subs.map((s) => s.percentage).reduce((a, b) => a + b) / subs.length;
      final high =
          subs.map((s) => s.percentage).reduce((a, b) => a > b ? a : b);
      final low = subs.map((s) => s.percentage).reduce((a, b) => a < b ? a : b);
      final passed = subs.where((s) => s.grade.letter != 'F').length;
      final passRate = (passed / subs.length * 100).toStringAsFixed(1);

      _writeRow(sheet, row++, [
        entry.key,
        subs.first.code,
        subs.first.creditHours.toString(),
        avg.toStringAsFixed(2),
        high.toStringAsFixed(2),
        low.toStringAsFixed(2),
        '$passRate%',
      ]);
    }
  }

  void _writeHeader(Sheet sheet, int row, List<String> values) {
    for (int c = 0; c < values.length; c++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row),
      );
      cell.value = TextCellValue(values[c]);
    }
  }

  void _writeRow(Sheet sheet, int row, List<String> values) {
    for (int c = 0; c < values.length; c++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row),
      );
      cell.value = TextCellValue(values[c]);
    }
  }

 
  //  Export to PDF
 
  Future<File?> exportToPdf(GradeSession session) async {
    try {
      final pdf = pw.Document();
      final fmt = DateFormat('dd MMM yyyy HH:mm');

      //  Cover Page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(24),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#1a237e'),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'GRADE MASTER',
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Academic Grade Report',
                      style: const pw.TextStyle(
                        fontSize: 16,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),
              _pdfInfoRow('Session', session.name),
              _pdfInfoRow('Institution', session.institution ?? 'N/A'),
              _pdfInfoRow('Academic Year', session.academicYear ?? 'N/A'),
              _pdfInfoRow('Semester', session.semester ?? 'N/A'),
              _pdfInfoRow('GPA Scale', session.defaultGpaScale.label),
              _pdfInfoRow('Total Students', session.totalStudents.toString()),
              _pdfInfoRow(
                'Class GPA Average',
                session.sessionAverageGpa.toStringAsFixed(3),
              ),
              _pdfInfoRow('Generated', fmt.format(DateTime.now())),
              pw.SizedBox(height: 24),
              pw.Text(
                'Generated by Grade Master',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
            ],
          ),
        ),
      );

      //  Student Results Table
      const chunkSize = 25;
      final chunks = <List<Student>>[];
      for (int i = 0; i < session.students.length; i += chunkSize) {
        chunks.add(
          session.students.sublist(
            i,
            i + chunkSize > session.students.length
                ? session.students.length
                : i + chunkSize,
          ),
        );
      }

      for (final chunk in chunks) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4.landscape,
            build: (ctx) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Student Results â€” ${session.name}',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.TableHelper.fromTextArray(
                  headers: [
                    'Name',
                    'ID',
                    'Dept',
                    'Avg %',
                    'GPA',
                    'Standing',
                    'Passed',
                    'Failed',
                  ],
                  data: chunk
                      .map(
                        (s) => [
                          s.name,
                          s.studentId,
                          s.department ?? '-',
                          s.averagePercentage.toStringAsFixed(1),
                          s.gpa.toStringAsFixed(3),
                          s.standing.title,
                          s.passedSubjects.toString(),
                          s.failedSubjects.toString(),
                        ],
                      )
                      .toList(),
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFF1a237e),
                  ),
                  rowDecoration: const pw.BoxDecoration(),
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    4: pw.Alignment.center,
                    5: pw.Alignment.center,
                  },
                  cellStyle: const pw.TextStyle(fontSize: 9),
                  headerHeight: 25,
                  cellHeight: 20,
                ),
              ],
            ),
          ),
        );
      }

      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File(
        '${dir.path}/GradeMaster_${session.name}_$timestamp.pdf',
      );
      await file.writeAsBytes(await pdf.save());
      return file;
    } catch (e) {
      return null;
    }
  }

  pw.Widget _pdfInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 140,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
            ),
          ),
          pw.Text(value, style: const pw.TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  
  //  Share a file
 
  Future<void> shareFile(File file) async {
    await Share.shareXFiles([XFile(file.path)]);
  }
}
