# W18 T2 품질 리뷰

판정: PASS — 검토 범위에서 수정이 필요한 finding 없음.

## 범위
design.md v2 우선 계약을 읽고 WidgetSnapshotPublisher.swift, WidgetNavigation.swift, AppModel.swift, RootView.swift, RecordsView.swift, RecordsAnalyticsView.swift의 T2 동작을 검토했다. 원본 전체 검증 여부 확인을 위해 AppSnapshot.launchRoute의 validate 호출도 확인했다. T3 Shared stub·provider·실제 앱 publisher 주입/프로비저닝은 판정 범위 밖이다.

## 확인한 계약
- projection은 launchRoute를 통해 전체 원본 검증을 거치고 W09b 주간 report의 today/7일/topTags만 투영한다. task/memo/최근 원문은 공유 모델로 전달하지 않는다.
- publisher는 유효한 동일 공유 payload의 중복 게시를 생략한다. stale 또는 다른 payload는 쓰기를 시도하고 성공 후에만 reload한다. 공유 실패는 false로 종료하여 원본 저장 결과를 뒤집지 않는다.
- AppModel의 persist와 카드 보충은 store.save 성공 뒤에만 게시 가능 상태를 연다. migration 필요 load는 게시 불가이며 실패 후 foreground에도 불가 상태를 유지한다. 성공 persist/보충 저장은 실제 새 형식 저장 이후이므로 게시 가능 전환이 타당하다.
- cleanup은 backupAndClear 성공 뒤에만 empty를 게시한다. load 실패 시 snapshot을 제거하고 publication eligibility를 비활성화한다.
- pending은 raw URL로 보관하고 소비 시 현재 recordClock으로 다시 parse한다. 적용 전에 삭제하여 같은 pending의 중복 소비를 막는다.
- 정책은 열린 흐름을 먼저 보존하고, 여정 ID를 UTF16으로 비교한다. running/paused의 showActiveJourney는 저장·경로 변경·resume token 설정 없이 반환된다. awaiting/arrived만 기존 무저장 안내 진입을 사용한다.
- 새 여정 링크는 confirmation 결정만 반환하고 RootView가 기존 확인 UI를 소유한다. 실제 confirmNewJourney는 사용자 확인 action에만 연결된다.
- 분석 링크의 kind/day/tag를 최신 검증 결과와 함께 전달한다. RecordsView는 entry를 한 번 소비하고 AnalyticsView는 initialKind 적용 후 태그를 검증한다. 일반 앱 분석 진입의 월 기본값은 유지한다.

## 검증 증거와 한계
테스트·빌드를 실행하지 않았고 생산 코드·테스트를 수정하지 않았다. 부모 보고상 단위 GREEN은 t2-green-run.log 68건/0실패이며 해당 로그를 직접 재검증하지 않았다. 신규 UI GREEN은 리뷰 요청 당시 진행 중이므로 이 문서는 UI 완료 판정이 아니다.

RootView의 실제 URL 전달, cold launch/retry 후 pending 소비, confirmation 취소, 분석 push 전환은 별도 UI 결과로 확인해야 한다. 현재 리뷰는 소스 계약 검토이며 실제 기기·갤러리·VoiceOver 동작을 보증하지 않는다.
