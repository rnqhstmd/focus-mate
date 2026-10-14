# W10 최종 검증 — 사용자 지시에 따른 제한 범위

기준: main5a9b611을 합류한 HEAD8bf0b922와 현재 W10 소스. 2026-10-15 KST.

| 실행 | 실제 결과 |
|---|---|
| npm run build | exit0 |
| npm test | exit0, 단위31 및 edge QA PASS |
| iOS Debug build | exit0 BUILD SUCCEEDED |
| 최신 통합 focused | 단위539+핵심UI6=545PASS, 0FAIL, exit0 |
| 부모 최신 전체 test | 단위539+완료UI7 PASS, 완료실패0. 사용자 중단 exit130이며 전체 통과 아님 |
| 전체 UI115 중 이번 실행의 나머지108 | 미완료: 사용자 요청으로 중단 |
| iOS Release build | 수정 후 부모 직접 BUILD SUCCEEDED, exit0 |

사용자는 전체 회귀를 중단하고 리뷰 후 PR·main 머지를 명시 요청했다. 이 제한을 숨기거나 전체0fail로 치환하지 않는다. 코드 변경이나 실제 결함이 없는 한 전체 시험을 반복하지 않는다.

## 직접 실제 런타임 증거

- 실제 PhotosPicker 순서 입력·취소·재선택·드래그·크기 조절 후 선택 유지·저장·동일 UUID 재실행 PASS. R40 겹침/카드clip/선택outline/resizehandle PNG 직접 확인.
- 고유 파일명으로 확인한 소유 원본2개만 Photos에서 삭제. 기존6개 labels 보존. 삭제 전후 photoID·이미지SHA256·치수·배치·색 유지. 전체 파일 persistedBytes 비교는 삭제 후 두 cold launch 사이만 확인.
- 실제 native RGB 슬라이더 변경·버리기·저장·동일 UUID 재실행 PASS.
- 실제 VoiceOver selected/disabled/current-value 발화와 X/Y doubleTap .50→.55 PASS. 최신 profile import/saveFailure/saveSuccess currentSpeech3 PASS 및 성공 안내 초점 PNG 직접 확인.
- VO width swipe bonus 및 가져오기 안내의 지속 시각초점은 미확정. 실제 iPhone/햅틱 체감은 W14 대기.
- 이 native 관찰 후 W03 합류에서 핵심13개 Swift·폰트2개 bytes가 동일함을 부모가 직접 비교했다. 관찰 자체를 합류 후 새로 재실행했다고 과장하지 않는다.

세부: [runtime](t5-runtime-supplement.md), [시각](t5-visual-verification.md), [W03 합류](w03-main-integration.md), [T5 재리뷰](t5-r2-review.md).

## 테스트 보존 및 이전 증거

최신22개 frozen test Gitblob 동일. 과거 전체관련집합259PASS는 당시 소스의 증거이며 최신 전체 회귀로 재사용하지 않는다. 새 artwork 및 nativegesture 실제 RED→최소fix→부모 fresh PASS와 W11 합류10PASS, W03 합류545PASS를 각각 구분한다. 전체sourcefreeze 및 코드지문은 리뷰·종료단계에 기록한다.

## 안내 수정 후 최종 직접 검증
리뷰 I1의 오류 이유 안내는 독립8개 의미 검사 actual RED→최소 enum표현 변경→8GREEN으로 수리했다. 부모는 긴 UI를 재실행하지 않고 **전체 단위547/0fail, exit0 TEST SUCCEEDED**(8.672초) 및 수정 후 **Release BUILD SUCCEEDED, exit0**를 직접 확인했다. 두 source 파일은 공유 안내 표현만 바꾸며 controller 상태·processor·snapshot·store·layout은 변경하지 않았다. 기존 일반 읽기/저장 안내는 정확히 유지했다. 이전 완료UI7 및 통합focusedUI6은 안내 수정 전의 근거로 명시하고 현재 전체UI완료로 바꾸지 않는다.

최종 리뷰: SPEC35/35 PASS, QUALITY Critical0/Important0/Minor4유예. 보안 최초 및 안내 delta 모두 CRITICAL0/HIGH0/MEDIUM0.

경고: 단위 실행에는 main에서 그대로 가져온 AudioResourceTests23의 AVAudioSession main-thread runtime 진단이 출력됐다. 해당 파일은 origin/main과 동일하며 테스트는 PASS. 신규 W10 Swift compiler 경고를 확인하지 않았고 SDK 메타데이터 알림과 기존 unused 경고를 모든 경고0으로 표현하지 않는다.

코드 지문: `8bf0b92:9e9701f3045a`(helper exit0/형식 확인). 사용자 지시로 중단한 전체UI108 미완료 제한을 수용한 완료 게이트이며, 전체 회귀 PASS가 아니다.

## 완료 문서 반영
PR #15 생성 후 plan·card context·CURRENT-STATE를 완료 상태로 갱신했다. 승인된 iOS 소스112개 SHA256은 모두 동일하다. 문서만 변경하여 테스트를 반복하지 않았으며 문서 반영 지문은 `223a883:4d988c4964bd`다. 원 검증 지문과 실행 근거는 위와 같다.
