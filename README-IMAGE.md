# 居酒屋 이미지 추가 방법

이 문서는 "오늘의 식사" 앱에 居酒屋(이자카야) 등의 음식 테마 이미지를 추가하는 방법을 설명합니다.

## 1. 이미지 준비

- 이미지는 가급적 정사각형으로 준비해주세요. (권장 크기: 210x210px 이상)
- 앱에서는 원형으로 표시되므로, 중요한 내용이 가운데에 오도록 해주세요.

## 2. 이미지를 Assets.xcassets에 추가하기

1. Xcode에서 프로젝트를 열고 Assets.xcassets 폴더를 찾습니다.
2. Assets.xcassets에 우클릭하여 "New Image Set"을 선택합니다.
3. 생성된 이미지셋의 이름을 정확히 "居酒屋"로 변경합니다.
4. 준비한 이미지를 드래그하여 1x, 2x, 3x 중 하나에 추가합니다.

## 3. 코드에서 이미지 표시하기

SearchView.swift 파일에서 이미지를 표시하려는 항목에 `useCustomImage: true` 속성을 추가합니다:

```swift
EmptyCirclePlaceholder(label: "居酒屋", useCustomImage: true)
```

이미지셋의 이름이 EmptyCirclePlaceholder의 label 속성과 정확히 일치해야 합니다.

## 4. 다른 음식 테마에도 적용하기

다른 음식 테마(ダイニングバー・バル, 創作料理 등)에도 같은 방법으로 적용할 수 있습니다:

1. 해당 이름의 이미지셋을 Assets.xcassets에 추가
2. SearchView.swift에서 해당 항목에 `useCustomImage: true` 속성 추가

## 참고사항

- 이미지 파일은 가급적 PNG 포맷을 사용하세요.
- 앱의 다크 모드를 고려하여, 이미지가 어두운 배경에서도 잘 보이도록 준비하세요.
