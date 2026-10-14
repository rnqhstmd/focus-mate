# 코드 맵: W10 카드 꾸미기

## 핵심 파일
- ios/FocusMate/PassFace.swift → 공통 기본 카드 외형·고정 장식·카드 경계
- ios/FocusMate/CardSection.swift → 카드 ID·발급 시각 저장
- ios/FocusMate/AppModel.swift → 현재 스냅샷 저장·화면 이동
- ios/FocusMate/RootView.swift → 메인 및 화면 진입
- designs/final/animation-preview.html → 웹 cardStudio의 편집·입력·취소·저장 정책

## 참조 파일
- ios/FocusMate/AppSnapshot.swift → 저장 스냅샷 정합성
- ios/FocusMate/SnapshotCodec.swift → 버전 1/2 전용 변환·버전3 외형/사진 저장
- ios/FocusMate/LocalSnapshotStore.swift → 원본 저장·복구
- ios/FocusMate/DestinationScreen.swift → 화면 경로
- ios/FocusMate/UITestBootstrap.swift → DEBUG 시드·오류 주입
- ios/FocusMateTests/CardStorageTests.swift → 카드 실제 파일 보존 시험
- ios/FocusMate/PassIdentity.swift → 공통 이름·ID

## 설정
- .claude/config.json → Node·iOS 빌드와 테스트
- ios/FocusMate.xcodeproj/project.pbxproj → iOS 앱·시험 타깃
- package.json → 웹 검증 명령

## W10 구현 추가
- ios/FocusMate/CardStyle.swift → 외형·사진·입력/보존 한도와 정합성
- ios/FocusMate/CardPhotoProcessor.swift → ImageIO thumbnail·방향·저장 인코딩·실제 사진 검증
- ios/FocusMate/CardCustomizationController.swift → 독립 초안·입력 세대·undo·저장 및 공유 안내 표현
- ios/FocusMate/CardCustomizationView.swift → native PhotosPicker·편집 조작·오류/VO 안내
- ios/FocusMate/FontCatalog.swift → 공통 서울알림 PS 이름과 등록
- ios/FocusMate/Resources/Fonts/ → main과 공유하는 동일 서울알림 폰트 자원
- ios/FocusMate/ProfileView.swift / AppModel+Profile.swift → 현재 저장 외형·실제 편집 callback, records 집계 읽기
