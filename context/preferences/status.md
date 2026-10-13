# 환경설정 구현 추적

수정일: 2026-10-13. 도메인 구성은 사용자 확인으로 확정했고 담당자·사용자 규모는 ❓입니다. ID와 AC 번호는 이 도메인 안에서만 유일합니다. `[웹]`과 `[iOS]`는 별도 구현 범위입니다. `[iOS·P5]`의 P 번호는 [개발 단계](../../docs/DEVELOPMENT-PHASES.md)의 담당 Phase입니다.

## 범례

- ✅ 반영됨 — 현재 코드에 구현됨. 웹 VM·iOS 시뮬레이터 검증은 실제 브라우저·iPhone 사용성 완료를 의미하지 않음
- ⬜ 미반영 — 네이티브 구현 또는 실기기 검증 전
- 🚫 폐기 — 사용자 확인 후 범위에서 제거한 항목

## 요구사항 원장

| ID | 요구사항 | AC | 상태 | PR |
|---|---|---|---|---|
| FR-1 | [웹] 동작 줄이기 | AC-1: matchMedia와 두 체크박스를 동기화한다. 독립 영속 설정 키는 없다. | ✅ | 코드 기준선 [54dde93](https://github.com/rnqhstmd/next-step/commit/54dde93280f41bd6c8a497625869e42e904e389b) |
| FR-2 | [웹] 환경 복구 | AC-2: 지도 재시도·소리 재시도/무음과 지원 실패를 안내하며 여정을 보존한다. | ✅ | 코드 기준선 [54dde93](https://github.com/rnqhstmd/next-step/commit/54dde93280f41bd6c8a497625869e42e904e389b) |
| NFR-1 | [웹/VM] 제한 안내 | AC-3: 저장 거부·손상·AudioContext/햅틱 미지원에서 성공을 과장하지 않는다. | ✅ | 코드 기준선 [54dde93](https://github.com/rnqhstmd/next-step/commit/54dde93280f41bd6c8a497625869e42e904e389b) |
| FR-3 | [iOS·P2~P5/P5] 접근성·모션 | AC-4: VoiceOver·Dynamic Type·시스템 모션 선호를 적용한다. 각 Phase가 새 화면에 적용하는 것을 완료 기준으로 두고, P5는 설정 화면과 전체 점검을 맡는다. | ⬜ | - |
| NFR-2 | [iOS·P6] 실기기 사용성 | AC-5: 큰 글자·드래그·햅틱·오디오 중단과 청취 품질을 검증한다. | ⬜ | - |
| FR-4 | [iOS·P5] 저장 오류 복구 | AC-6: 손상·미지원 버전·내용 불일치·읽기 실패에서 재시도와 원본 검증 백업 뒤 정리를 제공한다. 명시적 확인 전에 저장물을 바꾸지 않으며 외부 내보내기는 제외한다. W13 AC-1~8. | ✅ | [PR #10](https://github.com/rnqhstmd/focus-mate/pull/10) |

## 근거와 개발 연결

- FR-1 / AC-1: reduced.
- FR-2 / AC-2: mapRetry / soundMessage.
- NFR-1 / AC-3: 도메인별 storage 플래그 / issueHaptic.
- FR-3 / AC-4: 네이티브 구현 전.
- NFR-2 / AC-5: 실기기 검사 전.
- FR-4 / AC-6: W13 재시도·확인/취소·원본 검증 백업 뒤 정리·실패 안내 구현. iOS 26.5 Unit141/UI21 및 웹31+edge, Debug/Release 빌드 통과([완료 검증](../../.dev/codex-feat-storage-error-recovery/reports/verify.md)). 실기기·VoiceOver 실제 포커스는 W14에서 확인한다.

[현재 동작](../../docs/CURRENT-STATE.md) · [화면 계약](../../docs/FLOWS.md) · [개발 단계](../../docs/DEVELOPMENT-PHASES.md). 현재 요구사항 원장은 코드와 마지막 직접 VM 검사로 작성했으며 자동 git 동기화는 아직 실행하지 않았습니다.

<!-- gx-sync
git-head: -
svn-revision: -
pr-merged-at: -
-->
