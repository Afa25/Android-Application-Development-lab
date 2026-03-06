// ============================================================
//  GRADE MASTER - Excel Import Service
//  Parses .xlsx files and returns Student objects
// ============================================================

import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:xml/xml.dart';
import '../models/models.dart';

class ExcelImportResult {
  final List<Student> students;
  final List<String> warnings;
  final List<String> errors;
  final String? fileName;

  const ExcelImportResult({
    required this.students,
    this.warnings = const [],
    this.errors = const [],
    this.fileName,
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
}

class ExcelImportService {
  static ExcelImportService? _instance;
  ExcelImportService._();
  static ExcelImportService get instance =>
      _instance ??= ExcelImportService._();

  Future<File?> pickExcelFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return null;
    final path = result.files.single.path;
    if (path == null) return null;
    return File(path);
  }

  Future<List<File>> pickExcelFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      allowMultiple: true,
    );
    if (result == null || result.files.isEmpty) return const [];
    final files = <File>[];
    for (final item in result.files) {
      final path = item.path;
      if (path == null) continue;
      files.add(File(path));
    }
    return files;
  }

  Future<ExcelImportResult> parseExcelFile(
    File file,
    GpaScale gpaScale, {
    ExcelMapping? mapping,
  }) async {
    final m = mapping ?? const ExcelMapping();
    final fileName = _fileNameOnly(file.path);
    if (_isExcelTempFile(fileName)) {
      return ExcelImportResult(
        students: const [],
        errors: const [
          'This is a temporary Excel file, not the real data file. Please select the main file name that does not start with "~\$".',
        ],
        fileName: fileName,
      );
    }

    try {
      final rawBytes = await file.readAsBytes();
      final bytes = _normalizeWorkbookRelationTargets(rawBytes);
      final excel = Excel.decodeBytes(bytes);
      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName];

      if (sheet == null) {
        return ExcelImportResult(
          students: const [],
          errors: const [
            'We could not read the spreadsheet sheet. Please confirm the file is a valid Excel file.',
          ],
          fileName: fileName,
        );
      }

      final rows = sheet.rows;
      
      if (rows.isEmpty) {
        return ExcelImportResult(
          students: const [],
          errors: const [
            'The file appears to be empty. Please add headers and student scores, then try again.',
          ],
          fileName: fileName,
        );
      }

      final rowsResult = _parseByOrientation(
        rows: rows,
        mapping: m,
        gpaScale: gpaScale,
        orientation: ExcelOrientation.studentsInRows,
        fileName: fileName,
      );
      final columnsResult = _parseByOrientation(
        rows: rows,
        mapping: m,
        gpaScale: gpaScale,
        orientation: ExcelOrientation.studentsInColumns,
        fileName: fileName,
      );

      final selected = _selectBest(rowsResult, columnsResult);
      if (selected.students.isEmpty) {
        final diagnostics = <String>[
          'We could not detect a valid student table in this file.',
          '',
          'Expected format:',
          '• Column A: Student Name',
          '• Column B: Student ID', 
          '• Column C: Department',
          '• Column D: Level/Year',
          '• Columns E+: Subject scores',
          'First row should contain headers.',
          '',
        ];
        
        if (rows.isNotEmpty && rows[0].isNotEmpty) {
          diagnostics.add('Your file headers: ${rows[0].map((d) => "\"${d?.value ?? "NULL"}\"").join(", ")}');
          diagnostics.add('');
        }
        
        diagnostics.addAll(rowsResult.warnings);
        diagnostics.addAll(columnsResult.warnings);
        
        return ExcelImportResult(
          students: const [],
          errors: [diagnostics[0]],
          warnings: diagnostics.sublist(1),
          fileName: fileName,
        );
      }

      final detectedLayout = selected == rowsResult
          ? 'students in rows'
          : 'students in columns';
      return ExcelImportResult(
        students: selected.students,
        warnings: [
          'Layout detected automatically: $detectedLayout.',
          ...selected.warnings,
        ],
        fileName: fileName,
      );
    } catch (e) {
      return ExcelImportResult(
        students: const [],
        errors: [_friendlyParseMessage(e)],
        warnings: ['Technical details: $e'],
        fileName: fileName,
      );
    }
  }

  ExcelImportResult _parseByOrientation({
    required List<List<Data?>> rows,
    required ExcelMapping mapping,
    required GpaScale gpaScale,
    required ExcelOrientation orientation,
    required String fileName,
  }) {
    final students = <Student>[];
    final warnings = <String>[];
    switch (orientation) {
      case ExcelOrientation.studentsInRows:
        _parseStudentsInRows(rows, mapping, gpaScale, students, warnings);
        break;
      case ExcelOrientation.studentsInColumns:
        _parseStudentsInColumns(rows, mapping, gpaScale, students, warnings);
        break;
    }
    return ExcelImportResult(
      students: students,
      warnings: warnings,
      fileName: fileName,
    );
  }

  ExcelImportResult _selectBest(
    ExcelImportResult rowsResult,
    ExcelImportResult columnsResult,
  ) {
    final rowsScore = _score(rowsResult);
    final columnsScore = _score(columnsResult);
    if (rowsScore == columnsScore) return rowsResult;
    return rowsScore > columnsScore ? rowsResult : columnsResult;
  }

  int _score(ExcelImportResult result) {
    if (result.students.isEmpty) return -1;
    final subjectCount = result.students.fold<int>(
      0,
      (sum, s) => sum + s.subjects.length,
    );
    return (result.students.length * 1000) + subjectCount;
  }

  String _fileNameOnly(String path) {
    final parts = path.split(RegExp(r'[\\/]'));
    if (parts.isEmpty) return path;
    return parts.last;
  }

  bool _isExcelTempFile(String fileName) => fileName.startsWith(r'~$');

  String _friendlyParseMessage(Object error) {
    final raw = error.toString();
    if (raw.contains('Null check operator used on a null value')) {
      return 'We could not read this workbook. If the file is open in Excel, close it and upload the real file (not a temporary file like "~\$..."). You can also re-save it as a new .xlsx file and try again.';
    }
    return 'We could not read this file. Please confirm it is an Excel file (.xlsx or .xls) and not currently corrupted.';
  }

  List<int> _normalizeWorkbookRelationTargets(List<int> bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes, verify: false);
      final relsFile = archive.findFile('xl/_rels/workbook.xml.rels');
      if (relsFile == null) return bytes;

      final relsContent = _archiveContentToBytes(relsFile.content);
      if (relsContent.isEmpty) return bytes;

      final xml = XmlDocument.parse(utf8.decode(relsContent));
      var changed = false;

      for (final rel in xml.findAllElements('Relationship')) {
        final target = rel.getAttribute('Target');
        if (target == null || target.isEmpty) continue;

        var normalized = target;
        if (normalized.startsWith('/xl/')) {
          normalized = normalized.substring(4);
        } else if (normalized.startsWith('/')) {
          normalized = normalized.substring(1);
        }

        if (normalized != target) {
          rel.setAttribute('Target', normalized);
          changed = true;
        }
      }

      if (!changed) return bytes;

      final patchedRels = utf8.encode(xml.toXmlString());
      final rebuilt = Archive();
      for (final file in archive.files) {
        if (file.name == 'xl/_rels/workbook.xml.rels') {
          rebuilt.addFile(
            ArchiveFile(
              file.name,
              patchedRels.length,
              patchedRels,
            ),
          );
          continue;
        }

        final fileBytes = _archiveContentToBytes(file.content);
        rebuilt.addFile(ArchiveFile(file.name, fileBytes.length, fileBytes));
      }

      return ZipEncoder().encode(rebuilt) ?? bytes;
    } catch (_) {
      return bytes;
    }
  }

  List<int> _archiveContentToBytes(dynamic content) {
    if (content is List<int>) return content;
    if (content is Uint8List) return content;
    return const [];
  }

  void _parseStudentsInRows(
    List<List<Data?>> rows,
    ExcelMapping m,
    GpaScale gpaScale,
    List<Student> students,
    List<String> warnings,
  ) {
    if (m.headerRow >= rows.length) {
      warnings.add('Header row ${m.headerRow} is outside the sheet range.');
      return;
    }

    final header = rows[m.headerRow];
    final subjectHeaders = <String>[];
    for (int c = m.firstSubjectCol; c < header.length; c++) {
      final h = _cellStr(header, c)?.trim() ?? '';
      if (h.isEmpty) break;
      subjectHeaders.add(h);
    }

    if (subjectHeaders.isEmpty) {
      warnings.add(
        'No subject columns found starting at column ${m.firstSubjectCol}.',
      );
      return;
    }

    for (int r = m.headerRow + 1; r < rows.length; r++) {
      final row = rows[r];
      final name = _cellStr(row, m.nameCol)?.trim();
      if (name == null || name.isEmpty) continue;

      final studentId = _cellStr(row, m.studentIdCol)?.trim() ?? 'STU$r';
      final department = _cellStr(row, m.departmentCol)?.trim();
      final level = _cellStr(row, m.levelCol)?.trim();

      var emptyFieldsCount = 0;
      final subjects = <Subject>[];

      for (int i = 0; i < subjectHeaders.length; i++) {
        final parsed = _parseSubjectHeader(subjectHeaders[i], i + 1);
        final score = _cellDouble(row, m.firstSubjectCol + i);
        if (score == null) emptyFieldsCount++;

        subjects.add(
          Subject(
            name: parsed.name,
            code: parsed.code,
            creditHours: parsed.creditHours,
            score: score ?? 0.0,
            maxScore: 100.0,
          ),
        );
      }

      students.add(
        Student(
          name: name,
          studentId: studentId,
          department: department,
          level: level,
          subjects: subjects,
          gpaScale: gpaScale,
          emptyFieldsCount: emptyFieldsCount,
        ),
      );
    }
  }

  void _parseStudentsInColumns(
    List<List<Data?>> rows,
    ExcelMapping m,
    GpaScale gpaScale,
    List<Student> students,
    List<String> warnings,
  ) {
    if (m.headerRow >= rows.length) {
      warnings.add('Header row ${m.headerRow} is outside the sheet range.');
      return;
    }

    final header = rows[m.headerRow];
    final studentColumns = <int>[];
    final studentNames = <String>[];

    for (int c = m.firstSubjectCol; c < header.length; c++) {
      final studentName = _cellStr(header, c)?.trim() ?? '';
      if (studentName.isEmpty) break;
      studentColumns.add(c);
      studentNames.add(studentName);
    }

    if (studentNames.isEmpty) {
      warnings.add(
        'No student columns found on header row ${m.headerRow} starting at column ${m.firstSubjectCol}.',
      );
      return;
    }

    final subjectRows = <int>[];
    final subjectHeaders = <String>[];
    for (int r = m.headerRow + 1; r < rows.length; r++) {
      final subjectHeader = _cellStr(rows[r], m.nameCol)?.trim() ?? '';
      if (subjectHeader.isEmpty) continue;
      subjectRows.add(r);
      subjectHeaders.add(subjectHeader);
    }

    if (subjectHeaders.isEmpty) {
      warnings.add(
        'No subject rows found in column ${m.nameCol} below header row ${m.headerRow}.',
      );
      return;
    }

    for (int i = 0; i < studentNames.length; i++) {
      final col = studentColumns[i];
      var emptyFieldsCount = 0;
      final subjects = <Subject>[];

      for (int j = 0; j < subjectRows.length; j++) {
        final parsed = _parseSubjectHeader(subjectHeaders[j], j + 1);
        final score = _cellDouble(rows[subjectRows[j]], col);
        if (score == null) emptyFieldsCount++;

        subjects.add(
          Subject(
            name: parsed.name,
            code: parsed.code,
            creditHours: parsed.creditHours,
            score: score ?? 0.0,
            maxScore: 100.0,
          ),
        );
      }

      students.add(
        Student(
          name: studentNames[i],
          studentId: 'STU${i + 1}',
          subjects: subjects,
          gpaScale: gpaScale,
          emptyFieldsCount: emptyFieldsCount,
        ),
      );
    }
  }

  ({String code, String name, int creditHours}) _parseSubjectHeader(
    String raw,
    int index,
  ) {
    final parts = raw.split('|');
    if (parts.length >= 3) {
      return (
        code: parts[0].trim(),
        name: parts[1].trim(),
        creditHours: int.tryParse(parts[2].trim()) ?? 3,
      );
    }
    if (parts.length == 2) {
      return (code: parts[0].trim(), name: parts[1].trim(), creditHours: 3);
    }
    return (code: 'SUB$index', name: raw.trim(), creditHours: 3);
  }

  String? _cellStr(List<Data?> row, int col) {
    if (col >= row.length) return null;
    final val = row[col]?.value;
    if (val == null) return null;
    final s = val.toString().trim();
    return s.isEmpty ? null : s;
  }

  double? _cellDouble(List<Data?> row, int col) {
    if (col >= row.length) return null;
    final val = row[col]?.value;
    if (val == null) return null;
    return double.tryParse(val.toString().trim());
  }

  List<int> generateTemplate({
    required List<String> subjectColumns,
    int sampleRows = 5,
  }) {
    final excel = Excel.createExcel();
    final sheet = excel['Students'];

    final headers = [
      'Student Name',
      'Student ID',
      'Department',
      'Level/Year',
      ...subjectColumns,
    ];

    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
    }

    for (int r = 1; r <= sampleRows; r++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r))
          .value = TextCellValue(
        'Student $r',
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: r))
          .value = TextCellValue(
        'STU${1000 + r}',
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: r))
          .value = TextCellValue(
        'Computer Science',
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: r))
          .value = TextCellValue(
        'Year 1',
      );
      for (int c = 4; c < headers.length; c++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r))
            .value = const DoubleCellValue(
          75.0,
        );
      }
    }

    return excel.encode() ?? [];
  }
}
