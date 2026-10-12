# 기록 아키텍처

> 구성 확정 / 담당·규모 미확인. 현재 구조와 향후 개발을 구분합니다.

## 현재 시스템 구조

제품 상태·DOM·스타일은 [animation-preview.html](../../designs/final/animation-preview.html)에 함께 있다. 화면 모아보기는 `flow-viewer.js`와 빌드/캡처 스크립트로 구성한다. 현재 별도 API 서버·도메인 서비스 레이어·Swift 소스는 확인되지 않았다. 이 context 폴더의 4개 도메인은 물리 코드 분리안이 아니다.

주요 현재 함수/경계: recordJourney/loadRecords/persistRecords, renderRecords, renderAnalytics, saveSummaryMemo 및 postMemo 함수.

저장·자산: `next-step-prototype-records-v1`. 완료·메모는 로컬 저장이고 현재 서버나 계정이 없다.

연계: journey의 하차 성공을 입력으로 받는다. 카드 외형이나 진행 타이머를 변경하지 않으며 완료 기록에 있는 태그/시간으로 분석한다.

## 향후 네이티브와 후순위

iOS 로컬 완료/메모 모델·같은 집계 정책은 MVP 예정. 계정·클라우드 동기화·공유·백업은 후순위. 상세 범위는 [MVP](../../docs/MVP.md)에 있다. 새로운 계층·파일·API를 이미 구현된 것으로 표시하지 않는다.

## 주제 문서

| 주제 | 설명 |
|---|---|
| [현재 상태](../../docs/CURRENT-STATE.md) | 최신 기능과 검증 시점 |
| [화면 계약](../../docs/FLOWS.md) | 성공·취소·오류·저장 |
| [현재 VM 검사](../../scripts/prototype-edge-qa.cjs) | mock DOM·수치·상태 검증, 실제 iPhone 검증과 구분 |


## 개발 단계 연결

[개발 단계](../../docs/DEVELOPMENT-PHASES.md)에 단계 구분과 범위를 연결합니다. 현재 구조는 위의 단일 HTML이며 Swift 소스는 아직 존재하지 않습니다. 도메인의 구현 근거와 미반영 항목은 [status.md](status.md)에 기록합니다.
