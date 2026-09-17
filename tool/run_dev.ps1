param([string]$ApiBaseUrl = "http://localhost:8080/api")
flutter run -d chrome --web-port=5555 --dart-define="API_BASE_URL=$ApiBaseUrl"
