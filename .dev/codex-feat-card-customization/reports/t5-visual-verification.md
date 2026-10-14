> 부모/독립 scoped reviewer 후속 판정: F1 카드명·문구 겹침은 두 검토자가 직접 확인한 확정 결함이다. F2 삭제 글자 잘림은 독립 reviewer가 동일 PNG에서 전체 문자를 읽었으므로 **미확정 관찰**로 낮춘다. F2만을 이유로 생산 코드를 수정하지 않으며 실제 조작/추가 원본 증거로 판단한다. 오류 안내·손잡이·실제 VO는 별도 검증 대기다. 아래는 최초 시각 검사자의 원문 기록이다.

# T5 final UI screenshot verification

판정: **FAIL — 확인된 F1 수정 필요; F2는 독립 판독 이견으로 PENDING.** 기본 크기 화면 구성·색·확인창은 PASS. 오류 안내가 캡처에 보이지 않는 시각 문맥과 실제 R40 겹침/손잡이 상태는 PENDING이다. 부모의259/259 자동 검증 통과와 별개 판정이다. 다른 앱 화면 전체의 시안 일치를 주장하지 않는다.

## 검증 범위와 원본

ROOT 절대 경로: `/Users/bonseung/.codex/worktrees/w10-card-customization/new`. DEV 절대 경로: `ROOT/.dev/codex-feat-card-customization`. 본 보고서의 `reports/...`, `t5-final-ui12-attachments/...`는 DEV 기준이다. 최종 PNG9개 절대 디렉터리: `/Users/bonseung/.codex/worktrees/w10-card-customization/new/.dev/codex-feat-card-customization/reports/simulator/final/`.

완료된 `.build/ios/Logs/Test/Test-FocusMate-2026.10.14_22-16-53-+0900.xcresult`에서 `CardCustomizationFlowTests`만 `--filter '*.png'`로 추출했다. keepAlways PNG 정확히9개이며 동영상은 추출하지 않았다. 원본9개와 manifest는 DEV `t5-final-ui12-attachments/`에, 파일 내용 그대로의 명확한 이름 복사본은 `reports/simulator/final/`에 보존했다. manifest의 deviceId는 모두 `88EC0B32-40D7-4592-A34F-E09C051CECFA` / FocusMate W10 UI다.

9개 모두 직접 열어 확인했다. 원본 **1206×2622px, 402×874pt,3x**. 뷰어 표시는942×2048로 축소되어 있었으므로 글자·배치의 관찰과 논리 좌표의 추정을 구분한다. 픽셀 단위 일치나 색 계측 PASS가 아니다. 참조 R39 `reports/design-reference/z3LCu.png`, R40 `x3PCFl.png`는 직접 본804×1748px/402×874pt/2x이며 `pencil-read.txt`·최종 `design.md`·시안 인계의 후속 PRD/서체 결정을 함께 적용했다.

이번 단계는 PNG 추출·복사와 본 보고서 작성만 수행했다. source/tests/Git/기기 변경, build/test 실행 없음. 실제27 런타임 슬롯에 간섭하지 않았다.

## 중요한 발견

### F1 — XXXL 기본 카드의 이름·문구가 겹치고 오른쪽에서 잘림

파일: `reports/simulator/final/t5-final-xxxl-basic-start.png`.

`집중동행카드`가 카드 폭을 넘어 오른쪽에서 잘리고, 바로 아래 목적 문구와 글자 높이가 겹친다. 목적 문구 역시 오른쪽으로 잘려 전체를 읽을 수 없다. 일반 크기의 동일 카드에서는 각각 분리되어 모두 읽힌다. 장식 서울 점묘가 추가된 승인 차이와 무관하게 실제 글자 레이아웃이 깨진 상태다.

