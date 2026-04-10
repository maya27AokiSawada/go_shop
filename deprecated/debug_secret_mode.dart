// Debug script to check current secret mode status
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  final prefs = await SharedPreferences.getInstance();
  final secretMode = prefs.getBool('secret_mode') ?? false;
  print('🔍 Current secret mode: $secretMode');

  // List all stored preferences
  final keys = prefs.getKeys();
  print('🔍 All stored preferences:');
  for (final key in keys) {
    final value = prefs.get(key);
    print('  - $key: $value');
  }
}
