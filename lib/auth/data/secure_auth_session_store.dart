import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:oncue_mobile/auth/application/auth_service.dart';
import 'package:oncue_mobile/common/auth/auth_session.dart';

abstract interface class AuthSecureStorage {
  Future<String?> read({required String key});

  Future<void> write({required String key, required String value});

  Future<void> delete({required String key});
}

final class FlutterAuthSecureStorage implements AuthSecureStorage {
  FlutterAuthSecureStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<void> delete({required String key}) => _storage.delete(key: key);

  @override
  Future<String?> read({required String key}) => _storage.read(key: key);

  @override
  Future<void> write({required String key, required String value}) {
    return _storage.write(key: key, value: value);
  }
}

final class SecureAuthSessionStore implements AuthSessionStore {
  SecureAuthSessionStore(
    this._storage, {
    this.storageKey = 'oncue.auth.session',
  });

  final AuthSecureStorage _storage;
  final String storageKey;

  @override
  Future<AuthSession?> load() async {
    final encoded = await _storage.read(key: storageKey);
    if (encoded == null || encoded.isEmpty) {
      return null;
    }
    final decoded = jsonDecode(encoded);
    if (decoded is! Map) {
      throw const FormatException('Stored auth session must be a JSON object');
    }
    return AuthSession.fromJson(Map<String, dynamic>.from(decoded));
  }

  @override
  Future<void> save(AuthSession session) {
    return _storage.write(
      key: storageKey,
      value: jsonEncode({
        'accessToken': session.accessToken,
        'expiresAt': session.expiresAt.toIso8601String(),
        'createdAt': session.createdAt.toIso8601String(),
      }),
    );
  }

  @override
  Future<void> clear() => _storage.delete(key: storageKey);
}
