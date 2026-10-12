# Phase 2 코드 맵

## 핵심 (5)
- ios/FocusMate/AppSnapshot.swift — 현재 카드 발급 bool·정류장 값과 진입 분기
- ios/FocusMate/LocalSnapshotStore.swift — version1 JSON·원본 보호·atomic save
- ios/FocusMate/AppModel.swift — 단일 소유·성공 후 상태 확정·기본 탐색
- ios/FocusMate/RootView.swift — 기존 기본 진입/네 목적지 화면
- ios/FocusMate/UITestBootstrap.swift — DEBUG UUID 시험 경로와 seed·실패 주입

## 참조 (7)
- designs/final/animation-preview.html — 승인 준비·승차 제품 동작과 자산 경로
- docs/FLOWS.md — 접촉 checkpoint·취소·인식 연출 계약
- docs/MVP.md — 제품 범위와 실제 지도·타이머·사진·기록의 제외 경계
- docs/DEVELOPMENT-PHASES.md — Phase2~6 구분
- docs/PHASE-1-FOUNDATION.md — 기존 기반의 검증·유예 경계
- context/card/ — 카드 용어·아키텍처와 iOS 요구사항 부분 연결
- context/journey/ — 준비·승차 용어·아키텍처와 후속 타이머/지도 요구사항

## 설정·러너 (3)
- .claude/config.json — standard 및 node/ios-swiftui build/test/focused 명령
- ios/FocusMate.xcodeproj — iOS17 작업 기준, 공유 scheme와 동기화 source/test 그룹
- scripts/check-ios.py — 설치 iPhone Simulator 선택; 기존 focused0건 제한은 실제 실행 수 검증으로 보완해야 함
