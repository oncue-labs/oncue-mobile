import 'package:flutter_test/flutter_test.dart';
import 'package:oncue_mobile/auth/data/secure_auth_session_store.dart';
import 'package:oncue_mobile/common/auth/auth_session.dart';

void main() {
  test('saves and loads an auth session as JSON', () async {
    final storage = _FakeSecureStorage();
    final store = SecureAuthSessionStore(storage);
    final session = _session();

    await store.save(session);
    final loaded = await store.load();

    expect(loaded?.accessToken, session.accessToken);
    expect(loaded?.expiresAt, session.expiresAt);
    expect(loaded?.createdAt, session.createdAt);
    expect(storage.values, contains('oncue.auth.session'));
  });

  test('returns null when no auth session is stored', () async {
    final store = SecureAuthSessionStore(_FakeSecureStorage());

    expect(await store.load(), isNull);
  });

  test('clears the stored auth session', () async {
    final storage = _FakeSecureStorage();
    final store = SecureAuthSessionStore(storage);

    await store.save(_session());
    await store.clear();

    expect(await store.load(), isNull);
  });
}

AuthSession _session() {
  return AuthSession(
    accessToken: 'access-token',
    expiresAt: DateTime.parse('2026-09-15T10:01:00Z'),
    createdAt: DateTime.parse('2026-09-15T10:00:00Z'),
  );
}

final class _FakeSecureStorage implements AuthSecureStorage {
  final values = <String, String>{};

  @override
  Future<void> delete({required String key}) async {
    values.remove(key);
  }

  @override
  Future<String?> read({required String key}) async => values[key];

  @override
  Future<void> write({required String key, required String value}) async {
    values[key] = value;
  }
}
