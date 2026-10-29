$assetRoot = Split-Path -Parent $PSScriptRoot
$previewTemplate = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'preview.template.html') -Raw
$characterJson = @('io-explorer','brasa-mechanic','luma-botanist') | ForEach-Object { Get-Content -LiteralPath (Join-Path $assetRoot ('exports/' + $_ + '.json')) -Raw }
$assetManifest = Get-Content -LiteralPath (Join-Path $assetRoot 'manifest.json') -Raw | ConvertFrom-Json
$previewTemplate = $previewTemplate.Replace('__CHARACTER_DATA__', '[' + ($characterJson -join ',') + ']').Replace('__PALETTE_DATA__', ($assetManifest.palette | ConvertTo-Json -Compress))
[IO.File]::WriteAllText((Join-Path $assetRoot 'preview.html'), $previewTemplate, [Text.UTF8Encoding]::new($false))
