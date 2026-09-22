# OnCue Mobile

OnCue iOS Flutter 앱이다.

## 로컬 실행 설정

Flutter 실행에 필요한 API 주소와 OAuth 공개 클라이언트 값은
`--dart-define-from-file`로 주입한다. 로컬 파일은 Git에 커밋하지 않는다.

```bash
cp config/local.json.template config/local.json
```

`config/local.json`의 다음 값을 실제 로컬 환경에 맞게 바꾼다. TestFlight 배포는 `config/production.json.template`을 복사해 `config/production.json`을 만들고 배포용 값을 입력한다. 두 파일은 Git에 포함하지 않는다.

- `ONCUE_API_BASE_URL`: Mac의 로컬 IP와 백엔드 포트
- `ONCUE_APNS_ENVIRONMENT`: 개발 앱은 `SANDBOX`
- `ONCUE_KAKAO_NATIVE_APP_KEY`: Kakao Native App Key
- `ONCUE_X_CLIENT_ID`: X Client ID

X Client Secret이나 APNs `.p8` 개인키는 이 파일에 넣지 않는다.

실제 iPhone에서 실행할 때는 Mac과 iPhone을 같은 네트워크에 연결하고 다음을 실행한다.

```bash
flutter run \
  -d <iPhone device id> \
  --dart-define-from-file=config/local.json
```

이 방식은 터미널에 별도의 환경변수를 등록하지 않아도 된다.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
