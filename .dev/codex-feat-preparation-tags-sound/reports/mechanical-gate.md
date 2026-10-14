# 통합 기계 검증

실행 기준 최신 main8ac11c3 + W03 작업트리.

| 검증 | 결과 |
|---|---|
| npm run build | exit0 |
| npm test | 31 pass /0fail +edge QA PASS, exit0 |
| iOS build | BUILD SUCCEEDED, exit0 |
| iOS test | 단위366 +화면99 =465 pass /0fail, exit0 |

전용 simulator88ABB031-C48A-4DA0-B15C-14787702E647 /iOS26.5. 병렬 빌드·테스트 실행 없음.

테스트 종료2026-10-14 23:05:27 KST. xcresult .build/ios/Logs/Test/Test-FocusMate-2026.10.14_22-38-19-+0900.xcresult. 실제 로그 integrated-*.log와 reports/integrated-gate.jsonl.

기존 경고 재출력은 CardIssuanceView14 actor, JourneyStartModelTests128 unused return, AppIntents metadata skip. W03 변경으로 추가된 경고 없음. 상세기존증거 reports/warning-provenance.md.

전체 코드·보안 리뷰 완료 후 phase-complete의 fresh gx-verify는 별도 신규 실행. 이 보고서를 최종 verify 결과로 재사용하지 않음.
