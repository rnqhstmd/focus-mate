## Testability 평가

### Score:8/10 PASS
순수PreparationDraft/TagEditor:실제값테스트,mock없음 AC1~9/19.
AppModel:실제store와I/Oclosure경계spy,throw전호출증가,write0/snapshot및바이트불변,확정/요청소비·시간무효AC11~13/23.
Controller:protocolfakeplayer/factorycontinuation/sleepgate로late완료/nooverlap/fade120·60ms/loop-1/throw·preparefalse·playfalse/none0/복귀0 AC17~22.
AVadapter/WAV:실제Bundle.main4샘플URL·decode·factory성공,sourcepathfallback금지,복사바이트비교별도. fake만으로리소스포함주장안함.
SwiftUI:실제XCUITest role/name또는프로젝트ID컨벤션으로선택/입력/버튼enabled/시트취소·왕복/큰글자/숨긴컨트롤미노출 AC1~16/19~25.

### 동작/표현 분류
상태검증/폼가드/라우팅/컨트롤러/UI조건부렌더는동작.색/여백/폰트/테두리/장식모양은표현으로테스트밖.

### 러너
XCTest apphost와XCUITest이미존재,check-ios.py test파일단위focused실행.파일stem=class명일치.

### RED 격리
새타입compileRED뒤무동작선언만추가,behaviorassertRED실행후GREEN.기댓값손도출리터럴.테스트전용제품메서드금지.固定yield/sleep대신explicitexpectation+continuation해제,모든task정리.

### 검증 범위 한계
단위테스트stopAPI만호출해시트저장/취소/이탈5갈래UI연결을검증했다고주장하지않음. 실제UI연결검사필요. 자동접근성attribute와실제VoiceOver포커스수동검증구분. actualWAVdecode는청취품질아님.

### 판정
TESTABILITY PASS:8/10. critic두MUST보강뒤진입.
