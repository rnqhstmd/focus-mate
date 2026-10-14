# W10 제품 인수 검증

## 판정
**ACCEPT — 실제 완료 scope 내 Must 미충족 0건.** PRD 35개 중 Must34/34, Should1/1 충족. 이는 카드 꾸미기 구현과 확보된 검증 근거의 인수이며 전체 UI 회귀 또는 실제 iPhone 출시 준비 완료 판정은 아니다.

사용자 최신 지시 “그냥 멈추고 리뷰 돌린 후 pr 올리고 머지 작업 해줘”에 따라 전체 UI115 중7개 완료·나머지108개 중단(exit130)을 인수 조건에 명시한다. 중단을 PASS로 바꾸지 않는다. 추가 사용자 승인 질문 없이 확정 계약에 따라 진행할 수 있다.

## 수용 기준 대조
PRD·설계 최종 R39/R40 기준·codemap·review-stat/review-diff·현재 안내 관련 소스·최종 리뷰 R1·보안·검증·Trust Ledger를 읽기 전용으로 대조했다. 아래 O는 구현 및 해당 범위 근거 충족이며 각 항목의 전체 UI 재실행을 뜻하지 않는다.

| AC-W10 | 제품 수용 기준 | 충족 | 확인 근거 |
|---|---|---|---|
| 01 | 저장 외형으로 진입·정체성 유지 | O | AppModel, 최종 리뷰 AC01 |
| 02 | 미발급은 발급 경로 유지 | O | AppModel, 최종 리뷰 AC02 |
| 03 | 준비색·사용자색은 초안만 변경 | O | Controller 및 실제 native RGB 변경·버리기·저장·재실행 |
| 04 | 사진 추가 후 편집 가능 | O | Controller 및 실제 PhotosPicker |
| 05 | 입력8MiB·비율0.1~10·실패 이유 | O | 현재 Controller.message, 화면·VO공유 연결, 새8개 독립 의미 검사 |
| 06 | 최대6장 제한 | O | Controller/View, 최종 리뷰 AC06 |
| 07 | 남은 자리만 선택 순서로 추가 | O | Controller 및 실제 순서 입력 |
| 08 | 선택 취소는 기존 초안·이력 유지 | O | Controller 및 실제 취소·재선택 |
| 09 | 일부 실패는 성공분 유지·실패 안내 | O | Controller, 부분실패 원인·6장 생략 동시보존 |
| 10 | 모두 실패는 초안 유지·다시 선택 | O | Controller/View, 최종 리뷰 AC10 |
| 11 | 선택 사진만 이동·크기 변경 | O | Controller/View, 실제 native gesture 선택 유지 |
| 12 | 위치·크기 경계 유지 | O | CardStyle 및 독립 경계 시험 |
| 13 | 한 단계 앞뒤·끝 조작 제한 | O | Controller 및 최종 리뷰 AC13 |
| 14 | 한 장 삭제 후 추가 가능 | O | Controller 및 최종 리뷰 AC14 |
| 15 | 역순 되돌리기 | O | Controller 및 최종 리뷰 AC15 |
| 16 | 최근20회·선택/no-op는 이력 제외 | O | Controller 및 최종 리뷰 AC16 |
| 17 | 기본 복원·한 번 되돌리기 | O | Controller 및 최종 리뷰 AC17 |
| 18 | 기본 문구·고정장식·clip·번호 숨김 | O | PassFace, 최종 시안 대조·XXXL artwork 수리 및 실제 R40 PNG |
| 19 | 변경 없이 닫기 | O | Controller 및 최종 리뷰 AC19 |
| 20 | 계속 편집은 초안·이력 유지 | O | Controller/View 및 최종 리뷰 AC20 |
| 21 | 버리기 후 마지막 저장 외형 | O | Controller/RootView 및 실제 RGB 버리기 |
| 22 | 입력 중 버리기 뒤 늦은 사진 무효 | O | Controller 독립 시나리오 및 최종 리뷰 AC22 |
| 23 | 입력 중 초안변경·저장·추가 제한 | O | Controller/View 및 최종 리뷰 AC23 |
| 24 | 6장 실제 저장·재실행 복원 | O | 실제 파일 보존 시험·동일UUID 런타임 관찰 |
| 25 | 보관함 원본 삭제 후 사진 보존 | O | 소유 원본2개만 실제 삭제·기존6개 보존, photoID/hash/치수/배치/색 동일 |
| 26 | 저장 실패 시 기존값 보존·재시도 | O | 실제 쓰기 실패 보존 시험·실제 저장오류 안내 |
| 27 | 장당1MiB·전체6MiB 및 이유 안내 | O | 저장 경계 시험·현재 message·새8개 독립 의미 검사 |
| 28 | 읽기 실패는 원본 유지·재시도 | O | LocalSnapshotStore/AppModel 관련 보존 시험 |
| 29 | v1/v2·이용정보·기존 카드 유지 | O | SnapshotCodec/카드 보충 시험 및 최종 리뷰 AC29 |
| 30 | 공통 외형만 공급·여정집계 유지 | O | AppModel 관련 시험·최종 리뷰 AC30 |
| 31 | 이름·선택·사용가능·현재값·드래그 대안 | O | 실제 VO selected/disabled/current-value, X/Y doubleTap .50→.55 |
| 32 | XXXL 60분·2014·목적지 유지 | O | 기존 T1 큰글자 회귀 근거 및 최종 리뷰 AC32 |
| 33 | XXXL 발급 본문 끝·발급 도달 | O | 기존 T1 큰글자 회귀 근거 및 최종 리뷰 AC33 |
| 34 | 프로필 실제 편집·저장·복귀 | O | 최신 focused 및 실제 profile 저장성공 발화·초점 PNG |
| 35 | XXXL 메인·프로필·편집 접근 | O | W03 합류 최신 focused 실제 스크롤·복귀 |

