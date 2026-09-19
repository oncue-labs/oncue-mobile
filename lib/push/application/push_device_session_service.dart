abstract interface class PushDeviceSessionService {
  Future<void> attachSession(String accessToken);

  Future<void> detachSession(String accessToken);
}
