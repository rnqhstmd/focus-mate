# Alert helper 패치·회귀 범위 리뷰

판정: 패치 및 7개 클래스/83건 재검증 계획 적절. 실행 통과는 아직 미판정.

## 1. 호출 범위
현재 ios/FocusMateUITests 전체에서 alertButton 참조를 검색했다. 정의를 제외한 호출은 scope JSON의 7개 파일에만 존재한다. 호출 래퍼도 이 파일들 안에 있다.
- BoardingLargeTextUITests 2
- JourneyLifecycleSafetyUITests 14
- JourneyAbandonUITests 30
- RouteDataUITests 10
- NewJourneyUITests 19
- ActiveJourneyMainUITests 3
- WidgetEntryUITests 5

각 파일의 test 함수 수를 별도로 계산해 합계 83건을 확인했다. full-failure-classification.json의 실패 클래스 중 이 범위를 벗어난 클래스는 없다. 실패한 47건뿐 아니라 같은 helper를 소비하는 기존 통과 사례까지 재실행하는 범위다.

## 2. unique leaf의 의미
패치와 현재 helper가 일치하는 것을 읽어 확인했다. 동일 ID+정확한 label을 가진 후손 button이 있는 후보만 제외하므로 부모/자식 중복 체인은 최하위 후보로 수렴한다. 같은 조건의 독립 sibling 두 개는 각각 일치 후손이 없어서 leaf 두 개로 남으며 성공 분기에 들어가지 않는다. 두 sibling이 각각 자식 체인을 가져도 마지막 leaf 두 개가 남는다.

ID 후보가 없을 때만 단일 alert 내부의 label fallback을 사용하며, 이 경우도 leaf가 정확히 하나여야 한다. firstMatch·좌표 탭·isHittable 필터로 임의 한 버튼을 선택하지 않는다. 따라서 정적 검토상 실제 sibling 중복을 숨기는 변경은 발견하지 않았다. 실제 AX 트리에서 부모/자식 중복이라는 진단 및 hit 가능성은 재실행 증거로 확인해야 한다.

## 3. 불변 근거
full-run-file-hashes.json의 1,094개 항목을 현재 파일 SHA-256과 직접 비교했다. 차이는 ios/FocusMateUITests/UITestLaunchSupport.swift 한 파일뿐이었다. 앱/Shared/확장/단위/UI 테스트 디렉터리의 현재 Swift 파일을 별도로 열거했으며 manifest 누락은 없었다. 이 검토 시점의 생산 코드 및 기존 테스트 본문 불변 근거로 적절하다. 재실행 종료 후에도 같은 조건을 확인해야 한다.

## 4. 결과 표기 조건
- 첫 전체 실행: 부모가 제공한 iOS exit 65, 단위 1,426 통과, UI 317 중 270 통과/47 실패를 원래 결과로 보존한다. 이 리뷰에서는 원본 전체 로그를 다시 집계하지 않았다.
- helper 수정 후: 7개 클래스 83건의 실제 실행 수·통과/실패·명령 exit를 별도 기록한다. 아직 실행 전이므로 통과라고 쓰지 않는다.
- 두 isHittable 실패는 duplicate AX 진단만으로 해결 처리하지 않는다. 해당 최대 글자 두 사례의 실제 assertion 통과를 반드시 확인한다.
- 재실행 실패가 있으면 helper 문제/다른 원인을 다시 구분하고 미해결로 남긴다. 83건 모두 통과하고 생산 불변이면 미영향 234건의 최초 통과와 합쳐 영향 범위 회귀 검증이 완료되었다고 설명할 수 있다.
- 최초 전체 명령이 성공했다고 바꾸거나 수정 후 UI 317건 전체를 다시 실행했다고 쓰면 안 된다. 다른 config 5명령의 최초 성공 결과도 각각 보존한다.

테스트·빌드·시뮬레이터 조작은 수행하지 않았다. 보고서만 작성했으며 소스/테스트 파일은 변경하지 않았다.