## 비즈니스 정합성 및 근거 경계

사진·색·배치 초안은 성공 저장 전 기존 카드를 바꾸지 않으며 정체성·한 장 정책·이용 상태를 유지한다. R39/R40 편집 구성과 기본 서울 점묘·고정 IC/비접촉·경계 잘림 계약에 부합한다. 최종 안내 수정은 입력8MiB/비율0.1~10/보존 장당1MiB·전체6MiB/부분실패·6장 생략의 이유를 화면과 VO의 같은 message에 보존하고 중복만 제거한다. 기존 generic 읽기·저장 안내와 상태·사진처리·저장·레이아웃 계약은 유지된다. 비즈니스 정합성 차단 이슈 없음.

- 부모 직접 최종 단위547PASS/0failure, Debug/Release build PASS, Node31+edge/build PASS 근거를 사용했다. 리뷰 SPEC35/35, QUALITY Critical0/Important0/Minor4 유예, 보안 최초·안내delta0/0/0이다. 이 인수 담당은 시험·빌드·기기를 실행하지 않았다.
- 안내 수정 전 최신 통합539단위+6UI=545PASS와 완료UI7은 별도 시점 증거다. 최종 안내는 corrected8 실제RED→8GREEN→부모547단위PASS 및 R1 리뷰로 확인했으며 새 문구를 실제 VO로 재관찰했다고 하지 않는다.
- 실제 PhotosPicker·native gesture·RGB·보관함 삭제·VoiceOver 관찰은 W03 합류 전이다. 핵심13소스·폰트2개 bytes 동일 및 최신 focused 회귀로 연결한다. 이후 변경한 안내2소스는 위의 별도 delta 근거로 한정한다.
- 원본 삭제 전후 동일성은 photoID·이미지hash·치수·배치·색의 증거다. 전체파일 bytes 비교는 삭제 후 두 cold launch 사이만 확인했다.
- 전체UI108 미완료는 사용자 중단 제한이다. VO width swipe bonus와 import 안내의 지속 시각초점은 미확정이고 실제 iPhone·햅틱은 W14 대기다. AC31의 실제 선택·상태·현재값 및 드래그 대안 근거와 구별하며 전체 실제기기 ready로 확대하지 않는다.

## 우선순위별 상태
- Must: 34건 구현·해당 검증 근거 충족, 미충족0건.
- Should: 1건 구현·해당 검증 근거 충족, 미구현0건.
- Could: 0건.

**최종 ACCEPT.** 위 검증 범위와 미완료 회귀·실제기기 한계를 보존하는 조건으로 개발 결과를 인수한다.
