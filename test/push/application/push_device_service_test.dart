import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oncue_mobile/push/application/push_device_service.dart';
import 'package:oncue_mobile/push/data/push_device_api_client.dart';
import 'package:oncue_mobile/push/data/push_device_token_source.dart';
import 'package:oncue_mobile/push/model/push_environment.dart';

void main() {
  test(
    'registers the current token when an authenticated session is attached',
    () async {
      final tokenSource = _FakePushDeviceTokenSource(currentToken: 'token-1');
      final pushClient = _FakePushDeviceApiClient();
      final service = PushDeviceService(
        pushClient,
        tokenSource,
        environment: PushEnvironment.sandbox,
      );

      await service.attachSession('access-token');

      expect(pushClient.registered, [
        (
          deviceToken: 'token-1',
          environment: PushEnvironment.sandbox,
          accessToken: 'access-token',
        ),
      ]);
      await service.dispose();
      await tokenSource.dispose();
    },
  );

  test('re-registers when PushKit rotates the current device token', () async {
    final tokenSource = _FakePushDeviceTokenSource();
    final pushClient = _FakePushDeviceApiClient();
    final service = PushDeviceService(
      pushClient,
      tokenSource,
      environment: PushEnvironment.production,
    );

    await service.attachSession('access-token');
    tokenSource.emit('token-2');
    await Future<void>.delayed(Duration.zero);

    expect(pushClient.registered.single.deviceToken, 'token-2');
    expect(
      pushClient.registered.single.environment,
      PushEnvironment.production,
    );
    expect(pushClient.registered.single.accessToken, 'access-token');
    await service.dispose();
    await tokenSource.dispose();
  });

  test(
    'deletes the server token when the authenticated session is detached',
    () async {
      final tokenSource = _FakePushDeviceTokenSource(currentToken: 'token-1');
      final pushClient = _FakePushDeviceApiClient();
      final service = PushDeviceService(
        pushClient,
        tokenSource,
        environment: PushEnvironment.sandbox,
      );

      await service.attachSession('access-token');
      await service.detachSession('access-token');
      tokenSource.emit('token-after-logout');
      await Future<void>.delayed(Duration.zero);

      expect(pushClient.deletedAccessTokens, ['access-token']);
      expect(pushClient.registered, hasLength(1));
      await service.dispose();
      await tokenSource.dispose();
    },
  );
}

final class _FakePushDeviceApiClient implements PushDeviceApiClientContract {
  final registered =
      <
        ({String deviceToken, PushEnvironment environment, String accessToken})
      >[];
  final deletedAccessTokens = <String>[];

  @override
  Future<void> register({
    required String deviceToken,
    required PushEnvironment environment,
    required String accessToken,
  }) async {
    registered.add((
      deviceToken: deviceToken,
      environment: environment,
      accessToken: accessToken,
    ));
  }

  @override
  Future<void> delete({required String accessToken}) async {
    deletedAccessTokens.add(accessToken);
  }
}

final class _FakePushDeviceTokenSource implements PushDeviceTokenSource {
  _FakePushDeviceTokenSource({this.currentToken});

  String? currentToken;
  final _controller = StreamController<String>.broadcast();

  @override
  Future<String?> currentDeviceToken() async => currentToken;

  @override
  Stream<String> get tokenUpdates => _controller.stream;

  void emit(String token) {
    currentToken = token;
    _controller.add(token);
  }

  Future<void> dispose() => _controller.close();
}
