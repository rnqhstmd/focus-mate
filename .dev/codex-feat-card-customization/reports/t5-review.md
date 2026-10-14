## Part 1: AC 충족 매트릭스

검토 범위는 T5의 `t5-diff.txt`와 현재 소스, 지정된 PRD·최종 설계 부록·보고서·UI 테스트다. 빌드·테스트·기기 조작·파일 수정은 수행하지 않았다. `t5-parent-green.log`에서 245 unit + 12 T5 UI + 2 T1 UI, failures 0, `TEST SUCCEEDED`를 직접 확인했다.

| AC | 충족도 | Given / When / Then 및 근거 |
|---|---|---|
| AC-W10-18 [Must] | ⚠️ 부분 | PRD:131~133 — “Given: 기본 카드와 다른 색 또는 사진이 있는 카드가 있다”, “When: 공통 카드로 표시한다”, “Then: 기본의 브랜드·이름·문구는 표시, 꾸민 카드에서는 숨김이다. IC·비접촉·경계 잘림은 활성이고 번호는 표시하지 않는다”. `CardStyle.swift:59`의 `isStandard`와 `PassFace.swift:26~38`이 기본/꾸민 상태를 구분한다. 사진은 `39~46`, 고정 IC·비접촉은 `47~51`, 경계 clip은 `54`에 있고 번호 출력은 없다. `RootView.swift:147`이 저장 외형을 사용한다. UI test05는 카드 밖 사진과 저장·재선택 동작을, test12는 XXXL 도달을 검증한다. 그러나 직접 확인한 `reports/simulator/final/t5-final-xxxl-basic-start.png`에서 기본 카드명·문구가 겹치고 오른쪽에서 잘려 표시된다. 기본 정보의 온전한 표시와 최종 시각 게이트가 충족되지 않았다. |
| AC-W10-31 [Should] | ⚠️ 부분 — 검증 증거 부족 | PRD:196~198 — “Given: 보조기술 사용 중 사진 한 장을 선택했다”, “When: 편집·저장 조작을 탐색한다”, “Then: 이름·선택·사용 가능 여부·현재값을 구분하고 드래그 없이 위치 변경할 수 있다”. `CardCustomizationView.swift:192~195`가 사진 이름·선택 trait를, `206~210`이 크기 label/value를, `220~236`이 위치 이름·현재값·감소/증가 버튼·경계 비활성화를 제공한다. 잠금은 `24`, `64`, `82`, `217`에 연결된다. UI test04:97~114와 step helper:450~466이 선택 사진의 버튼 이동·한국어 이름·활성 상태·실제 좌표 변화를 검증하며 test05:173~186이 카드 밖 사진의 복귀를 확인한다. 다만 UI 테스트의 `selectedPhotoID`는 DEBUG 진단이며 AX 선택 trait 검증이 아니다. 사진 선택 trait 및 X/Y·크기 현재값을 실제 보조기술 탐색으로 구분하는 증거는 아직 전달되지 않았다. 실제 VoiceOver 보충 검증 결과를 받은 뒤 재판정해야 한다. 미실행 자체를 제품 결함으로 단정하지 않는다. |

[Must] 1건 중 완전 충족 0건, 부분 충족 1건.
[Should] 1건 중 완전 충족 0건, 부분 충족 1건.

## 설계 범위 이탈

이탈 없음. PassFace·편집 화면·RootView·UITestBootstrap·UI 시험은 T5 소유 범위다. FontCatalog·폰트·앱 등록은 최종 서체 계약에, `CardIssuanceController.swift`의 `nonisolated static let` 변경은 전달된 actor constant 기계 수리 범위에 해당한다. T1~T4 기반 구현의 품질·다른 AC는 확대 평가하지 않았다.

## Part 1 판정

**SPEC FAIL.** AC-W10-18의 확인된 표시 결함을 수정하고 AC-W10-31의 실제 AX 탐색 증거를 보충해야 한다.

## Part 2: 코드 품질 리뷰

### Critical (0건)

없음.

### Important (1건)

1. **기본 카드의 고정 좌표와 확대되는 글꼴이 충돌한다.**
   `ios/FocusMate/PassFace.swift:32~37`, `ios/FocusMate/FontCatalog.swift:14~15` — 카드 크기·텍스트 offset은 카드 너비에 비례하는 고정 artwork 좌표인데, 글꼴은 `.custom(...relativeTo:)`로 시스템 글자 크기에 따라 추가 확대된다. XXXL에서는 카드명과 문구가 서로 겹치고 `PassFace.swift:54`의 카드 clip에 오른쪽 글자가 잘린다. 직접 확인한 `t5-final-xxxl-basic-start.png`가 실제 결과다. 현재 UI test12의 존재·hittable·도달 PASS는 이 표시 결함을 반증하지 않는다. **→ [동작결함] (재구현 대상 — AC-W10-18)**
   - 권고: 카드 artwork의 글자와 고정 카드 좌표에 일관된 크기 정책을 적용해 승인된 위계와 전체 문구를 유지한다. 일반 편집 도구의 Dynamic Type 대응과 구분하고, 수정 뒤 같은 XXXL 기본 카드 캡처에서 겹침·잘림 해소를 직접 확인한다.

### Minor (0건)

없음.

### 검증 필요

- **AC-W10-31 실제 VoiceOver 탐색:** 사진 한 장을 선택한 상태에서 사진 이름·선택 여부, 편집/저장 버튼의 활성·비활성 상태, X/Y·크기 현재값을 구분하는지 확인한다. X/Y는 `.contain` 아래 별도 label·값·버튼으로 구성되어 있으므로 실제 읽기 순서와 축의 맥락을 확인해야 한다. 이어 드래그 없이 위치를 변경하고 저장까지 수행한다. 현재 코드만으로 실제 탐색 실패를 확정하지 않는다.
- **XXXL 사진 도구:** `t5-final-xxxl-photo-end.png`를 직접 확인했으나 이 이미지에서는 “앞으로 뒤로 삭제” 글자 전체가 보인다. 전달된 오른쪽 삭제 잘림 관찰을 독립적으로 확정하지 못했으므로 Important에 포함하지 않았다. 별도 원본·좌표 근거 또는 수정 전 재현으로 확정해야 한다.
- PhotosPicker·Reduce Motion·최종 전체 시각 비교는 별도 진행 중인 증거다. 현재 259 PASS를 해당 수동 검증의 PASS로 확대하지 않는다. 오류 안내가 특정 캡처의 viewport 밖에 있다는 사실만으로 접근 불가 결함을 주장하지 않는다.

## Part 2 판정

**QUALITY FAIL.** Critical 0건, Important 1건이며 해당 Important는 확인된 표시 동작 결함이다.

```yaml
spec_verdict:
  verdict: FAIL
  ac_total: 2
  ac_met: 0
  ac_partial: 2
  ac_unmet: 0
  unmet_ids: [AC-W10-18, AC-W10-31]
```

```yaml
quality_verdict:
  verdict: FAIL
  critical: 0
  important: 1
  important_behavior: 1
  minor: 0
```