정적 연결 지점은 `ios/FocusMate/PassFace.swift:32–37`: Dynamic Type을 적용한 세 Text가 카드의 고정 상대 offset에 놓이고 카드 경계에서 clip된다. 관찰은 스크린샷으로 확정되며, 수정 방법을 본 보고서에서 강제하지 않는다. 카드의 비율·IC·번호 미표시와 접근성 이름은 유지하면서 XXXL에서 카드 내 문구가 겹치거나 잘리지 않도록 처리하고 동일 상태를 재캡처해야 한다.

### F2 — XXXL 사진 도구 행 판독 이견, PENDING (결함 미확정)

파일: `reports/simulator/final/t5-final-xxxl-photo-end.png`.

최초 직접 판독에서는 `삭제` 오른쪽 일부가 잘린 것으로 보였으나, 독립 리뷰어는 같은 PNG에서 `앞으로/뒤로/삭제` 전체를 읽을 수 있다고 판정했다. 현재 glyph/actual bounds의 독립 확증이 없으므로 **확정 결함 주장을 철회하고 PENDING**으로 정정한다. 자동 테스트 통과와 별개로, 이 이견만으로 production ViewThatFits/버튼을 수정하지 않는다.

정적 관련 위치는 `CardCustomizationView.swift:213–216`,239–244다. 필요하면 원본 해상도의 glyph 경계와 실제 AX/뷰 bounds를 직접 대조해 별도 판정한다. F1 수정 범위에 묶어 임의 변경하지 않는다.

## 상태별 직접 관찰

| 복사본(모두 reports/simulator/final/) | 판정 | 직접 확인한 내용 / 제한 |
|---|---|---|
| `t5-final-r39-basic.png` | **PASS, 기본 구성** | 카드·안내·팔레트·native picker·사진/빈 안내·보존 안내·밑줄 복원·하단 흰 CTA 모두 읽힘. 좌우24pt, 카드비율, 원형 back/제목/undo 위계, 색 순서/선택 체크 유지. 복원 밑줄이 실제 보이며 picker는 문구 옆으로 붙었다. |
| `t5-final-r40-photo2selected.png` | **PASS, 선택 상태 기본 구성 / 겹침·손잡이 PENDING** | 샌드 선택과 두 번째 썸네일 선택 링,60% 현재값/슬라이더, 사진 경계 clip, IC/contactless 고정, 꾸민 카드의 identity 숨김 확인. 중앙 portrait의 손잡이는 카드 아래로 나가 clip되어 보이지 않음. R40의 오른쪽 아래 겹침/노출 손잡이와 같은 비교 상태가 아님. |
| `t5-final-confirmation.png` | **PASS, 확인창 시각 문맥** | dim 처리된 기존 모브 초안 위 native Alert. `변경 내용을 버릴까요?`, `계속 편집`, 붉은 `변경 버리기`가 전부 읽히고 분리됨. 기존 편집 화면과 선택 색이 뒤에 남아 맥락 유지. |
| `t5-final-import-error.png` | **PENDING, 오류 안내 시각 문맥** | 성공 사진1장의 선택 테두리/노출된 흰 손잡이와 편집 화면은 온전함. 오류 notice는 도구 아래 현재 화면 밖이어서 문구·재시도 읽힘을 이 PNG로 검증할 수 없음. 안내가 사라졌다고 단정하지 않음. |
| `t5-final-save-error.png` | **PENDING, 오류 안내 시각 문맥** | 샌드/사진2장/선택60%/저장 CTA의 편집 초안이 유지된 모습. 저장 오류 notice는 이 상단 viewport에 보이지 않음. 별도 스크롤 캡처 필요. |
| `t5-final-xxxl-basic-start.png` | **FAIL F1** | 본문 두 안내 문장은 큰 글자로 줄바꿈되어 읽힘. 고정 저장 CTA도 전체 읽힘. 카드 내부 이름/목적 문구는 겹치고 오른쪽이 잘림. |
| `t5-final-xxxl-basic-end.png` | **PASS, 하단 문맥** | 사진 추가/빈 안내, `사진은 이 기기에만 저장돼요. 최대6장까지 넣을 수 있어요.` 전체와 밑줄 복원이 저장 CTA 위로 올라와 읽힘. `직접 고르기`가 세 줄인 것은 좁은 큰 글자 그룹의 줄바꿈이며 글자 소실 없음. |
| `t5-final-xxxl-photo-start.png` | **PASS, 보이는 본문 / 전체 시작점 PENDING** | 사진 카드가 header 위로 일부 스크롤된 상태에서 캡처됨. 사진 clip/고정 chip와 큰 글자 안내/팔레트가 보임. 제목이 `start`라고 해서 카드 전체 시작 경계까지 찍혔다고 주장하지 않음. |
| `t5-final-xxxl-photo-end.png` | **F2 PENDING / 하단 본문 PASS** | X/Y 위치 행과50% 값, 마지막 보존 안내 전체·밑줄 복원·흰 저장 CTA는 읽힘. 앞으로/뒤로/삭제 가로 행의 잘림 여부는 독립 판독 이견으로 미확정. |

