# W09b 보안·정책 재감사

상태: PASS_STATIC. 기존 CRITICAL0/HIGH0/MEDIUM2 중 MEDIUM2건 모두 닫힘. 현재 확인된 RISK/POLICY/GAP/ASSUMPTION은 각0건이다. W18 생산 소스와 W17은 감사 범위에서 제외했다. 이번 재감사에서 소스 변경·빌드·테스트 실행은 하지 않았다.

## 기존 발견 종료

### RISK/MEDIUM — UTF-16 기록 ID의 UI identity 충돌: CLOSED
- RecordsAnalyticsView.swift:161,163의 최근 기록·최근 메모 두 ForEach가 모두 RecordsAnalyticsRow를 사용한다.
- 같은 파일:261~264의 행 ID는 Array(record.id.utf16)이며 원본 record를 보존한다. Swift String canonical equality로 서로 다른 원본 행을 합치던 경계가 제거됐다.
- RecordsAnalyticsRowTests의 두 사례는 canonical-equivalent이지만 UTF-16이 다른 두 행 ID와 각 원본 task/memo 보존을 검사한다. 앱 Adapter와 원본 ID 재검증도 기존 UTF-16 계약을 유지한다.
- t1-green-w09b-regression.log:569의 RowTests2건/0fail을 포함해 단위30건/0fail(:639~641)을 직접 읽었다. 실제 Unicode 두 행의 화면 선택을 별도로 관찰한 것은 아니며, 이번 종료는 수정된 UI identity 연결·회귀 단위 증거에 근거한다.

### GAP/MEDIUM — 신규 UI 통과 주장과 0건 로그의 불일치: CLOSED
- reports/t3-impl.md는 이전 t3-green-run.log가 실행0건으로 무효임을 명시하고 대체 실행을 연결했다.
- reports/t3-ui-actual.log:1745에서 기능UI4건/0fail, :1801~1803에서 캡처1 포함 실제5건/0fail, :1811 TEST SUCCEEDED를 직접 확인했다.
- 후속 .dev/codex-system-surfaces-w18/reports/t1-green-w09b-regression.log:1114에서 기능UI5건/0fail, :1170~1172에서 캡처1 포함 UI6건/0fail, :1180 TEST SUCCEEDED를 확인했다. 여기서 단위30건은 선택된 회귀 묶음이며 기존52건에 단순 더해 전체 테스트 수로 설명하지 않는다.

## 유지된 정합성
- 순수 집계는 날짜·기간·유한 시각·분 범위·필수 문자열·색·UTF-16 중복 ID를 검증한 뒤 적격 기록을 추린다. 손상 일부를 건너뛰는 성공 경로를 발견하지 못했다.
- RecordsAnalyticsAdapter는 전체 RecordSection.validate 및 모든 변환/집계 오류를 unavailable로 처리한다. nil 원본과 정상 빈 section을 구분한다.
- 보고서에는 메모·할 일·원본 ID가 없다. 최근 원문을 담는 앱 전용 Content는 Codable이 아니다. W18 공유 스냅샷의 최소 투영·파일 게시 안전성은 이번 판정에 포함하지 않는다.
- 분석의 최근/메모 이동은 외부 링크를 추가하지 않고 기존 navigation과 editor를 사용한다. 선택/편집 직전 최신 원본 ID를 UTF-16으로 재확인한다.
- 분석 변경은 원본 저장 형식·타이머·완료 저장 정책을 변경하지 않는다. 신규 analytics 시드는 UITestBootstrap의 DEBUG 범위다.
- 상위3+묶음 기타의 정적 구성과 전체 태그 선택이 분리돼 있다. 실제 이름 기타와 묶음 remainder의 식별자를 구분한다.

## 실제 증거와 남은 경계
- reports/visual-verification.md는 부모가 직접 연 Simulator 캡처와 승인 시안의 차이를 명시한다. 시안의 지도 위 모달 프레임과 현재 전체화면 navigation을 픽셀 일치로 주장하지 않는다.
- 해당 문서는 초기 캡처가 후속 UTF-16/태그 구성 수정 전임을 명시한다. 후속 회귀 로그의 캡처 성공만으로 최종 이미지를 직접 대조했다고 판정하지 않는다. 이 감사자는 이미지 자체를 새로 열지 않았다.
- 큰 글자 UI 동작 통과와 코드/XCUI 접근성 요약은 실제 VoiceOver 청취·시스템 Reduce Motion 설정 전환·실기기 증거를 대신하지 않는다. 이 한계는 문서에 기록돼 있어 새 누락 발견으로 집계하지 않는다.
- 전체 회귀·빌드는 사용자 지시대로 W18 이후다. 현재 정적 감사 통과를 전체 verify 완료나 main 병합 승인으로 확대하지 않는다.

추가 확인 사항 없음. 감사가 완료되었습니다.

```yaml
security_verdict:
  status: PASS_STATIC
  critical: 0
  high: 0
  medium: 0
  risk: 0
  policy: 0
  gap: 0
  assumption: 0
  previous_medium_closed: 2
  full_verification: deferred_until_after_W18
  device_voiceover: unverified
```
