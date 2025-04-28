#!/bin/bash

# iOS 18.4.1 디스크 이미지 다운로드 스크립트

echo "iOS 18.4.1 개발자 디스크 이미지 다운로드 시작..."
mkdir -p iOS_18.4.1_DeviceSupport

# 개발자 디스크 이미지 파일 다운로드 - doronz88/DeveloperDiskImage 저장소에서
echo "DeveloperDiskImage.dmg 다운로드 중..."
curl -L "https://github.com/doronz88/DeveloperDiskImage/raw/main/DeveloperDiskImages/18.4.1/DeveloperDiskImage.dmg" -o iOS_18.4.1_DeviceSupport/DeveloperDiskImage.dmg

echo "DeveloperDiskImage.dmg.signature 다운로드 중..."
curl -L "https://github.com/doronz88/DeveloperDiskImage/raw/main/DeveloperDiskImages/18.4.1/DeveloperDiskImage.dmg.signature" -o iOS_18.4.1_DeviceSupport/DeveloperDiskImage.dmg.signature

# 다운로드 파일 확인
if [ -f "iOS_18.4.1_DeviceSupport/DeveloperDiskImage.dmg" ] && [ -f "iOS_18.4.1_DeviceSupport/DeveloperDiskImage.dmg.signature" ]; then
    echo "다운로드 완료. 이제 Xcode에 설치합니다..."
    
    # Xcode에 설치
    XCODE_PATH="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/DeviceSupport/18.4.1"
    
    echo "Xcode 디스크 이미지 디렉토리 생성 중 (sudo 필요)..."
    sudo mkdir -p "$XCODE_PATH"
    
    echo "디스크 이미지 파일 복사 중..."
    sudo cp iOS_18.4.1_DeviceSupport/DeveloperDiskImage.dmg "$XCODE_PATH/"
    sudo cp iOS_18.4.1_DeviceSupport/DeveloperDiskImage.dmg.signature "$XCODE_PATH/"
    
    echo "권한 설정 중..."
    sudo chmod -R 755 "$XCODE_PATH"
    
    echo "iOS 18.4.1 개발자 디스크 이미지 설치가 완료되었습니다."
    echo "이제 iPhone을 다시 연결한 후 Xcode에서 실행을 시도해보세요."
else
    echo "다운로드 실패. GitHub 저장소에서 필요한 파일을 찾을 수 없습니다."
    echo "다른 저장소에서 iOS 18.4.1 개발자 디스크 이미지를 찾아보세요."
fi 