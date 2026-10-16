# 기록 아키텍처

> 구성 확정 / 담당·규모 미확인. 현재 구조와 향후 개발을 구분합니다.

## 현재 시스템 구조

웹 제품 상태·DOM·스타일은 [animation-preview.html](../../designs/final/animation-preview.html)에 함께 있다. 화면 모아보기는 `flow-viewer.js`와 빌드/캡처 스크립트로 구성한다. 별도 API 서버·도메인 서비스 레이어는 없다. 이 context 폴더의 4개 도메인은 물리 코드 분리안이 아니다.

웹의 주요 함수/경계: recordJourney/loadRecords/persistRecords, renderRecords, renderAnalytics, saveSummaryMemo 및 postMemo 함수.

웹 저장 키는 `next-step-prototype-records-v1`이다. 완료·메모는 로컬 저장이고 현재 서버나 계정이 없다.

## iOS W08 완료·메모 저장 모델

`ios/FocusMate/RecordSection.swift`의 `RecordSnapshot`은 완료 당시의 여행 정보와 연결 메모를 보관한다. `RecordSection`은 하차 성공(`alighted`)만 기록하고 진행·포기·예시 입력을 제외한다. 같은 여행 ID의 재요청은 기존 기록을 유지한다. 완료 시각은 UTC로 저장하고, 일별 집계에 쓸 `date`는 완료 당시 전달된 시간대로 생성한다. 복원할 때 날짜를 다시 계산하지 않는다. 기록은 완료 시각의 최신순으로 정렬하며 일별 횟수·분 합계와 전체 누적 횟수·분 합계(`lifetimeSummary`, W11 마이페이지가 읽음)를 제공한다. 누적 집계도 기록이 하나라도 유효하지 않으면 일부만 합산하지 않고 실패한다.

`AppModel.recordCompletion`과 `AppModel.updateRecordMemo`는 기존 `LocalSnapshotStore`를 통해 저장한다. 메모는 앞뒤 공백·개행을 제거하고 Unicode scalar를 분할하지 않는 범위에서 UTF-16 200단위까지 저장한다. 빈 메모로 수정하면 메모를 삭제한다. 파일 저장에 성공한 뒤에만 메모리 상태를 갱신하므로 쓰기 실패 시 기존 기록·메모·화면 경로와 파일 원본을 유지한다.

`SnapshotCodec`은 `app-state.json`의 버전 2 계약을 유지하며 `AppSnapshot.records.items`를 복원한다. 버전 1은 기존 카드·정류장 정보를 유지하고 빈 기록으로 이관한다. 손상·지원하지 않는 버전·중복 여행 ID·잘못된 기록을 거부하며 로드 실패 상태에서 덮어쓰기를 차단한다. 복원 시 정렬은 메모리에만 적용하고 파일을 다시 쓰지 않는다.

연계: 웹은 journey의 하차 성공을 입력으로 받는다. iOS는 W08에서 완료 저장 API를 만들었고 W09a에서 하차 접촉 성공(`AppModel+Alighting`)이 이 API로 완료 기록을 만든다. 카드 외형이나 진행 타이머를 변경하지 않으며 완료 기록에 있는 태그/시간으로 집계한다.

## 향후 네이티브와 후순위

## iOS W09a 요약·기록 화면

`AlightingSummaryView`가 요약(한 일·시간·도착 정류장, 200자 선택 메모)을 보이고 `RecordMemoDraft`가 메모 입력 초안(200자 제한, 저장 실패 시 입력 유지)을 맡는다. 메모 저장은 `updateRecordMemo` 하나로 단일화했고 `saveRecordMemo`는 제거했다. 기록 화면은 `RecordsBrowser`(선택 날짜·연도 이동·최신순 10개와 더 보기·요약 줄)와 순수 규칙 `RecordsCalendar`(연 단위 하루 합계 0/1~30/31~60/61~120/121분+ → 0~4단계, 미래 선택 불가, 연도 이동 시 선택일 규칙)로 구성하고, `RecordMemoEditor` 시트로 메모를 남기거나 고친다. 잔디 격자 전체가 VoiceOver 조정 요소 하나다. 저장 형식은 v4 그대로다.

## 향후 네이티브와 후순위

W09b의 분석 화면(주/월·태그·인사이트)은 미구현이며 `RecordsCalendar`/`RecordsBrowser`와 기록 화면을 재사용한다. W09b는 같은 완료 기록·기간·달력/시간대 입력에서 같은 결과를 내는 공용 순수 집계도 소유한다. 앱과 위젯의 합계·횟수·7일 추이·태그별 시간을 별도 계산하지 않는다. 진행·포기·예시 제외, 저장된 완료 당시 날짜, 주/월 경계와 빈 기간을 테스트 입력으로 명시한다.

W18은 공용 집계 결과와 최소 여정 상태를 버전 있는 App Group 스냅샷으로 전달하는 입출력/갱신 기반과 두 계열의 소형·중형 위젯을 한 브랜치/PR로 구현할 계획이다. 앱의 원본 저장 성공 뒤에만 게시하며 공유 파일 쓰기 실패는 원본을 되돌리거나 덮어쓰지 않는다. 메모·할 일 원문은 공유하지 않는다. 손상·미지원 버전·접근 불가와 정상 빈 기간, 오래된 유효 스냅샷을 구분한다. 갱신은 성공한 상태 변경 뒤 reload 요청과 날짜 경계 timeline을 사용하며 매초 reload하지 않는다. App Group 식별자·서명 담당자는 ❓다. 큰 위젯·잠금 accessory는 1차 범위 밖이다. [승인 계획](../../.dev/system-surfaces-plan/plan.md)은 미구현 설계와 향후 실기기/접근성 검증 기준이다.

계정·클라우드 동기화·기기 간 공유·백업은 후순위다. 앱과 확장 사이의 로컬 App Group 공유와 구분한다. 상세 제품 범위는 [MVP](../../docs/MVP.md)에 있다.

## 주제 문서

| 주제 | 설명 |
|---|---|
| [현재 상태](../../docs/CURRENT-STATE.md) | 최신 기능과 검증 시점 |
| [화면 계약](../../docs/FLOWS.md) | 성공·취소·오류·저장 |
| [현재 VM 검사](../../scripts/prototype-edge-qa.cjs) | mock DOM·수치·상태 검증, 실제 iPhone 검증과 구분 |


## 개발 단계 연결

[개발 단계](../../docs/DEVELOPMENT-PHASES.md)에 단계 구분과 범위를 연결합니다. 웹 구현은 위의 단일 HTML이고, iOS는 W08 완료·메모 저장 모델과 집계·복원 검증, W09a 요약·기록 화면과 실제 하차 연동까지 완료했습니다. 분석 화면은 W09b입니다. 도메인의 구현 근거와 미반영 항목은 [status.md](status.md)에 기록합니다.
