# T3 선언 전용 스캐폴드 보고

## 작성 범위
- `ios/FocusMate/CardCustomizationController.swift`: design.md의 공개 controller 계약에 따른 enum, saving protocol, CardPhotoInput initializer, @MainActor @Observable controller initializer, 외부 읽기 전용 상태와 메서드 시그니처.
- 초기 draft는 card.style이며 optional 상태는 nil, 모든 Bool 상태·계산 속성은 false다. 변경 메서드와 discard는 no-op, save는 false, requestExit는 dismiss다.
- saver와 makeID는 initializer 시그니처만 제공하며 호출하거나 보관하지 않는다. processor만 비동기 경계 전달을 위해 private 저장한다.

## Compile + gate harness stub
importPhotos는 각 input.load를 await하고 non-nil Data만 주입된 processor.process에 전달한다. 오류는 삼키고 모든 결과를 버린다. 명시적 start/release gate를 기다리는 초안 테스트가 빈 import 스텁 때문에 assertion RED 이전에 교착되는 것을 방지하기 위한 한정된 harness stub이다. 상태 변경, 사진 추가, ID 생성, 이력, 검증, notice, 재진입 잠금 또는 세대 처리는 없다. GREEN 기능 구현이 아니다.

## 검토 및 실행 상태
- design.md의 공개 controller 계약·최종 생성자/종료 계약, 47개 테스트 초안과 test-double.swift를 정적으로 확인했다.
- 테스트 초안·실제 테스트 및 다른 source 파일은 수정하지 않았다.
- 빌드·컴파일·테스트, 에이전트 디스패치, 커밋은 실행하지 않았다. 컴파일 가능 여부와 assertion RED는 미검증이다.
- 부모가 draft를 실제 target에 반영하고 컴파일 및 assertion RED를 실행해야 한다.
- GREEN 구현자는 source의 DECLARATIONS-ONLY 표시와 harness stub를 실제 구현으로 교체해야 한다.

## 우려사항
선언 전용 단계이므로 기능 동작과 컴파일 성공을 주장하지 않는다. gate 전달은 결과와 오류를 모두 버리며 잠금·비활성 계약을 구현하지 않는다.
