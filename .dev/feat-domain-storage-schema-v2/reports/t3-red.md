# T3 RED 보고

- 테스트 파일: ios/FocusMateTests/StorageV2Tests.swift (클래스 StorageV2Tests, 8케이스)
- 실패 확인 명령: `python3 scripts/check-ios.py test ios/FocusMateTests/StorageV2Tests.swift` (프로젝트 루트). 로그 사본은 세션 scratchpad t3.log.
- 결과: 8케이스 모두 실패(컴파일 성공, assertion/오류로 실패)

## 케이스와 결과, 깨짐 명명 (각 테스트 본문 위 주석에 있음)
1. AC1 v1 파일 읽기: 실패 (load가 "corrupt"를 던짐)
2. AC1 v1 읽기 시 createDirectory/writeData 0회: 실패 (load가 "corrupt"를 던짐)
3. AC2a 파일 없음 저장: 실패 (version이 1, 기대 2)
4. AC2b v1 로드 후 저장 == G2 바이트: 실패 (load가 "corrupt"를 던짐)
5. AC3 읽기 오류 표 (7입력): 실패. 개별 실패는 "v2 records 누락"뿐이다. 기대 .corrupt, 실제 .unsupportedVersion(2).
6. AC3 저장 차단 표 (7입력): 실패. 개별 실패는 "v2 records 누락"뿐이다. 기대 writeBlocked(.corrupt), 실제 writeBlocked(.unsupportedVersion(2)).
7. AC4a 내용 불일치 v1: 실패. 기대 invalidState(.inconsistentStage), 실제 corrupt(v1을 구조 실패로 처리함).
8. AC4b v2 파일 + 쓰기 실패: 실패. 기대 .writeFailed, 실제 writeBlocked(.unsupportedVersion(2)).

## 기대 통과(특성 고정) 분류
- 케이스 5와 6은 표 기반이라 케이스 단위로는 실패다. 표 안에서는 버전 3, 999, 0, 빈 파일, version 없음, `"2"`의 6입력이 현재도 통과한다(실패 메시지에 나온 입력은 "v2 records 누락" 하나뿐). 이 6입력은 기대 통과(특성 고정)이고, 근거는 현행 헤더 판정이 이미 이 분기를 처리한다는 점이다.
- 케이스 5와 6의 "v2 records 누락"은 기대 RED다.
- AC4a와 AC4b는 현재 v1 형식 기준이 아니라 v2 형식 기준으로 실패한다(기대 RED).
- 순수 통과 케이스는 없다.

## 우려사항
- 표 기반 케이스는 첫 실패 입력만이 아니라 모든 입력을 검사한다. 실패 메시지에 입력 이름이 들어간다.
- 케이스 5와 6을 입력별로 분리하지 않았다.

## 참조한 파일
- .dev/feat-domain-storage-schema-v2/prd.md
- ios/FocusMateTests/AppFoundationTests.swift (스타일·헬퍼 참고, 수정 없음)
- 프로덕션 코드는 읽지 않았다.
