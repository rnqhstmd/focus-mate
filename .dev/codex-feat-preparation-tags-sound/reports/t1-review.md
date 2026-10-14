## Part 1: AC 충족 매트릭스

T1 도메인 범위만 평가했다. 화면 표시·편집 화면 유지/복귀·취소·접근성·오디오 재생은 이번 판정에 포함하지 않았다.

| AC | 충족도 | 근거 |
|---|---|---|
| AC-1 | ✅ | `ios/FocusMate/PreparationDraft.swift:40-46` 초기 선택 없음·빈 할 일·bus·불완전. `PreparationModelTests.swift:19-29` 유효 W02 진입 후 직접 확정·소비 차단 확인. |
| AC-2 | ✅ | `PreparationDraft.swift:47-50` 존재하는 태그 하나만 선택하고 할 일은 변경하지 않음. `PreparationDraftTests.swift:17-23`, `PreparationModelTests.swift:35-45` 독서 선택 후 빈 입력·확정 차단 확인. |
| AC-3 | ✅ | `PreparationDraft.swift:45-46`, `AppModel.swift:32-49` trim 결과가 비어 있으면 확정 불가. `PreparationDraftTests.swift:36-48`, `PreparationModelTests.swift:51-58,313-322` 기존 확정 이후 빈 값·공백으로 변경한 경우도 전달 차단 확인. |
| AC-4 | ✅ | `PreparationDraft.swift:52-61` UTF-16 80단위 제한과 scalar 경계 보존. `PreparationDraftTests.swift:52-80` 80/81·이모지 경계 확인. `PreparationModelTests.swift:63-70` 잘린 입력의 실제 확정·1회 전달 확인. |
| AC-5 | ✅ | `PreparationDraft.swift:24-27` 편집 초안 기본값은 빈 이름·reading·sand. `PreparationDraftTests.swift:93-99` 해당 도메인 기본값 확인. 실제 `+` 진입은 T3 범위. |
| AC-6 | ✅ | `PreparationDraft.swift:65-66` 빈 이름·공백 이름을 `.empty`로 거부하며 변경 전 반환. `PreparationDraftTests.swift:104-110,181-186` 오류와 준비 초안 전체 불변 확인. |
| AC-7 | ✅ | `PreparationDraft.swift:68-71` 기존·입력 이름 양쪽 NFKC 및 소문자 비교. `PreparationDraftTests.swift:114-128` 대소문자·전각/반각 중복과 추가 없음 확인. |
| AC-8 | ✅ | `PreparationDraft.swift:65-67` trim 후 UTF-16 20단위 상한. `PreparationDraftTests.swift:132-147` 20 허용·21 거부·22단위 이모지 거부 확인. |
| AC-9 | ✅ | `PreparationDraft.swift:72-77` 정리한 표시 이름·아이콘·색을 가진 태그 하나 추가하고 선택. `PreparationDraftTests.swift:151-163` 메타데이터·할 일·소리 보존, `PreparationModelTests.swift:76-85` W02 여정 보존 확인. |
| AC-11 | ✅ | 기존 `AppModel+JourneyStart.swift:35-38` 재진입에서 준비 초안을 초기화하지 않음. `AppModel.swift:32-34` 현재 유효 여정 필요. `PreparationModelTests.swift:91-121` 왕복 보존 및 시간 변경 후 getter·확정·소비 차단 확인. |
| AC-12 | ✅ | `AppModel.swift:32-36,45-69` 현재 여정·태그·trim 할 일·확정 소리를 값으로 전달하며 요청만 1회 소비. `PreparationDraft.swift:80-87` 출발 이름·방면·거리 파생. `PreparationModelTests.swift:127-144`, `PreparationDetailsTests.swift:6-16` payload·파생값·진행 여정/기록 없음·쓰기 없음 확인. |
| AC-13 | ✅ | `AppModel.swift:32-49,55-66` 유효하지 않은 현재 상태의 확정·소비를 차단하고 backing 값을 정리. `PreparationModelTests.swift:109-121,179-237,242-267,313-339` 여정/태그/할 일 누락·변경된 payload·무효 소비 이후 복원·getter 무부작용 확인. |
| AC-23 | ✅ | 추가 프로덕션 코드에 저장 호출 없음. `PreparationModelTests.swift:285-292,344-368,388-397` 정상·쓰기 실패 환경의 실제 파일 바이트·snapshot·쓰기 시도 0 및 새 AppModel 세션 초기화 확인. |

[Must] 13건 중 13건 충족. [Should] 대상 없음.

## 설계 범위 이탈

이탈 없음. 변경은 T1의 `PreparationDraft`, `PreparedJourneyDetails`, `AppModel` 준비 경계와 해당 테스트에 한정된다. computed getter의 현재 payload 비교 및 무효 소비 시 backing 삭제는 설계의 「2차 설계 보강」과 일치한다.

## Part 1 판정

**SPEC PASS — T1 도메인 대상 AC 13건 충족.**

## Part 2: 코드 품질 리뷰

실제 production diff와 세 테스트 파일을 검토했다. 테스트는 재실행하지 않았다. 실행 결과 42 pass / 0 fail 및 RED 해시 유지 여부는 부모가 직접 확보한 증거로 구분한다.

상한은 `private(set)` 필드와 공개 변경 메서드에서 보장된다. 따라서 `isComplete`에 상한을 다시 검사하지 않는 것이 현재 생성·변경 경로에서 초과 입력을 허용하지 않는다. 실패한 태그 저장은 상태 변경 전에 반환하며, 확정값과 요청은 현재 payload가 일치할 때만 노출된다. 실제 store와 I/O 경계 probe를 사용한 테스트는 모의 자체의 동작을 검증하지 않는다. UTF-16 경계 및 파생값 기댓값도 검증 대상 헬퍼로 계산하지 않았다.

### Critical (0건) — 전부 [동작결함]

없음.

### Important (0건)

없음.

### Minor (1건) — 전부 [동작불변], 비차단

- `ios/FocusMateTests/PreparationDraftTests.swift:94-100` — `draft`와 `before`는 동일한 불변 값이고, 이후 생성하는 `TagEditorDraft()`에는 해당 draft를 전달하지 않는다. 따라서 마지막 `XCTAssertEqual(draft, before)`는 편집 화면을 열 때 준비 초안이 보존되는지를 검증하지 않는 중복 assertion이다. 기본 편집값을 검증하는 앞선 세 assertion은 유효하다.
  - 권고: 이 테스트의 설명을 편집 초안 기본값으로 한정하고 중복 비교를 제거한다. 실제 화면 열기의 초안 보존은 T3의 상호작용 테스트에서 평가한다.

## Part 2 판정

**QUALITY PASS — Critical 0건, Important 0건, Minor 1건.**

```yaml
spec_verdict:
  verdict: PASS
  ac_total: 13
  ac_met: 13
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
  minor: 1
```
