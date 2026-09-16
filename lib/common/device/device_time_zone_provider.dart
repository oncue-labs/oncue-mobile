import 'package:flutter/services.dart';

abstract interface class DeviceTimeZoneProvider {
  Future<String> currentTimeZone();
}

final class MethodChannelDeviceTimeZoneProvider
    implements DeviceTimeZoneProvider {
  const MethodChannelDeviceTimeZoneProvider({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  static const channelName = 'oncue/device_time_zone';
  static const currentTimeZoneMethod = 'currentTimeZone';

  final MethodChannel _channel;

  @override
  Future<String> currentTimeZone() async {
    final timeZone = await _channel.invokeMethod<String>(currentTimeZoneMethod);
    if (timeZone == null || timeZone.isEmpty) {
      throw StateError('The device time zone was not provided');
    }
    return timeZone;
  }
}
