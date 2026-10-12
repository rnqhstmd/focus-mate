# 실제 녹음 기반 소리 샘플 교체

2026-10-12. 사용자가 기존 소리를 탁하고 지지직거린다고 느낀다는 피드백에 따라 원본 음원과 재생 방식을 바꿨다.

## 확인과 선택

기존 파일은 24 kHz mono DSP 합성 소리였고 3 kHz 초과 에너지를 거의 제거한 상태였다. 샘플레이트만으로 음질을 판단할 수 없지만, 실제 녹음의 질감이 없고 고음을 과도하게 줄인 점은 탁한 인상의 원인 후보다. 이는 파일과 코드에 근거한 해석이며 직접 청취한 판단은 아니다.

원본 녹음과 앱 포함·재배포 조건을 함께 찾았다. BigSoundBank, Freesound, OpenGameArt의 후보를 확인했고, 최종적으로 원본 WAV를 로그인 없이 제공하며 각 파일에 CC0를 명시한 BigSoundBank 샘플 4개를 선택했다.

| 앱 소리 | 채택 원본 | 선정 이유 |
|---|---|---|
| 빗소리 | [Rain on car windshield · 1295](https://bigsoundbank.com/rain-on-car-windshield-s1295.html) | 실제 유리 빗방울 녹음, 48 kHz·24-bit 원본 |
| 숲 소리 | [Forest: On the Edge · 0905](https://bigsoundbank.com/forest-on-the-edge-s0905.html) | 새·바람이 있는 48 kHz stereo 현장 녹음 |
| 버스 주행 | [London bus · 0644](https://bigsoundbank.com/london-bus-s0644.html) | 실제 2층 버스 차내, 48 kHz stereo 원본 |
| 핑크 노이즈 | [Pink Noise · 0432](https://bigsoundbank.com/pink-noise-s0432.html) | 의도적인 노이즈 선택은 유지하되 백색 대신 핑크 노이즈 샘플 제공 |

모든 채택 음원의 작성자는 Joseph SARDIN이다. [제공자의 라이선스](https://bigsoundbank.com/licenses.html)와 각 파일에서 CC0 및 편집·재배포·상업 이용 허용을 확인했다. 출처와 원본 SHA-256은 [SOURCE.md](../designs/final/assets/audio/SOURCE.md), `sources.json`에 남겼다. 버스 녹음은 런던이며 앱의 가상 서울 경로 녹음이라고 표현하지 않는다. 핑크 노이즈는 현장 녹음이 아닌 스튜디오 노이즈다.

검토했지만 채택하지 않은 후보:

- [Freesound · Long and quiet bus ride](https://freesound.org/people/Rolly-SFX/sounds/626798/): CC0, 96 kHz·24-bit지만 원본 432 MB와 다운로드 로그인 조건이 있어 이번에는 제외했다.
- [OpenGameArt · Park ambiences](https://opengameart.org/content/park-ambiences): CC0·48 kHz 원본 다운로드를 확인했으며 숲 소리의 대안으로 남겼다.
- [Freesound · london bus inside.wav](https://freesound.org/people/Walter_Odington/sounds/26276/): 제작자가 저역 왜곡 구간을 명시해 이번 품질 개선용에서 제외했다.
- [Rain and Thunder](https://bigsoundbank.com/rain-and-storm-s0124.html): 큰 천둥이 있는 설명 때문에 일정한 여행 배경음 후보에서 제외했다.

## 파일과 재생 개선

자연 녹음은 음량 변동이 작은 구간을 골라 40초, 핑크 노이즈는 30초의 루프로 만들었다. 원본 샘플레이트·채널 수를 보존하고 출력은 16-bit PCM WAV다. 강한 저역통과 필터·전대역 노이즈 제거를 적용하지 않는다. 2초 equal-power 교차 연결, DC 제거와 RMS -26 dBFS 보정을 적용한다. 자연스러운 소리 변화는 평탄화하지 않는다.

재생 시작은 120 ms, 중지는 60 ms 페이드한다. 갑작스러운 시작·정지로 생길 수 있는 클릭음을 줄이도록 변경했고, 중지 후 노드를 분리한다. 버전이 붙은 새 파일명으로 기존 브라우저 캐시의 합성 파일과 구분한다. 선택·멈춤·복구 흐름은 유지한다.

현재 앱 파일의 클리핑 표본은 0이다. 디지털 루프 경계 변화량은 일반 인접 변화량의 99백분위 이하이며, 실제 Web Audio로 두 바퀴 렌더링한 결과도 같은 범위 안에 있었다. 이 결과는 청취 선명도를 보장하지 않는다. 실제 스피커·이어폰 청취 평가는 수행하지 않았으므로 사용자에게 교체한 샘플을 제공한다.

## 반영과 검증

HTML, 로컬 프로토타입, 게시용 패키지와 Pen **개선 R10 · 소리 선택**(`pWWhp`)에 반영했다. 안내를 ‘현장 녹음 기반’으로 고쳤고 선택 이름을 ‘핑크 노이즈’로 바꿨다. [소리 화면](../designs/revised/sound.png)과 [22개 상태 PDF](../designs/revised/next-stop-revised.pdf)도 갱신했다. 이전 합성 파일은 검토 자료와 과거 36개 뷰어에 보존하며 현재 게시 패키지에서는 제거했다.

- `python scripts/prepare-recorded-ambience.py`: 4개 원본·출력 SHA, 포맷, 레벨, 루프 경계 검사 통과
- `node scripts/recorded-audio-browser-qa.cjs`: Chrome의 실제 Web Audio로 4개 WAV 디코딩·반복·시작/중지 페이드, 선택 취소·저장·여행 일시정지/재개·캐시 재사용·네트워크 실패 재시도 통과. 3개 화면 크기의 소리 선택 시트 확인, 페이지 오류 0건
- `node scripts/prototype-edge-qa.cjs`: 기존 여행 수치·화면·포커스·비동기 취소·오디오 상태 검사 통과

브라우저 결과: `.impeccable/review/recorded-audio/verification.json`. 회귀 로그: `.impeccable/review/recorded-audio-state-qa.log`. 원본 다운로드 재현은 `scripts/download-ambient-sources.cjs`, 편집 재현은 `scripts/prepare-recorded-ambience.py`다.

## 게시 결과

소스 `296ee0102d1f839bdb10a6426e5a959e4074d119`를 푸시하고 게시 아카이브의 HTML·시연 JS·4개 WAV·출처·측정값이 같은 커밋과 일치하는지 확인했다. 배포 `appgdep_6acc5bb3056481918f1866a5964a1b04`는 `succeeded`다. 기존 주소와 소유자 전용 접근을 유지했다. [소리 선택과 미리듣기](https://next-step-app-flow.sqisoft-3053.chatgpt.site/?scene=sound).
