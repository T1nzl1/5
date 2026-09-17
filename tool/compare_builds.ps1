param(
  [string]$BaseHref = "/libraryden/",
  [Parameter(Mandatory=$true)][string]$ApiBaseUrl
)
$ErrorActionPreference = "Stop"
Remove-Item build/compare -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force build/compare/js, build/compare/wasm | Out-Null

flutter build web --release --base-href $BaseHref --dart-define="API_BASE_URL=$ApiBaseUrl"
Copy-Item build/web/* build/compare/js -Recurse -Force
$js = (Get-ChildItem build/compare/js -Recurse -File | Measure-Object Length -Sum).Sum

flutter build web --release --wasm --base-href $BaseHref --dart-define="API_BASE_URL=$ApiBaseUrl"
Copy-Item build/web/* build/compare/wasm -Recurse -Force
$wasm = (Get-ChildItem build/compare/wasm -Recurse -File | Measure-Object Length -Sum).Sum

"variant,size_bytes,size_mb" | Set-Content build/compare/build_sizes.csv
"javascript,$js,$([math]::Round($js/1MB,2))" | Add-Content build/compare/build_sizes.csv
"wasm,$wasm,$([math]::Round($wasm/1MB,2))" | Add-Content build/compare/build_sizes.csv
Get-Content build/compare/build_sizes.csv
Write-Host "Время первой загрузки измерь в Chrome DevTools > Network (Disable cache) и внеси в отчет."
