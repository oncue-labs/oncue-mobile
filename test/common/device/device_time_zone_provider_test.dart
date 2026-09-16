import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncue_mobile/common/device/device_time_zone_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('oncue/device_time_zone');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('returns the device time zone from the platform channel', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'currentTimeZone');
          return 'Asia/Seoul';
        });

    final provider = MethodChannelDeviceTimeZoneProvider(channel: channel);

    expect(await provider.currentTimeZone(), 'Asia/Seoul');
  });

  test('rejects an empty platform time zone', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => '');

    final provider = MethodChannelDeviceTimeZoneProvider(channel: channel);

    expect(provider.currentTimeZone(), throwsA(isA<StateError>()));
  });
}
