## Part 1: AC 충족 매트릭스

T2의 controller·AV adapter·소리 식별자·AppModel 단일 소유/주입만 평가했다. 실제 화면 열기·저장·취소·화면 이탈·scenePhase 이벤트 연결은 T3 대상이다.

| AC | 충족도 | 근거 |
|---|---|---|
| AC-14 | ✅ | `SoundPreviewController.swift:24-34,93-98` 확정값으로 임시 선택을 초기화하며 초기화·선택만으로 factory를 호출하지 않음. `SoundPreviewControllerTests.swift:35-50` 실제 controller 초기화·자동 재생 없음 확인. 다섯 식별자는 `PreparationDraft.swift:33-45`. |
| AC-15 | ✅ | `SoundPreviewController.swift:93-98` 재진입 시 전달된 확정값으로 임시 선택을 되돌림. controller가 준비 초안을 직접 변경하지 않음. `SoundPreviewControllerTests.swift:53-59` forest 편집 후 bus 재진입 확인. 실제 취소 연결·다른 준비 필드 보존은 T3 대상. |
| AC-16 | ✅ | `SoundPreviewController.swift:31-34` 임시 선택 보유. `SoundPreviewControllerTests.swift:62-71` 실제 `PreparationDraft.setSound`로 rainBus를 확정하고 다음 선택 초기화에 반영. 버튼·표시 문구 연결은 T3 대상. |
| AC-17 | ✅ | `SoundPreviewController.swift:36-67` 사용자 요청 후 factory, 무음 준비, 무한 반복 설정, prepare/play 성공 후 120ms 페이드와 playing 전이. `AVSoundPreviewPlayer.swift:7-20` AVAudioPlayer에 forwarding. `SoundPreviewControllerTests.swift:74-94` 네 샘플·요청 순서·loading 확인. `AudioResourceTests.swift:10-27` 실제 앱 번들 golden 바이트·decode·adapter 준비 확인. |
| AC-18 | ✅ | `SoundPreviewController.swift:31-34,37,51-55,77-87` 선택/재입력 중지, 60ms 페이드 후 stop, 이전 stop 완료 대기 및 재검증. `SoundPreviewControllerTests.swift:97-128` 중지·선택 변경·중복 stop 확인. `:131-154` 순서 검사도 존재하나 회귀 검출력 문제는 Part 2에 별도 기록. |
| AC-19 | ✅ | `SoundPreviewController.swift:38` none이면 factory 호출 없음. `PreparationDraft.swift:44` none 리소스 없음. `AVSoundPreviewPlayer.swift:22-27` 직접 none 요청 거부. `SoundPreviewControllerTests.swift:157-163`, `AudioResourceTests.swift:31-36` none 동작 확인. 준비 확정 가드는 기존 T1 검토 대상. |
| AC-20 | ✅ | `SoundPreviewController.swift:59-74` prepare/play 실패 및 factory 오류에서 중지·안내·선택 유지. `AVSoundPreviewPlayer.swift:22-27` 주입 bundle의 리소스만 조회하고 누락 시 throw. `SoundPreviewControllerTests.swift:166-191` 세 실패 경로 확인. `AudioResourceTests.swift:39-46` 누락 bundle 주입 확인. |
| AC-21 | ✅ | `SoundPreviewController.swift:46-55,68-74,77-102` generation·active·선택·Task 취소로 늦은 성공/오류를 차단하며 stop 대기 뒤 재검증. `SoundPreviewControllerTests.swift:194-247` 재입력·선택·stop·비활성화·새 재생 후 old 성공/오류·재진입 후 old 오류 확인. save/cancel/disappear는 공통 stop 경계 테스트이며 실제 UI 연결을 검증한 것으로 보지 않음. |
| AC-22 | ✅ | `AppModel.swift:78-86` 세션 단일 controller 소유 및 선택적 주입. `SoundPreviewController.swift:77-98` 종료 작업 보존, 비활성화 중지, 복귀/재진입 자동 시작 없음. `SoundPreviewControllerTests.swift:35-43,135-154,250-258` identity·재진입·자동 재개 없음 확인. |

[Must] 9건 중 9건의 T2 담당 부분 충족. [Should] 대상 없음.

## 설계 범위 이탈

이탈 없음. 신규 controller·AV adapter·승인된 기존 WAV 네 개, `resourceName` 매핑, AppModel 소유/생성자 주입은 승인 설계 범위다. 공유 파일의 T1 준비 로직은 이번 리뷰에서 재평가하지 않았다.

## Part 1 판정

**SPEC PASS — 현재 프로덕션 코드가 T2 담당 계약을 충족한다.**

## Part 2: 코드 품질 리뷰

실제 diff와 `SoundPreviewControllerTests` 22개, `AudioResourceTests` 3개를 읽었다. 테스트 실행·파일 변경은 하지 않았다. 67 pass / 0 fail·exit 0 및 다섯 테스트의 RED 해시 유지 여부는 부모의 직접 실행 증거다.

늦은 성공과 catch 양쪽에서 동일한 유효성 검사를 수행한다. 이전 stop 대기 뒤에도 검사하여 대기 중 선택·활성 상태가 바뀐 경우 재생하지 않는다. stop은 active player 참조를 즉시 비우므로 반복 호출이 기존 종료 작업을 교체하거나 fade/stop을 중복하지 않는다. AV adapter는 주입 bundle을 존중하며 main이나 source path로 fallback하지 않는다.

### Critical (0건) — 전부 [동작결함]