## 승인된 차이와 비차단 관찰

- PNG의 Noto 대신 승인된 서울알림체를 쓴 현재 글자 모양·자폭 차이는 오류가 아니다. 실제 기본 화면의 글자가 모두 읽히며 generic Form으로 바뀌지 않았다. 폰트 등록을 API 수준에서 검증했다는 의미는 아니다.
- 참조 카드 번호와 R40 brand badge는 후속 PRD에 따라 제거됐고, 기본 서울 점묘는 유지됐다. 기본 카드에서 점묘와 문구가 함께 보이는 자체는 승인 차이다. F1은 그 배경 선택이 아니라 XXXL의 문구 겹침·잘림이다.
- 참조 사진/53%와 현재 체크 fixture/60%는 다른 사용자 상태다. 실제 기본60% 정책을 시안 숫자에 맞춰 바꾸면 안 된다. Native slider와 X/Y/순서/삭제 도구는 최종 설계에 명시된 추가다.
- 기본 화면의 직접 고르기 묶음과 밑줄은 초기 precheck 문제를 실제로 해결한 모습이다. 사진 행은 R39/R40보다 대략10–20pt 높게 보이지만, 이 정도 간격 차이는 두 현 상태의 읽힘·계층·경계를 망가뜨리지 않는다. 이번 final pass의 material issue로 승격하거나 임의 간격 polish를 제안하지 않는다.
- 시스템 Alert 스타일, 상태바 시각·아이콘, 실제 safe area 차이는 시안 복제 대상이 아니다.

## 남은 증거와 완료 조건

1. 확인된 F1 수정 후 해당 XXXL 화면을 실제 새 binary로 다시 캡처·직접 확인한다. 기존259PASS 결과는 새 source 변경 후 필요한 focused/cumulative 게이트와 별도로 보존한다.
2. 가져오기/저장 오류의 실제 notice와 다시 시도/초안 문맥이 고정 footer 위에 함께 보이는 스크롤 캡처를 확보한다. 현재 PNG에서는 오류 문구를 확인할 수 없어 PENDING이며, 일반 성공 화면만으로 대체하지 않는다.
3. 실제27 런타임의 두 사진 겹침+카드 안에 보이는 손잡이 캡처와 실제 PhotosPicker/VoiceOver/Reduce Motion 검증은 별도 담당/슬롯에서 계속한다. import-error PNG는 한 장의 노출 손잡이가 렌더되는 증거지만, 두 장의 실제 R40 겹침 상태·제스처 성공·actual speech를 입증하지 않는다.

## 추출 명령과 파일 대응

```sh
xcrun xcresulttool export attachments \
  --path .build/ios/Logs/Test/Test-FocusMate-2026.10.14_22-16-53-+0900.xcresult \
  --test-id CardCustomizationFlowTests --filter '*.png' \
  --output-path .dev/codex-feat-card-customization/t5-final-ui12-attachments
```

