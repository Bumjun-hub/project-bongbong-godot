$ErrorActionPreference = 'Stop'
$compilerPath = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (-not (Test-Path -LiteralPath $compilerPath)) {
    $compilerPath = Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\csc.exe'
}
if (-not (Test-Path -LiteralPath $compilerPath)) {
    throw 'The Windows .NET Framework C# compiler is required to build WindowBounds.'
}
$outputDirectory = Join-Path $PSScriptRoot 'bin'
New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
$outputPath = Join-Path $outputDirectory 'Bongbong.WindowBounds.exe'
$sourcePath = Join-Path $PSScriptRoot 'WindowBounds.cs'
$manifestPath = Join-Path $PSScriptRoot 'WindowBounds.manifest'
& $compilerPath /nologo /optimize+ /target:winexe /platform:anycpu "/out:$outputPath" "/win32manifest:$manifestPath" $sourcePath
if ($LASTEXITCODE -ne 0) { throw "WindowBounds build failed ($LASTEXITCODE)." }
Write-Output $outputPath
