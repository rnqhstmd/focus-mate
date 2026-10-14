# T2 구현 진행

## 내부 RGR
1. 초기 선택/시트 초기화: 45 pass / 22 fail, t2-green-1.log.
2. 임시 소리 선택: 47 pass / 20 fail, t2-green-2.log.
3. factory/loop/시작120ms·중지60ms: 57 pass / 10 fail, t2-green-3.log.
4. 이전 종료 Task 완료 대기: 57 pass / 10 fail. t2-green-4.log.
5. generation/active/Task취소와 stale 성공·오류 차단: 64 pass / 3 fail. t2-green-5.log.

## 구현 내용
SoundPreviewController: 사용자 시작만 factory, loop-1/volume0, 시작120ms/중지60ms, oldstopTask await, generation·active·Task취소 검사(stale 성공과 catch 둘 다), loading중 재입력취소, none 요청0, 중복stop멱등, beginSelection세션owner 재사용. AVSoundPreviewPlayer: 실제AVAudioPlayer forward, 주입bundle 존중 및 누락/none throw. AppModel은 단일controller수명/DI 추가. PreparationDraft의resourceName 매핑과 Resources/Audio 승인WAV4개동일복사. shared등록파일은T1로직유지, 추가필드/매핑만T2대상.

## GREEN 증거
직접 focused 67 pass / 0 fail, exit0, t2-green-final.log. 기존42+신규25 모두통과. 다섯 테스트파일 RED해시 동일. 실제앱번들 SHA golden4개·AVdecode/adapter.prepare 성공 및 누락bundle/none throw. bytes동일 reports/audio-copy.md.

## REFACTOR 내역
추가 정리 없음. async 유효성검사를 isCurrent로 공유.

## self-review 결과
완전성: 선택/반복/페이드/취소/늦은결과/단일owner/번들 포함. 품질: protocol과외래factory/sleep 경계, AV표준API만사용. 규율: 테스트불변/순차RGR/실제저장0 유지. 테스트:67/0fail, 실제번들과fake효과경계 구분.

## 우려사항
겹침 테스트의 초기 await없는 중간 구현에서도 양성실행순서 assertions는 통과했다(t2-green-3.log). 현재코드는oldstopTask await를 명시해 정확한 장벽이 있으나, B 준비완료 후 oldgate를 계속 보류하는 음성 관찰을 더 강하게 만들 여지는 있다. 독립리뷰에서 테스트품질/추가범위 판정 요청. 실기기 청취·실제VO·UI lifecycle연결은 별도 T3/최종검증.

## FIX R1 검증
제품코드byte동일유지. 격리red-writer가2겹침공통helper만보강; 실제중지barrier제거변이65pass/2targetfail 확인. 원본복원뒤직접67pass/0fail exit0 t2-green-r1.log. 새해시fd1a0b5f6eb2a57510d650663d484f4f47b1f904, 다른4테스트해시이전기준유지. self-review우려사항의검출력문제보강완료,독립재리뷰대기.
