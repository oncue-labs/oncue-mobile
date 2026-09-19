abstract interface class PushDeviceTokenSource {
  Future<String?> currentDeviceToken();

  Stream<String> get tokenUpdates;
}
