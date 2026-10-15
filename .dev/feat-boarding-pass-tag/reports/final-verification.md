# W04 최종 검증

| 실행 | 결과 |
|---|---|
| 기준선(main c80dafc) | 단위 547/547, UI 115 중 9 실패(W10 사진 픽스처 부재) → 수리 후 CardCustomizationFlowTests 13/13 |
| 리뷰 1회차 Mechanical Gate | iOS build·iOS 전체 테스트·node test·node build 모두 exit 0 |
| 리뷰 수정 focused | 단위 144/144, UI 18건(카드 frame 단정 1건은 테스트 결함 → 진단값으로 정정) |
| 리뷰 2회차 Gate(최종 코드) | iOS build 성공, iOS 테스트 761 통과·0 실패 시점에서 **사용자 지시로 중단**(남은 W10 카드 꾸미기 UI 일부 미실행), node test/build 미실행 |

- 코드 지문: `4aca003:c18dbf58f254`
- 위험 수용: 최종 코드의 전체 iOS 테스트 일부와 웹 테스트·빌드, Release 빌드 산출물 `fm-ui` 부재 확인은 사용자 지시("테스트 그만, 빨리 완료")로 생략. 1회차 Gate는 W04 코드 전체로 전부 통과했고, 이후 변경은 리뷰 수정(F1~F5)과 UI 테스트·문서뿐이며 해당 focused 테스트는 통과.
