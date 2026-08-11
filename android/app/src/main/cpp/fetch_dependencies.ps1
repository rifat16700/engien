$ErrorActionPreference = "Stop"
$cppDir = $PSScriptRoot
if (-not $cppDir) { $cppDir = (Get-Location).Path }
Set-Location $cppDir

Write-Host "Creating library directories..."
New-Item -ItemType Directory -Force -Path libs/webrtc | Out-Null
New-Item -ItemType Directory -Force -Path libs/openssl | Out-Null
New-Item -ItemType Directory -Force -Path include | Out-Null

Write-Host "Downloading Google WebRTC AAR..."
Invoke-WebRequest -Uri "https://repo1.maven.org/maven2/io/github/webrtc-sdk/android/125.6422.06/android-125.6422.06.aar" -OutFile "webrtc.aar"

Write-Host "Extracting WebRTC AAR..."
Rename-Item -Path webrtc.aar -NewName webrtc.zip -Force
Expand-Archive -Path webrtc.zip -DestinationPath webrtc_extracted -Force
New-Item -ItemType Directory -Force -Path libs/webrtc/jni | Out-Null
Move-Item -Path webrtc_extracted/jni/* -Destination libs/webrtc/jni/ -Force
Remove-Item -Path webrtc.zip -Force
Remove-Item -Path webrtc_extracted -Recurse -Force

Write-Host "Cloning official Telegram tgcalls..."
if (Test-Path -Path "tgcalls") {
    Remove-Item -Path "tgcalls" -Recurse -Force
}
git clone --depth 1 https://github.com/TelegramMessenger/tgcalls.git

Write-Host "Dependencies fetched successfully!"
