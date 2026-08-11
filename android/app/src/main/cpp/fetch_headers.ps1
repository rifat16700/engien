$ErrorActionPreference = "Stop"
$cppDir = $PSScriptRoot
if (-not $cppDir) { $cppDir = (Get-Location).Path }
Set-Location $cppDir

Write-Host "Fetching WebRTC C++ Headers..."
if (Test-Path -Path "temp_webrtc") { Remove-Item -Path "temp_webrtc" -Recurse -Force }
if (Test-Path -Path "include/webrtc") { Remove-Item -Path "include/webrtc" -Recurse -Force }

# Clone a known WebRTC repository that explicitly tracks the include headers
Write-Host "Cloning WebRTC source to include/webrtc..."
git clone --depth 1 https://github.com/webrtc-mirror/webrtc.git include/webrtc

Write-Host "Headers fetched successfully and placed in include/webrtc/!"
