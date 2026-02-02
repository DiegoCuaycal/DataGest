import 'dart:convert';

class SqlParserService {
  
  static Map<String, dynamic> parseSqlToSchemaMap(String fileContent, String dbName) {
    
    final tablesList = <Map<String, dynamic>>[];
    final columnsList = <Map<String, dynamic>>[];
    final pkInfoList = <Map<String, dynamic>>[];

    // 1. LIMPIEZA
    String cleanContent = fileContent.replaceAll('\r\n', '\n');
    cleanContent = cleanContent.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), ''); 
    cleanContent = cleanContent.replaceAll(RegExp(r'--.*'), ''); 
    cleanContent = cleanContent.replaceAll(RegExp(r'^\s*INSERT\s+INTO.*$', multiLine: true, caseSensitive: false), '');
    cleanContent = cleanContent.replaceAll(RegExp(r'^\s*USE\s+.*$', multiLine: true, caseSensitive: false), '');
    cleanContent = cleanContent.replaceAll(RegExp(r'^\s*GO\s*$', multiLine: true, caseSensitive: false), '');
    cleanContent = cleanContent.replaceAll(RegExp(r'^\s*SET\s+.*$', multiLine: true, caseSensitive: false), '');
    cleanContent = cleanContent.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '').replaceAll("'", "");

    // 2. DETECCIÓN DE TABLAS
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

      // --- CAMBIO CLAVE 1: Mayúsculas (PascalCase) para coincidir con C# ---
      tablesList.add({
        "Schema": schema, // Antes "schema"
        "Table": tableName // Antes "table"
      });

      // 3. DETECCIÓN DE COLUMNAS
      List<String> lines = _splitColumnsRespectingParentheses(rawColumns);

      for (var line in lines) {
        line = line.trim();
        if (line.isEmpty) continue;

        if (line.toUpperCase().startsWith('CONSTRAINT') || (line.toUpperCase().startsWith('PRIMARY KEY') && line.contains('('))) {
             if (line.toUpperCase().contains('PRIMARY KEY')) {
                final pkMatch = RegExp(r'\(([^)]+)\)').firstMatch(line);
                if (pkMatch != null) {
                    String pkCol = pkMatch.group(1)!.split(',')[0].trim(); 
                    // --- CAMBIO CLAVE 2 ---
                    pkInfoList.add({
                        "Table": tableName, // Mayúscula
                        "Column": pkCol     // Mayúscula
                    });
                }
            }
            continue;
        }

        final parts = line.split(RegExp(r'\s+'));
        if (parts.length < 2) continue;

        String colName = parts[0];
        String colType = parts[1]; 

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

        if (upperType.startsWith('INT') || upperType == 'SERIAL') colType = 'int';
        else if (upperType == 'TEXT') colType = 'varchar(MAX)';
        else if (upperType == 'BOOL' || upperType == 'BOOLEAN') colType = 'bit';
        else if (upperType == 'DATETIME') colType = 'datetime';
        else if (upperType == 'BLOB') colType = 'varbinary(MAX)';

        // --- CAMBIO CLAVE 3 ---
        columnsList.add({
          "Table": tableName,     // Mayúscula
          "Name": colName,        // Mayúscula
          "Type": colType,        // Mayúscula
          "Is_Identity": isIdentity, // Mayúscula 'Is' y mayúscula 'Identity'
        });

        if (line.toUpperCase().contains('PRIMARY KEY')) {
             pkInfoList.add({
                 "Table": tableName, // Mayúscula
                 "Column": colName   // Mayúscula
             });
        }
      }
    }

    // =========================================================
    // 🔑 ESTRUCTURA FINAL (PASCAL CASE EXACTO)
    // =========================================================
    return {
      "database_name": dbName, // Este se queda así por [JsonPropertyName("database_name")]
      "Tables": tablesList,    // Mayúscula T
      "Columns": columnsList,  // Mayúscula C
      "Pk_Info": pkInfoList,   // Mayúscula P
    };
  }

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