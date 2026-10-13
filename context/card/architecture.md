# 카드 아키텍처

> 구성 확정 / 담당·규모 미확인. 현재 구조와 향후 개발을 구분합니다.

## 현재 시스템 구조

제품 상태·DOM·스타일은 [animation-preview.html](../../designs/final/animation-preview.html)에 함께 있다. 화면 모아보기는 `flow-viewer.js`와 빌드/캡처 스크립트로 구성한다. 별도 API 서버·도메인 서비스 레이어는 없다. Swift는 Phase 1 앱 기반(`ios/FocusMate`: 진입 분기·기본 화면 왕복·`app-state.json` 버전 1 저장)만 있고 이 도메인의 네이티브 기능은 아직 없다. 이 context 폴더의 4개 도메인은 물리 코드 분리안이 아니다.

주요 현재 함수/경계: currentPass/loadTransitPass/syncTransitPass, renderPassIssuance, syncCardAppearance, cardStudio 편집·저장/취소 함수.

저장·자산: `next-step-prototype-pass-v1`, `focus-mate-card-style-v1`. 현재 브라우저에 저장하며 실제 교통카드 결제 API는 없다.

연계: journey는 카드 접촉 성공 상태를 소유한다. card는 ID·외형을 공급하며 여행 완료 여부나 기록 합계를 결정하지 않는다.

## 향후 네이티브와 후순위

SwiftUI 공통 카드 뷰·사진 가져오기·로컬 카드 저장은 iOS MVP 예정. 공유·여러 카드·실제 교통카드 연동은 후순위. 상세 범위는 [MVP](../../docs/MVP.md)에 있다. 새로운 계층·파일·API를 이미 구현된 것으로 표시하지 않는다.

## 주제 문서

| 주제 | 설명 |
|---|---|
| [현재 상태](../../docs/CURRENT-STATE.md) | 최신 기능과 검증 시점 |
| [화면 계약](../../docs/FLOWS.md) | 성공·취소·오류·저장 |
| [현재 VM 검사](../../scripts/prototype-edge-qa.cjs) | mock DOM·수치·상태 검증, 실제 iPhone 검증과 구분 |


## 개발 단계 연결

[개발 단계](../../docs/DEVELOPMENT-PHASES.md)에 단계 구분과 범위를 연결합니다. 웹 구현은 위의 단일 HTML이고, iOS는 Phase 1 앱 기반만 있으며 이 도메인의 네이티브 기능은 아직 없습니다. 도메인의 구현 근거와 미반영 항목은 [status.md](status.md)에 기록합니다.
