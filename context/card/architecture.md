# 카드 아키텍처

> 구성 확정 / 담당·규모 미확인. 현재 구조와 향후 개발을 구분합니다.

## 현재 시스템 구조

제품 상태·DOM·스타일은 [animation-preview.html](../../designs/final/animation-preview.html)에 함께 있다. 화면 모아보기는 `flow-viewer.js`와 빌드/캡처 스크립트로 구성한다. 별도 API 서버·도메인 서비스 레이어는 없다. Swift(`ios/FocusMate`)는 버전 3 `app-state.json`의 `cards.items[]`에 `CardSnapshot(id, issuedAt, style)`을 저장한다. `CardStyle`은 불투명 sRGB 배경과 최대 6장 `CardPhoto`(Data·치수·중심 위치·너비)를 담는다. `SnapshotCodec`은 버전 1 변환을 유지하고 독립 버전 2 DTO에서 기본 외형으로 변환하며 읽기만으로 재저장하지 않는다. 발급은 `CardIssuanceController`·`CardIssuanceView`, 꾸미기 초안·입력 잠금·되돌리기·버리기는 `CardCustomizationController`·`CardCustomizationView`가 맡는다. `ImageIOCardPhotoProcessor`는 입력 장당 8MiB 제한, 방향 반영 thumbnail 처리, alpha PNG/불투명 JPEG 인코딩과 보존 장당 1MiB·전체 6MiB 한도를 적용한다. `LocalSnapshotStore`는 load/save/backup에서 사진 디코딩·선언 치수를 검증하고 외형·사진을 원자적 쓰기 한 번으로 저장한다. `AppModel`의 `beginCardCustomization/currentCardStyle/saveCardStyle`은 현재 카드·준비 상태를 확인하고 최신 snapshot의 일치 카드 외형만 갱신한다. `PassFace`는 저장 외형의 공통 표현, `PassIdentity`는 이름·번호의 출처다. 정합성은 `AppSnapshot.validate`와 저장소 사진 검증이 판정한다. 이 context 폴더의 4개 도메인은 물리 코드 분리안이 아니다.

주요 현재 함수/경계: currentPass/loadTransitPass/syncTransitPass, renderPassIssuance, syncCardAppearance, cardStudio 편집·저장/취소 함수.

저장·자산: `next-step-prototype-pass-v1`, `focus-mate-card-style-v1`. 현재 브라우저에 저장하며 실제 교통카드 결제 API는 없다.

연계: journey는 카드 접촉 성공 상태를 소유한다. card는 ID·외형을 공급하며 여행 완료 여부나 기록 합계를 결정하지 않는다.

## 향후 네이티브와 후순위

SwiftUI 카드 발급·로컬 저장은 W01, 마이페이지는 W11, 사진·외형 편집과 버전 3 보존은 W10에서 구현했다([#15](https://github.com/rnqhstmd/focus-mate/pull/15); main 병합 전). `ProfileView`는 `PassFace(style: model.currentCardStyle)`, `PassIdentity`와 records의 누적 집계(`AppModel+Profile`의 `ProfileStats`, `RecordSection.lifetimeSummary` 위임)를 읽는다. 마이페이지 꾸미기 행은 `RootView`가 생성한 실제 편집 세션을 열고 저장/닫기 후 같은 마이페이지로 돌아온다. card 모델에는 기록 집계가 없다. 승하차 배치는 W04 대상이다. 공유·여러 카드·실제 교통카드 연동은 후순위이며 실제 iPhone 검증은 W14에서 수행한다. 상세 범위는 [MVP](../../docs/MVP.md)를 본다. W10 구현의 검증 범위와 미완료 전체 UI108건·추가 VoiceOver 경계는 [최종 검증](../../.dev/codex-feat-card-customization/reports/final-verification.md)에 구분한다.

## 주제 문서

| 주제 | 설명 |
|---|---|
| [현재 상태](../../docs/CURRENT-STATE.md) | 최신 기능과 검증 시점 |
| [화면 계약](../../docs/FLOWS.md) | 성공·취소·오류·저장 |
| [현재 VM 검사](../../scripts/prototype-edge-qa.cjs) | mock DOM·수치·상태 검증, 실제 iPhone 검증과 구분 |


## 개발 단계 연결

[개발 단계](../../docs/DEVELOPMENT-PHASES.md)에 단계 구분과 범위를 연결합니다. 웹 구현은 위의 단일 HTML이고, iOS는 W01의 발급·공통 카드, W11의 마이페이지, W10의 꾸미기·사진 보존을 구현했고 승하차 표시(W04)는 예정입니다. 도메인의 구현 근거와 미반영 항목은 [status.md](status.md)에 기록합니다.
