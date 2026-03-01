import 'dart:convert';

/// Service that parses raw SQL DDL scripts and converts them into the
/// JSON schema format expected by the backend API.
///
/// Supports standard SQL dialects: T-SQL (SQL Server), MySQL, and PostgreSQL.
/// Handles `CREATE TABLE` statements, inline `PRIMARY KEY` constraints, and
/// `CONSTRAINT ... PRIMARY KEY` blocks. Output keys use PascalCase to match
/// the C# backend's JSON property naming convention.
class SqlParserService {

  /// Parses a SQL DDL [fileContent] and returns a schema map for [dbName].
  ///
  /// The parsing pipeline:
  /// 1. Strips comments, `INSERT`, `USE`, `GO`, and `SET` statements.
  /// 2. Extracts each `CREATE TABLE` block via regex.
  /// 3. Splits column definitions while respecting nested parentheses.
  /// 4. Normalizes SQL types to the subset understood by the backend.
  /// 5. Detects identity/auto-increment columns and primary keys.
  ///
  /// Throws an [Exception] if no valid `CREATE TABLE` statements are found.
  static Map<String, dynamic> parseSqlToSchemaMap(String fileContent, String dbName) {

    final tablesList = <Map<String, dynamic>>[];
    final columnsList = <Map<String, dynamic>>[];
    final pkInfoList = <Map<String, dynamic>>[];

    // Strip block comments, line comments, and non-DDL statements
    String cleanContent = fileContent.replaceAll('\r\n', '\n');
    cleanContent = cleanContent.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');
    cleanContent = cleanContent.replaceAll(RegExp(r'--.*'), '');
    cleanContent = cleanContent.replaceAll(RegExp(r'^\s*INSERT\s+INTO.*$', multiLine: true, caseSensitive: false), '');
    cleanContent = cleanContent.replaceAll(RegExp(r'^\s*USE\s+.*$', multiLine: true, caseSensitive: false), '');
    cleanContent = cleanContent.replaceAll(RegExp(r'^\s*GO\s*$', multiLine: true, caseSensitive: false), '');
    cleanContent = cleanContent.replaceAll(RegExp(r'^\s*SET\s+.*$', multiLine: true, caseSensitive: false), '');
    cleanContent = cleanContent.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '').replaceAll("'", "");

    // Match each CREATE TABLE block
    final tableRegex = RegExp(r'CREATE\s+TABLE\s+(?:(\w+)\.)?(\w+)\s*\(([\s\S]+?)\);', caseSensitive: false, multiLine: true);
    final matches = tableRegex.allMatches(cleanContent);

    if (matches.isEmpty) {
      throw Exception("No se encontraron tablas válidas.");
    }

    for (var match in matches) {
      String schema = match.group(1) ?? 'dbo';
      if (schema.toLowerCase() == 'public') schema = 'dbo';
      String tableName = match.group(2) ?? 'SinNombre';
      String rawColumns = match.group(3) ?? '';

      // PascalCase keys match the C# [JsonPropertyName] contract
      tablesList.add({
        "Schema": schema,
        "Table": tableName,
      });

      // Split column definitions, preserving nested parentheses in type declarations
      List<String> lines = _splitColumnsRespectingParentheses(rawColumns);

      for (var line in lines) {
        line = line.trim();
        if (line.isEmpty) continue;

        // Handle CONSTRAINT ... PRIMARY KEY and standalone PRIMARY KEY blocks
        if (line.toUpperCase().startsWith('CONSTRAINT') || (line.toUpperCase().startsWith('PRIMARY KEY') && line.contains('('))) {
          if (line.toUpperCase().contains('PRIMARY KEY')) {
            final pkMatch = RegExp(r'\(([^)]+)\)').firstMatch(line);
            if (pkMatch != null) {
              String pkCol = pkMatch.group(1)!.split(',')[0].trim();
              pkInfoList.add({
                "Table": tableName,
                "Column": pkCol,
              });
            }
          }
          continue;
        }

        final parts = line.split(RegExp(r'\s+'));
        if (parts.length < 2) continue;

        String colName = parts[0];
        String colType = parts[1];

        // Reconstruct type if it contains parentheses split across tokens
        if (colType.contains('(') && !colType.contains(')')) {
          for (int i = 2; i < parts.length; i++) {
            colType += parts[i];
            if (parts[i].contains(')')) break;
          }
        }

        colType = colType.replaceAll(' ', '');
        if (colType.endsWith(',')) colType = colType.substring(0, colType.length - 1);

        bool isIdentity = line.toUpperCase().contains('IDENTITY') || line.toUpperCase().contains('AUTO_INCREMENT');
        String upperType = colType.toUpperCase();

        // Normalize SQL types to the backend's supported subset
        if (upperType.startsWith('INT') || upperType == 'SERIAL') colType = 'int';
        else if (upperType == 'TEXT') colType = 'varchar(MAX)';
        else if (upperType == 'BOOL' || upperType == 'BOOLEAN') colType = 'bit';
        else if (upperType == 'DATETIME') colType = 'datetime';
        else if (upperType == 'BLOB') colType = 'varbinary(MAX)';

        columnsList.add({
          "Table": tableName,
          "Name": colName,
          "Type": colType,
          "Is_Identity": isIdentity,
        });

        // Inline PRIMARY KEY declaration (e.g. `id INT PRIMARY KEY`)
        if (line.toUpperCase().contains('PRIMARY KEY')) {
          pkInfoList.add({
            "Table": tableName,
            "Column": colName,
          });
        }
      }
    }

    return {
      "database_name": dbName,
      "Tables": tablesList,
      "Columns": columnsList,
      "Pk_Info": pkInfoList,
    };
  }

  /// Splits a raw column definition block by commas, ignoring commas that
  /// appear inside parentheses (e.g. `DECIMAL(10, 2)` or `CHECK(...)`).
  static List<String> _splitColumnsRespectingParentheses(String text) {
    List<String> result = [];
    int parenthesisLevel = 0;
    StringBuffer buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      String char = text[i];
      if (char == '(') parenthesisLevel++;
      if (char == ')') parenthesisLevel--;
      if (char == ',' && parenthesisLevel == 0) {
        result.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    if (buffer.isNotEmpty) result.add(buffer.toString());
    return result;
  }
}
