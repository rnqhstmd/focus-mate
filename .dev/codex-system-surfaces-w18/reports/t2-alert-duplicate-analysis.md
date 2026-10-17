# T2 시스템 alert 중복 AX 진단 및 수정안

상태: 읽기 전용 진단 완료. 이 작업은 보고서만 작성했다. 테스트·생산 코드 수정, 빌드·테스트 실행은 하지 않았다. 전체 통합 검증 종료 후 부모의 별도 지시에 따라 수정할 예정이다.

## 직접 확인한 증거

- `verify-ios-swiftui-test.log:3295–3325`: 확인 버튼의 존재 대기는 통과했으나 tap에서 단일 요소 해석에 실패했다. `ActiveJourneyMainUITests.swift:43`의 실패이며, sparse tree에 ID `main.newJourney.confirm`과 label `새 여정 시작`이 동일한 부모 Button과 자식 Button이 중첩돼 있다.
- 같은 로그 `3356` 이후: `ActiveJourneyMainUITests.swift:60`도 같은 중복 조회로 tap에 실패했다. 두 실패는 동작 후 저장 결과 assertion에 도달하기 전 조회 실패다.
- `/tmp/w18-alert-tree/9DB73CC5-0D59-467E-93BF-82B2B4621831.txt:59–81`의 앞서 직접 확인한 초기 URL 진입 alert는 제목과 두 Button label이 있지만 identifier가 없다.
- 현재 `UITestLaunchSupport.swift:239–257`은 ID+label 후보 수가 1개일 때만 반환하고, 0개일 때 단일 alert의 유일 label을 허용한다. 2개이면 `identified.element`를 반환하므로 부모/자식 AX wrapper 중복을 실제 버튼 중복과 구별하지 못한다.

현재 로그의 두 실패 원인은 UI 존재 대기 부족이 아니라 AX 요소의 단일성 해석이다. 시스템 경고에 Alert/Sheet automation type 불일치도 있지만, 이것만으로 SDK 전체 원인을 단정하지 않는다. 검증 실행은 진행 중이므로 최종 실패 수나 전체 결과를 주장하지 않는다.

## 후속 수정안 (미적용)

1. ID+정확한 label의 Button 후보를 기존과 같은 범위에서 조회한다.
2. 후보를 `allElementsBoundByIndex`로 열거하고, 각 후보의 `descendants(matching: .button).count == 0`인 말단 Button만 남긴다. 원본 중복 query의 `.element`를 먼저 해석하면 현재 오류가 반복될 수 있으므로 후보 열거로 개별 요소를 확보한다.
3. 말단 후보가 정확히 1개일 때만 반환한다. 둘 이상의 실제 말단 버튼은 임의 선택하지 않고 실패를 유지한다. ID 후보는 있지만 말단이 없거나 여러 개라면 label fallback도 하지 않는다.
4. 원래 ID+label 후보가 0개일 때만 fallback한다. 앱 alert가 정확히 1개일 때 그 alert 안의 정확한 label Button 후보를 같은 방식으로 말단 필터링한다. 말단 후보가 정확히 1개일 때만 반환한다. 복수 alert·복수 실제 말단 label 후보는 실패한다.
5. 실패 경로에서 `.firstMatch`로 중복을 숨기지 않는다. 기존 assertion이 실패하도록 미해결 query를 반환하거나 진단을 명시한다. 현재 실패 시 AX 첨부도 유지한다.

이 방식은 ID가 유지되지만 wrapper가 중복되는 기존 메인 진입과 ID가 누락되는 초기 URL 진입을 함께 다룬다. Button role, 정확한 label, ID 우선순위와 유일성 조건은 유지한다. 신규 테스트 본문 및 확인·취소 이후 화면/원본 바이트/저장 횟수 기대값은 바꾸지 않는다.

## 후속 확인 범위

전체 검증 종료 및 수정 승인 뒤, 실제 두 실패 테스트와 WidgetEntry 새 여정 확인·취소 테스트를 확인한다. ID 없는 단일 leaf, ID 있는 단일 leaf, 같은 ID 부모/자식 중 유일 leaf는 선택 가능해야 한다. 서로 다른 두 leaf 또는 두 alert의 label fallback은 거부되어야 한다. 실행 증거가 나오기 전에는 이 제안을 GREEN 수리로 간주하지 않는다.
