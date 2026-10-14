# T1 unused-result warning 정리

Status: DONE — 허가된 테스트 한 줄 정리. 테스트 실행은 부모 담당.

대상: `ios/FocusMateTests/PreparationModelTests.swift:299`.

state.md의 T1 원본 hash와 변경 전 git hash-object 값은 동일:
`6f4d7fb5bd4104acab0d716dd8353e32176d8616`.

변경 후 git hash-object:
`b5b246a187b7e9df585a31892bf8d5a76d994594`.

변경 직전/직후 단일 행 diff:

```diff
--- before/PreparationModelTests.swift
+++ after/PreparationModelTests.swift
@@ -299 +299 @@
-        model.journeyPlan.choose(busID: "2014", from: StopPosition(index: 0, direction: 1))
+        _ = model.journeyPlan.choose(busID: "2014", from: StopPosition(index: 0, direction: 1))
```

반환값 무시를 명시했을 뿐 호출·인자·후속 검증·행동·조건·케이스 개수는 동일하다. 기존 테스트 메서드 수 21개 유지. 제품 코드 조회/검색/수정 없음. 다른 테스트 수정 없음. state.md hash는 부모가 갱신하도록 그대로 두었다.

실행 없음; 부모가 focused85를 한 번 수행한다. 시작 시 디스크 Data 여유 66Gi 직접 확인.

참조: state.md T1 hash 행, 대상 테스트 파일과 해당 파일 git hash-object. 제품 diff 조회 없음.
