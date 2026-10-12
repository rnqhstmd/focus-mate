# Phase 0 검사 작업 배경

현재 HTML·실행용 복제본·Pen/레이어·문서의 기준선을 연결하고 변경 누락을 검사한다. 제품18·회귀21·Pen42는 서로 다른 분류이며 자동 검사와 실제 화면 검증을 분리한다.

## 요구사항

원본/복제본·필수 파일 불일치, 화면/노드 연결 누락, 제품 목록 누락, 필수 수동 검토 삭제, 잘못된 CLI 인자를 차단한다. 실제 브라우저 확인 대기2건은 완료로 선언하지 않는다.

## Audit Summary

초기 HIGH2건을 실패 테스트부터 수정했으며 재감사 CRITICAL0/HIGH0. 태스크 재리뷰 SPEC5/5 PASS, QUALITY PASS. 위험 수용 없음.

## Validation

27개 leaf / Node31개 집계 통과, 기존 VM 회귀 통과, npm build 통과, 경고0. 실제 연결 검사18/21/42·복제파일23개 errors0. 원본과 실행용 HTML은 metadata만 추가하며 UI/저장 동작을 변경하지 않음.

## Remaining product checks

최신 승차 단말기 실제 브라우저 렌더·터치 및 tags 중간 화면의 Pen/브라우저 확인은 pending. 이 PR은 기준선 검사 작업 완료이며 제품 Phase0 전체 완료가 아니다. 네이티브 도메인 FR/status를 완료로 바꾸지 않음.

## 산출물

PR: https://github.com/rnqhstmd/next-step/pull/1
기준선 검사·문서 작업 파이프라인 완료. 실제 화면 확인2건은 대기로 유지합니다.