| attachment name | 원본 exportedFileName |
|---|---|
| T5 basic | FCDC3EF4-3000-46DF-8AAD-C9E25703FABA.png |
| T5 confirmation | F25AD408-9250-412E-B939-44F102594095.png |
| T5 photo2selected | D9DAC847-BEEC-404B-8EA1-AB51F84B8B1C.png |
| T5 import-error | 30356A40-9A95-418B-B5C7-71179626C77E.png |
| T5 save-error | 0B02D216-291C-4FAD-961F-14C3D25F056E.png |
| T5 XXXL-basic-start | B3BDE274-5670-4EE6-80C8-8751F698703B.png |
| T5 XXXL-basic-end | 4353ADEA-6CDD-44AE-9542-5244174B707F.png |
| T5 XXXL-photo-start | B4590025-ABD2-4A68-B366-9A9E38CE4A2C.png |
| T5 XXXL-photo-end | 1CE086FE-3DE9-418F-A066-AF07181D1E3D.png |

9개 원본과 복사본의 byte-identical 복사 후 native PNG dimension을 stdlib header로 확인했다. 위 판정은 이 실행의 카드 꾸미기9개 화면으로 한정한다.


## Confirmed F1 recheck after artwork fix

The earlier nine captures remain preserved as the pre-fix evidence. Fresh focused xcresult `Test-FocusMate-2026.10.14_22-37-50-+0900.xcresult` supplies `reports/simulator/final/t5-artwork-fixed-xxxl-basic-start.png`, directly viewed after the artwork-only Dynamic Type policy. **F1 now PASS:** all card strings are separated and fully visible, while surrounding editor title/instructions/CTA still visibly XXXL. Component invariance1 + actual UItest121 passed with0failures. Detailed report `t5-artwork-fix.md`. F2 is disputed/PENDING rather than a confirmed defect; error-context/real-overlap runtime evidence remains pending. This update resolves confirmed F1 and does not relabel unobserved states as PASS.

## 실제 Photos 편집 R40 보충
최신 W11 합류 소스39파일과 동일한 독립 native 앱에서 실제 사진2장을 선택하고 드래그·크기 조절 후 생성한 `simulator/final/t5-actual-r40-overlap-handle.png`를 부모가 직접 열어 확인했다. sand 배경, 앞 red 가로사진과 뒤 blue 세로사진의 겹침, 카드 경계 clip, 선택 outline, 화면 안의 원형 resize handle이 보인다. drag/resize 각각 선택 유지와 실제 수정 저장·같은 UUID 재실행은 runtime B의 별도 수치 증거다. 실제 iPhone 증거로 간주하지 않는다.

## 최신 프로필 저장 성공 VoiceOver 초점
`simulator/final/t5-actual-profile-save-success-vo.png`를 부모가 직접 열었다. 최신 W11 연결 화면에서 저장된 사진 카드와 마이페이지, 하단 성공 안내 전체, 안내에 잡힌 VoiceOver 초점 사각형이 보인다. J01 원문 log563의 import/saveFailure/saveSuccess currentSpeech 결과가 모두 true이고 해당 C02 case는56.290초 PASS이다. 이전 import 안내의 지속 시각초점 미확정과 VO width swipe bonus 미확정은 별도로 남긴다. 실제 iPhone 확인으로 확대하지 않는다.

## 실제 보관함 원본 삭제 뒤 카드 보존
부모가 `simulator/final/t5-actual-photos-six-preserved.png`와 `t5-actual-same-uuid-after-source-deletion.png`를 직접 열어 보관함6개 및 동일 저장 카드의 사진 겹침·색·배치를 확인했다. 원본2개만 삭제한 소유권/선택/확인 UI와 H01→O01 photoID·이미지SHA256·수치배치 일치는 runtime 원문에서 별도 검증했다. 전체 persistedBytes 동일 비교는 삭제 후 두 cold launch 사이에 한정하며 삭제 전후 전체 파일바이트 비교로 과장하지 않는다.