없음.

### Important (1건)

- `ios/FocusMateTests/SoundPreviewControllerTests.swift:138-153` — `assertNoOverlap`이 **B의 factory 결과를 반환하기 전에 A의 종료 gate를 해제하고 A.stop까지 기다린다**. 따라서 `SoundPreviewController.swift:51`의 이전 stop 대기를 삭제해도, B는 테스트가 A.stop을 완료시킨 뒤에야 player를 받아 재생할 수 있다. `b.playCalls == 0` 검사도 factory 결과를 아직 제공하지 않은 시점이므로 종료 장벽을 검증하지 않는다. 현재 제품 코드는 올바르지만 두 겹침 테스트가 핵심 회귀를 잡지 못한다. 테스트 품질 기준의 변이 점검에 해당한다. → **[동작불변]**
  - 권고: A 종료 gate를 계속 보류한 상태에서 B factory 도착을 기다리고 B player를 반환한다. 그 상태에서 B.play가 발생하지 않는지를 명시적인 이벤트 관찰로 검사한 뒤 A gate를 해제하고 `A.stop → B.play` 순서를 확인한다. 일반 선택 변경과 close/reopen 두 경로 모두 적용하고, 종료 대기 제거 변이가 실제 실패하는지 확인한다. 고정 sleep/yield 횟수에 의존하지 않는다.
  - 이 지적은 새로운 AC나 현재 재생 결함을 주장하지 않는다. 기존 BR-8/설계의 겹침 금지 계약을 지키는 회귀 테스트를 보강하는 요청이다.

### Minor (0건) — 전부 [동작불변], 비차단

없음.

## Part 2 판정

**QUALITY FAIL — 프로덕션 동작 결함은 발견하지 않았으나, 종료 장벽 회귀 테스트 보강이 필요하다.**

이 판정은 실기기 청취·VoiceOver·UI lifecycle 연결 검증을 포함하지 않는다.

```yaml
spec_verdict:
  verdict: PASS
  ac_total: 9
  ac_met: 9
  ac_partial: 0
  ac_unmet: 0
  unmet_ids: []
```

```yaml
quality_verdict:
  verdict: FAIL
  critical: 0
  important: 1
  important_behavior: 0
  minor: 0
```

## 재리뷰 R1

### Part 1: AC 충족 매트릭스

R1은 이전 Important 테스트 품질 지적 재리뷰. 기존 프로덕션 계약 판정 유지, 변경된 테스트만 확인.

| AC | 충족도 | 근거 |
|---|---|---|
| AC14 | 충족 | 초기화·선택 계약 유지. |
| AC15 | 충족 | 확정값 기반 임시 선택 유지. |
| AC16 | 충족 | 임시 선택·준비 확정 유지. |
| AC17 | 충족 | 반복·120ms·번들 유지. |
| AC18 | 충족 | SoundPreviewController.swift51-55,77-87 종료 대기 유지; 테스트138-158 A gate 보류 중 B 반환 및 조기 재생 검사. |
| AC19 | 충족 | none 요청0/adapter 거부 유지. |
| AC20 | 충족 | 오류·선택 유지·주입bundle 유지. |
| AC21 | 충족 | 늦은 성공/오류 유효성검사 유지. |
| AC22 | 충족 | 테스트135-158 공통보강helper로 close/reopen 검사, 단일controller/복귀재개0 유지. |

Must9/9 충족. 설계 이탈 없음, 기존helper와fake의선택적play관찰자만변경. 프로덕션 테스트전용API 없음. SPEC PASS.

### 재리뷰 판정

| 항목 | 판정 | 근거 |
|---|---|---|
| A.stop 후 B factory를 반환해 종료대기제거 변이를 못 잡음 | ADDRESSED | SoundPreviewControllerTests.swift144-151: B factory도착/반환 먼저, inverted play 및호출수확인.153-158: gate해제/B완료/A.stop<B.play.274,281-283: 실제player경계play관찰. |

### Part 2: 코드 품질

새 결함 없음. inverted bounded fulfillment는 명시적 금지 이벤트 관찰이며 고정sleep/yield 없음. 관찰자 제거 후 gate해제와Task join 및 최종player 종료 유지. 리뷰어 재실행 없이 부모 로그 확인: 변이67개중2target실패(assertion6개), 원본복원뒤67/0fail TEST SUCCEEDED. 프로덕션SHA2566266dadcc2ce9c575ed2271f9a2a3260d6abb82a86d3acb86afa3d3de0d42f99 직접읽기확인 일치. 리뷰어 테스트rawSHA2566c6de3a45574c787231b608c8b73a7ea2076f4fd4a58f4f6b4536de8c2e52bef 확인. Critical0 Important0 Minor0, 이전Important해결. QUALITY PASS. UI lifecycle/실기기청취/VO범위외.

```yaml
spec_verdict:
  verdict: PASS
  ac_total: 9
  ac_met: 9
  ac_partial: 0
  ac_unmet: 0
  unmet_ids: []
```

```yaml
quality_verdict:
  verdict: PASS
  critical: 0
  important: 0
  important_behavior: 0
  minor: 0
```

부모 해시 알고리즘 구분: GX test-file-hash는 git hash-object의 SHA1 blob fd1a0b5f6eb2a57510d650663d484f4f47b1f904이다. 위rawSHA256과서로다른알고리즘/대상형식이므로불일치아님. 실제파일변경없음을두방법으로확인. 원장blob해시는정확하게유지.
