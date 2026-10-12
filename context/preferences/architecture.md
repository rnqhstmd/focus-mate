# 환경·복구 설정 아키텍처

> 구성 확정 / 담당·규모 미확인. 개념 경계이며 독립 서비스/모듈이 아닙니다.

## 현재 시스템 구조

[단일 HTML](../../designs/final/animation-preview.html)의 `matchMedia('(prefers-reduced-motion: reduce)')`, `reduce`/`settingsReduce` 체크박스와 `reduced()`가 현재 모션 상태를 연결합니다. 독립 localStorage 설정 키는 없습니다. 지도·오디오·저장 복구는 각 구현의 오류 안내/재시도 함수에 함께 있으며 중앙 환경 서비스로 분리되어 있지 않습니다.

journey는 태그·할 일·선택 소리와 재생 수명·여정 복원을 소유합니다. card는 발급 ID·외형·접촉 표시 UI를 공급하고 실제 여정 생성은 journey에 맡깁니다. records는 완료/메모를 저장합니다. 이 경계는 환경 선호·지원 제한·복구 안내 계약을 정리하며 기존 도메인 데이터를 변경하지 않습니다.

## 향후 네이티브

SwiftUI 접근성/동작 설정과 플랫폼 지원·오류 안내는 iOS MVP 검토 대상입니다. 새 설정 저장 정책·동기화는 미확정 ❓이며 현재 구현으로 표시하지 않습니다.

## 주제 문서

| 주제 | 설명 |
|---|---|
| [현재 상태](../../docs/CURRENT-STATE.md) | 실제 구현과 검증 시점 |
| [MVP](../../docs/MVP.md) | 네이티브 예정/후순위 |
| [상태 계약](../../docs/FLOWS.md) | 저장 실패/손상·환경 복구 |
| [회귀 검사](../../scripts/prototype-edge-qa.cjs) | 모션·저장 거부·오디오 지원 제한 모형 |


## 개발 단계 연결

[개발 단계](../../docs/DEVELOPMENT-PHASES.md)에 단계 구분과 범위를 연결합니다. 현재 구조는 위의 단일 HTML이며 Swift 소스는 아직 존재하지 않습니다. 도메인의 구현 근거와 미반영 항목은 [status.md](status.md)에 기록합니다.
