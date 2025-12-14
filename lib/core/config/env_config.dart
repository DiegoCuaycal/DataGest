import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get apiUrl => dotenv.env['API_URL'] ?? 'http://localhost:5000/api';

  static int get apiTimeout => int.tryParse(dotenv.env['API_TIMEOUT'] ?? '30') ?? 30;

  static bool get isDebug => dotenv.env['DEBUG'] == 'true';

  static Future<void> init() async {
    await dotenv.load(fileName: '.env');
  }
}
