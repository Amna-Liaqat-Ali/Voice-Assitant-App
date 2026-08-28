import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _apiKeyStorageKey = 'gemini_api_key';
const _storage = FlutterSecureStorage();

//the user's own Gemini API key, stored encrypted on-device (OS keychain on
//iOS/macOS, Keystore-backed EncryptedSharedPreferences on Android)
Future<String?> loadApiKey() => _storage.read(key: _apiKeyStorageKey);

Future<void> saveApiKey(String key) =>
    _storage.write(key: _apiKeyStorageKey, value: key);

Future<void> clearApiKey() => _storage.delete(key: _apiKeyStorageKey);
