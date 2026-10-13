# Phase 1 iOS 앱 기반

2026-10-13. 상태: **완료** — 앱 기반 구현·전체 검사·전체 리뷰 통과, [PR #2](https://github.com/rnqhstmd/next-step/pull/2) main 머지(2026-10-13 02:55 KST). 인수 근거는 아래 작업 기록에 연결한다. PRD와 후속 전체 과정은 사용자 “모두 진행”으로 승인했다.

## 포함 범위

- iOS 17 이상 SwiftUI 앱, 앱·XCTest Unit·XCTest UI 타깃과 공유 FocusMate 스킴.
- 저장 데이터 없음 → 집중동행카드 진입. 카드 발급 상태만 있음 → 최초 정류장 진입. 최초/현재 정류장이 저장됨 → 현재 정류장 메인.
- 메인에서 여행 준비·기록·설정·마이페이지 기본 화면 왕복. 탐색으로 저장 상태가 바뀌지 않는다.
- Application Support/FocusMate/app-state.json의 version 1 상태 저장과 복원. 발급 여부·최초/현재 정류장 ID/이름/방향만 저장한다.
- 손상·미지원 버전·읽기 실패는 초기 상태로 덮어쓰지 않는다. 실패한 저장은 이전 메모리·경로를 유지하고 성공으로 안내하지 않는다. 파일은 Foundation의 atomic write를 사용하며, 주입된 쓰기 전 실패에서 기존 바이트 보존을 확인했다. 실제 파일 교체 중 실패·전원 장애·다중 writer는 아직 검증하지 않았다.

실제 카드 발급·최초 정류장 선택·버스/시간/태그/소리·승하차·MapKit/타이머·기록 작성은 후속 Phase 2~5다. 기본 진입 화면에는 해당 기능을 완료하는 버튼이 없다. 서버·계정·GPS·실시간 버스 API·클라우드도 추가하지 않았다. 승인된 시안의 전체 네이티브 화면 재현이나 실기기 완료를 뜻하지 않는다.

## 실행

Xcode에서 ios/FocusMate.xcodeproj → FocusMate → 설치된 iPhone Simulator를 선택한다. 로컬 Simulator 빌드에는 배포 Team을 요구하지 않으며 임시 개발 ID app.focusmate.prototype를 사용한다.

```sh
python3 scripts/check-ios.py build
python3 scripts/check-ios.py test
# 한 테스트 클래스만 검사
python3 scripts/check-ios.py test ios/FocusMateUITests/Phase1FlowTests.swift
```

FOCUSMATE_SIMULATOR_ID로 기기를, FOCUSMATE_DERIVED_DATA로 빌드 캐시 경로를 지정할 수 있다. 기본은 최신 설치 iOS 17+ iPhone Pro와 .build/ios다. Simulator의 선택과 실제 런타임 설치는 별개이며 런타임이 없으면 명시적으로 종료한다.

## 직접 검증 근거

- Xcode 27.0 약관은 사용자가 직접 동의했다. Swift 6.4·iOS 27 SDK·iOS 27 런타임 조회가 성공했다.
- iPhone 18 Pro / iOS 27 (529B88AF-5286-43EA-938A-4233F6B226CD)에서 빈 하네스 단위1/UI1을 실제 실행해 0 failures 확인.
- 동일 기능 UI 테스트 8건이 빈 앱에서 실제 assertion RED(8 failures, exit65) → 구현 후 GREEN(8 pass, 0 failures, exit0)으로 바뀌었다. 테스트 파일 해시는 유지했다.
- 리뷰 지적 재현을 위해 UI2건을 추가했다. 잘못된 시험 UUID는 setup 오류를 표시하고 load를 중단하며, 네 목적지에는 뒤로가기 외 완료 동작이 없음을 확인했다. R1 RED는 9 pass/1 failure(exit65), 수정 후 10 pass/0 failures(exit0)이며 독립 재검토 SPEC/QUALITY가 통과했다.
- 카드만 있는 진입, 최초·현재 정류장 구별, 네 기본 화면 왕복, seed 없이 실제 terminate/launch 복원, 손상·미지원 원본 바이트 보존, 주입된 쓰기 전 실패의 이전 snapshot/파일 바이트 유지와 안내를 검사했다.
- 실제 재실행은 동일 Application Support 시험 경로를 사용한다. 새 저장소 인스턴스나 임시 파일 round-trip만으로 재실행을 통과로 보고하지 않았다.
- 실패 진단 수집에서 종료가 지연된 실행은 취소로 기록했다. 직렬 재검증과 collect-test-diagnostics never 적용 후 정상 exit65를 확인했다.

전체 회귀는 Unit15(제품14+smoke1), UI11(제품10+smoke1) 합계26건/0 failures, 웹31 tests/0 failures + VM26 PASS 항목을 확인했다. 양쪽 build/test exit0이다. Release generic Simulator build도 성공했고 시험 인자와 진단 문자열은 Release 바이너리에서 제외됐다. 전체 리뷰는 SPEC4/4·QUALITY PASS, Critical0/Important0이며 Minor2건을 유예했다. 보안은 CRITICAL0/HIGH0/MEDIUM3이며 출시 전 항목을 원장에 보존했다. 최신 완료 검증·인수 결과는 작업 기록에서 확인한다. 최초 전체 컴파일의 AppIntents 메타데이터 경고는 기존 도구 경고로 분리하며 신규 Swift 경고와 혼동하지 않는다.

## 시험 데이터와 안전 경계

DEBUG의 --fm-ui-test-id UUID에서만 시험 경로를 활성화한다. seed는 신규 UUID에만 쓰고 재실행에서는 seed를 전달하지 않는다. 상태/파일 바이트 진단은 읽기만 하며 Release에서 시험 인자·주입·진단은 제외한다. 운영 저장 파일을 시험 seed로 덮어쓰지 않는다.

## 작업 기록

[PRD](../.dev/codex-feat-phase-1-app-foundation/prd.md) · [설계와 테스트 가능성 평가](../.dev/codex-feat-phase-1-app-foundation/design.md) · [RGR 구현](../.dev/codex-feat-phase-1-app-foundation/reports/t1-impl.md) · [진행 상태](../.dev/codex-feat-phase-1-app-foundation/state.md) · [최종 검증](../.dev/codex-feat-phase-1-app-foundation/reports/verify.md) · [인수](../.dev/codex-feat-phase-1-app-foundation/reports/acceptance.md) · [유예](../.dev/codex-feat-phase-1-app-foundation/reports/review-deferred.md).

Phase 0의 승차·태그 브라우저 화면 확인 2건은 계속 대기이며 이번 iOS 기반 검증으로 대체하지 않는다. 기존 네 도메인 요구사항 원장의 iOS 기능은 이번 부분 연결만으로 완료 처리하지 않는다.

## 후속 검증·복구 경계

Phase1은 저장 오류를 감지하고 원본을 보호하는 단계다. 오류 화면에서의 재시도·내보내기·명시적 정리 기능은 제공하지 않아 복구 전에는 진행할 수 없다. 복구 동작은 Phase5 환경·복구 설정에서 정의하고 Phase6 출시 검증에서 확인한다.

파일 크기와 필드 길이 한도, 가상 정류장 데이터의 분류·백업·파일 보호 정책은 출시 전에 확정할 항목이다. 현재 단계에서 해당 정책 또는 실제 교체 실패·전원 장애 복구가 완료됐다고 보고하지 않는다. 상세 유예는 작업 원장에 기록한다.
