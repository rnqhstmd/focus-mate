# T1 구현 진행

## 내부 RGR
1. 최초 준비 기본값(default tags / sound bus): 2 pass / 39 fail. 로그 t1-green-1.log. 다음 독서 선택.
2. 실제 존재 태그 선택/미존재 유지: 8 pass / 33 fail. 로그 t1-green-2.log.
3. 할 일 UTF16/scalar 경계 및 trim: 15 pass / 26 fail. 로그 t1-green-3.log.
4. 실제 소리 선택값 보존: 16 pass / 25 fail. 로그 t1-green-4.log.
5. 유효 태그 생성/metadata/선택: 18 pass / 23 fail. t1-green-5.log.
6. 빈 태그 trim 검증: 20 pass / 21 fail. t1-green-6.log.
7. 20UTF16 이름 상한: 22 pass / 19 fail. t1-green-7.log.
8. NFKC/대소문자 중복 차단: 24 pass / 17 fail. t1-green-8.log.
9. 유효 현재 payload와 확정값 getter: 29 pass / 12 fail. t1-green-9.log. 다음 소비 revalidation.

## 구현 내용
PreparationDraft.swift: 기본값/선택/UTF16상한/trim/NFKC이름검증/추가태그/확정값파생. AppModel.swift: 세션초안, 현재payload검사, 유효확정값getter, 1회소비 재검증. UI용 title/systemImage/message는 T3, resourceName은 T2에서 구현할 선언이며 T1판정에서 제외.

## GREEN 증거
최종 focused Draft/Model/Details 42 pass / 0 fail, exit0, t1-green-final.log. 원래41개 GREEN10 exit0. 새 Details1개는 기존41pass+신규1fail assertionRED후구현. 세 파일 해시 RED기준과동일.

## REFACTOR 내역
추가 정리 없음. 기존 RouteStops/JourneyPlanner를 재사용.

## self-review 결과
완전성: 세션정책·유효확정·소비 경계확인. 품질: 기존저장/여정계산재사용. 규율: 테스트불변, 순차 RGR, 신규저장/W04UI 없음. 테스트:42/0fail, 실제파일바이트쓰기0 검증.

## 우려사항
브라우저검증보류, 최종시안대조요청은 T3 뒤진행. UI표현매핑 선언은 후속 태스크 소유.
