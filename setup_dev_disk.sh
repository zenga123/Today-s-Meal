#!/bin/bash

# 이 스크립트는 iOS 18.4.1 디스크 이미지를 Xcode에 연결하는 스크립트입니다

# 변수 설정
SOURCE_PATH="$HOME/Library/Developer/Xcode/iOS DeviceSupport/iPhone15,2 18.4.1 (22E252)"
TARGET_DIR="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/DeviceSupport/18.4.1"

# 1단계: 디렉토리 생성 시도 (sudo 필요)
echo "Creating target directory (requires sudo)..."
sudo mkdir -p "$TARGET_DIR"

if [ ! -d "$TARGET_DIR" ]; then
    echo "Failed to create target directory. Aborting."
    exit 1
fi

# 2단계: 필요한 파일 복사 (sudo 필요)
echo "Copying DeveloperDiskImage.dmg and signature files..."
sudo cp "$SOURCE_PATH/DeveloperDiskImage.dmg" "$TARGET_DIR/"
sudo cp "$SOURCE_PATH/DeveloperDiskImage.dmg.signature" "$TARGET_DIR/"

# 3단계: 심볼릭 링크 생성
echo "Creating symbolic link for Symbols..."
sudo ln -sf "$SOURCE_PATH" "$TARGET_DIR/Symbols"

# 4단계: 권한 설정
echo "Setting permissions..."
sudo chmod -R 755 "$TARGET_DIR"

echo "Done. Please reconnect your device and try again." 