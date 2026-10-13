## 구현 내용
LocalSnapshotStore.swift: closure DI·원본 관찰·버전보호·백업쓰기와 동일바이트 readback·원본재확인·삭제완료확인.

## GREEN 증거
지정 iOS26.5 focused StorageRecoveryTests: 18 pass / 0 fail. t1-green.log TEST SUCCEEDED. 테스트 해시 불변.

## REFACTOR 내역
기존 load/save 계약 변경 없음. 추가 정리 없음.

## self-review 결과
원본쓰기0회·백업검증후삭제·충돌보호·실패원본/백업보존·정상파일거부 모두 테스트로 확인. 변경 production1개라 태스크 리뷰 발동 없음.

## 우려사항
확인/삭제 사이 외부 writer 경쟁·전원손실 내구성은 설계 범위밖.
