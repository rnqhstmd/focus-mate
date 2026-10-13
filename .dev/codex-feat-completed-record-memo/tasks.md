# RGR 작업 분해
T1 AC1~15: RecordSection/AppSnapshot/SnapshotCodec/AppModel의 완료·메모 저장 계약 전체.
RED: RecordSectionTests.swift, RecordStorageTests.swift.
IMPLEMENT: 모델 순수동작 → 기존 저장경계 연결, 한 테스트씩 focused 통과.
같은 컴포넌트/파일 공유 AC를 한 태스크로 묶는다. 작업들은 병렬하지 않는다.
테스트선작성 후 신규 API 동작없는 선언껍데기로 컴파일하여 실제 assertion RED 확인 제안. 사용자 승인 대기.
