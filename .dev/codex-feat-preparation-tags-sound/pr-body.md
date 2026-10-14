## Background

시간·여정 선택 뒤 준비 화면이 자리표시라 태그·할 일·소리를 확정할 수 없었다. 승인 시안의 준비 허브를 구현하고 W04가 소비할 유효한 준비값을 제공한다.

## Summary

세션 메모리의 태그·할 일·소리 초안과 중복 소비를 막는 payload 경계를 연결했다. 승인된 준비·태그·소리 패널을 구현하고 최신 main의 마이페이지 변경을 보존했다.

## Changes

태그 이름 trim·20 UTF-16 상한·정규화 중복과 할 일 80단위 상한을 검증한다. 시간 왕복에서 초안을 유지하고 변경된 여정의 이전 확정값을 차단한다. 준비 확정은 저장 데이터나 진행 기록을 생성하지 않는다.

소리 5종을 임시 선택하고 저장·취소를 구분한다. 승인 WAV 4종과 실제 AVAudioPlayer 미리듣기·반복·페이드를 제공하며 선택 변경·닫기·비활성화와 늦은 완료를 안전하게 중지한다. 실패해도 선택과 저장을 유지한다.

승인 폰트·두 줄 태그·입력중 선택색 테두리·태그 편집·소리 3+2 배치를 반영했다. 최대 글자·키보드 상태에서도 입력·하단 버튼에 도달한다. 시간 후보 버튼의 둥근 사각형 모양을 명시해 기존 히트 영역 회귀를 보정했다.

## Validation

최신 main 통합 후 최종 gx-verify: 네이티브 단위366개·화면99개=465개와 웹31개+edge QA 실패0, 빌드 모두 성공·경고0. reports/verify.md에 신선한 실행 증거와 코드 지문을 기록했다. 정적 시안 대조91/pass와 실제 입력중 캡처를 확보했다.

W04 승차권·W09 지도, 실제 VoiceOver·실기기 청취·브라우저 확인은 이번 완료 판정에 포함하지 않는다.

## Audit Summary

보안 감사 CRITICAL0 HIGH0 MEDIUM0. 품질 Critical0 Important0 Minor3은 아래 유예 항목으로 유지한다.

## Rulings

- T3 scoped Minor 유예 — 성공/취소 VoiceOver 포커스 구분·한국어 접근성 phase를 기존 테스트 Minor와 전체 리뷰에 인계. 전체 reviewer가 필수 수정으로 승격하면 RGR/정리로 수정.
- 전체 리뷰 Minor 3건 유예 — 최신 main 통합 소스에서 3건 모두 비차단 유지. 실제 VoiceOver 차단이 확인되면 RED 재현 후 수정.

## Deferred

- [Minor] ios/FocusMateTests/PreparationDraftTests.swift:94 — 기본 편집값 검사의 중복 불변 비교.
- [Minor] ios/FocusMate/PreparationView.swift:128 — 저장 성공 후 실제 VoiceOver 포커스 확인.
- [Minor] ios/FocusMate/PreparationView.swift:387 — 미리듣기 접근성 상태의 한국어 문구 분리.

## Checklist

- [x] RED→GREEN 증거와 태스크/전체 리뷰 기록
- [x] 승인 참고와 실제 네이티브 상태 대조
- [x] 최신 main 통합 전체 테스트·빌드
- [x] 최종 gx-verify 및 인수 검증(ACCEPT25/25)
