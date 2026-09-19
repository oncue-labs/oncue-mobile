/// APNs endpoint selected by the app build, not a user-facing runtime choice.
enum PushEnvironment {
  sandbox('SANDBOX'),
  production('PRODUCTION');

  const PushEnvironment(this.wireValue);

  final String wireValue;

  static PushEnvironment fromWire(String value) {
    return switch (value.trim().toUpperCase()) {
      'SANDBOX' => PushEnvironment.sandbox,
      'PRODUCTION' => PushEnvironment.production,
      _ => throw ArgumentError.value(
        value,
        'value',
        'Unsupported push environment',
      ),
    };
  }
}
