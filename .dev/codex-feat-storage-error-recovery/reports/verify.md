# gx-verify PASS

직접 실행 시각: 2026-10-13T22:55:05.468544+09:00

Node31+edge PASS exit0, npm build PASS exit0. iOS26.5 Unit141+UI21=162 tests/0fail TEST SUCCEEDED exit0. iOS Debug build PASS exit0. 추가 Release build PASS exit0. verify-*.log 참고.

경고 baseline0 대비 config 대상 Node/test/Debug build 신규경고0. 추가 Release metadata skip1은 baseline-ios.log의 기존 AppIntents 의존성없음 경고와 동일한 도구 노이즈이며 신규 소스경고가 아님.

Fingerprint helper exit0, 형식검사 PASS: 858ed5d:8a746a4dff50. 임시별도objectstore 사용. source/test 변경이후 최신 전체 실행이며 commit/PR 게이트 해제. 테스트6파일고정, W08 통합재검증 포함. 실기기/VO 실제포커스/iOS27은 미검증.
