#!/bin/bash
set -e

# Navigate to the cpp directory
CPP_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$CPP_DIR"

echo "Creating library directories..."
mkdir -p libs/webrtc libs/openssl include

echo "Downloading Google WebRTC AAR..."
# Fetching the official prebuilt WebRTC
curl -L -o webrtc.aar https://dl.google.com/dl/android/maven2/org/webrtc/google-webrtc/1.0.32006/google-webrtc-1.0.32006.aar

echo "Extracting WebRTC AAR..."
unzip -q webrtc.aar -d webrtc_extracted
mkdir -p libs/webrtc/jni
mv webrtc_extracted/jni/* libs/webrtc/jni/
rm -rf webrtc.aar webrtc_extracted

echo "Cloning official Telegram tgcalls..."
if [ -d "tgcalls" ]; then
    rm -rf tgcalls
fi
git clone --depth 1 https://github.com/TelegramMessenger/tgcalls.git

echo "Dependencies fetched successfully!"
echo "Note: WebRTC headers (include files) are heavily dependent on the specific WebRTC branch used by Telegram."
echo "If CMake complains about missing headers during compilation, you will need to clone Telegram's custom WebRTC headers into the include/ directory."
