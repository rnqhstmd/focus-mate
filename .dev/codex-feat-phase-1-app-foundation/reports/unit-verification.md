# 추가 단위 검증

선행 UI RED→GREEN과 T1 재검토 후 AppFoundationTests 14건을 target에 추가했다. 제품 기능을 추가한 단계가 아니므로 새 RED로 보고하지 않는다.

첫 실행은 13 case pass, 1 case에서 assertion6건 fail(exit65)이었다. `/unused` 경로의 모델 fixture가 실제 mkdir로 연결되는 불완전 I/O 대체였다. red-writer가 실패·성공 save 모델 fixture 두 곳에 `createDirectory: { _ in }`을 주입했다. 모든 기대값과 assertion을 그대로 유지했으며 production/UI tests 무변경이다. 실제 임시 파일을 사용하는 파일 저장 검사는 대체하지 않았다.

수정 후 전체 Unit/UI gate 결과는 실행 완료 후 기록한다.

수정 후 전체 native gate에서 제품 Unit14건 모두 pass/0 failures를 확인했다. 하네스 포함 Unit15 + UI11 = 전체26건 pass/exit0. 기대값 약화 없이 파일 경계 주입만 수정했다.

전체 리뷰의 무저장 검증 Important는 directoryCalls0과 saveFailure nil을 추가해 보강했다. 원래 실패한 fixture2곳 외의 왕복 fixture 경계를 완성한 변경이며 기대값을 약화하지 않았다. 검증 결과는 review-cleanup.md를 참조한다.
