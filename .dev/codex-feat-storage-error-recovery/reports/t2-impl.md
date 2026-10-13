## 구현 내용
AppModel.swift: 공통 읽기·retry·확인캡처/취소·명시적 확인 후 보존정리·실패상태·재진입가드.
## GREEN 증거
StorageRecovery18 + AppRecovery16 = 34 pass / 0 fail, t2-green.log. 두 테스트 해시 불변.
## REFACTOR 내역
loadSnapshot으로 1회 시작/재시도 읽기를 공유. 기존 hasLoaded 계약 유지.
## self-review 결과
정상/loading/확인없는호출·중복/reentry는 I/O없이 차단. 실패시 failed 유지, 성공만 empty/cardEntry. 새 retry/request 실패안내 해제. 생산1개·fix없음 태스크리뷰 제외.
## 우려사항
없음.
