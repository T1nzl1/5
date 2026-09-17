param(
  [string]$BaseHref = "/libraryden/",
  [Parameter(Mandatory=$true)][string]$ApiBaseUrl
)
flutter build web --release --base-href $BaseHref --dart-define="API_BASE_URL=$ApiBaseUrl"
Copy-Item build/web/index.html build/web/404.html -Force
Write-Host "Release готов: build/web. 404.html создан для прямых ссылок GitHub Pages."
