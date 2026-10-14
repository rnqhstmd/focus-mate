# W10 Testability 평가 (초안)

설계작성자와 다른 기존 상위 설계석을 thread limit 때문에 재사용했다. 실제 실행 모델/effort는 미확인이며 계획값과 관측값을 혼동하지 않는다. 읽기전용 평가, 직접시험실행없음.

## 점수·판정
7/10 조건부 PASS: 순수값/Controller DI/실제파일/ImageIO경계는타당하지만 독립RED에필요한오류API/UIfixture계약을 보강한뒤진입한다. 표현및실제VO/CUA환경제약은감점사유가아님.

## 필수 계약 보강
1 값타입생성자/internal접근,invalidCardPhoto payload와Storeerror포장.
2 LocalSnapshotStore전체init/validateCardPhotosdefault/실행순서.
3 import성공·실패·생략조합별notice정책.
4 invalidcolor/nonfiniteplacement/unknownselection/discard후호출.
5 saverfalse+nilfallback/ID불일치/notReady오류.
6 save성공/실패/discard후draft/history/selection/import/notice상태.
7 UI진입·저장·취소·사진선택·조작안정selector.
8 DEBUGfixture인자/지연해제/compactdiagnosticJSON/재실행.
9 actualJPEG/PNGalpha/HEIC/orientation/WebP fixture출처/독립기대값.
10 모델+schema/store를Controller앞으로병합.

## 전략
- CardStyle 순수값: finite RGB,수/ID,positive dimensions,ratio/position/width경계,장당/전체byte. dummyData는구조시험에만사용,합계검사를장당보다우선.
- 실제ImageIO: 진짜HEIC·alpha영역PNG·비대칭색/EXIForientation·정상JPEG와손상본문. 재decode/치수/방향/alpha/실바이트검사;lossyJPEG원본바이트동등성요구금지. 정확8MiB성공은유효이미지를별도확인,확장자변경/dummyData불가.
- Controller: 고정ID/fakeSaver/continuation loader&processor로순서/부분성공/세대취소/no-op/20undo/초안쓰기0회/lock/저장실패유지검사. 임의sleep사용금지.
- Codec: 고정v1/v2→defaultstyle,新v3golden. v3stylemissing/reject;모르는키v2정책보존,version4이상unsupported. LegacyDTO내부생성에결합하지않음.
- Store/Model: 실제UUIDtempfile/newstore/relaunch·6사진내용/ID/위치/순서·다른section최신값·쓰기오류원본bytes동등성·사진손상load→W13백업. writeclosurethrow를전원차단내구성으로해석금지.
- UI: 조건별기본텍스트/조작가능/선택/AX값/번호없음,stylepixel스냅샷동등성금지. 실제Controller경유DEBUGfixture와실제PhotosPicker분리. actualVO/ReduceMotion직접확인별도.
- AC32: 기존LargeTextUITests와준비minutes60/bus2014/destination검증. hittable만으로선택성공판정금지.
- AC33: 끝hint가버튼위에전체도달하고발급가능한지. 이미PASS면불필요기능수리하지않는다. wheel20초기준유지.

## AC매핑
01/02 Model+UI;03 Controller;04 Processor+Controller+UI;05 ImageIO경계;06/07/08 Controller+UI;09/10 import실패;11/12 placement;13/14 layer/delete;15/16/17 undo/default;18 conditionalUI+직접화면;19/20/21 exit+실파일;22/23 suspendedimport;24 실제이미지+파일+UI재실행;25 source삭제통합+별도Photos;26 실제파일DI재시도;27 한도;28 손상원본보존;29 v1/v2→v3;30 최신snapshot외형;31 AX대체조작+별도VO;32/33 기존큰글자.

## 러너와 RED
XCTest클래스명=파일명. FOCUSMATE_SIMULATOR_ID=D3BB49D7-3834-4BC9-B910-1CADD9E036E1 python3 scripts/check-ios.py test {ios/FocusMateTests,ios/FocusMateUITests}/파일.swift.
API부재compilefail은RED아님. 선언용stub후actualassertionFAIL확인, fatalError/skip/test별분기금지. 기존처음부터PASS는특성회귀로구분. v3출력기대수정은test-author만,legacyfixture삭제금지. 전체회귀는 부모가 파이프라인 경계에서 실행한다.
