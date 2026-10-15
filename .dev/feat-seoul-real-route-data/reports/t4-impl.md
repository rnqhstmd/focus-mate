# T4 IMPLEMENT — 변환 CLI·출력

## 구현 내용
- scripts/build_route_data.py: build()(기준일·필수 열·노선 정리·구간 계산·줄 단위 JSON·원자 교체·크기 한도·요약), main()(종료 코드 0/2/3/4).
- .claude/config.json: projectTypes.python-scripts 등록(verify가 Python 테스트를 실행하도록).
- .gitignore: scripts/data/out/
- scripts/data/README.md: 원천·갱신 절차·규칙·형식·테스트 명령.

## GREEN 증거
- `python3 -m unittest discover -s scripts/tests -t scripts` → Ran 88, OK
- 실데이터 AC-77: reports/ac77-real-data.md

## REFACTOR 내역
- 정리 없음

## self-review 결과
- 출력 형식·요약 접두어·종료 코드 모두 테스트 대응. 실패 시 임시 파일 정리 후 기존 산출 보존.

## 우려사항
없음
