import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncue_mobile/push/data/method_channel_push_device_token_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('reads the current native PushKit token', () async {
    const channel = MethodChannel(
      MethodChannelPushDeviceTokenSource.channelName,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'currentVoipPushToken');
          return 'token-1';
        });
    final source = MethodChannelPushDeviceTokenSource(channel: channel);

    expect(await source.currentDeviceToken(), 'token-1');

    await source.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('publishes native token updates', () async {
    const channel = MethodChannel(
      MethodChannelPushDeviceTokenSource.channelName,
    );
    final source = MethodChannelPushDeviceTokenSource(channel: channel);

    final tokenFuture = source.tokenUpdates.first;
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          channel.name,
          const StandardMethodCodec().encodeMethodCall(
            const MethodCall('onPushTokenUpdated', 'token-2'),
          ),
          (_) {},
        );

    expect(await tokenFuture, 'token-2');
    await source.dispose();
  });
}
