# 여행 소리 · CC0 녹음과 노이즈 샘플

2026-10-12. 기존 Python DSP 합성 시안을 외부 원본 WAV 기반 샘플로 교체했다. 음원 제공자는 **Joseph SARDIN / BigSoundBank**다. 각 원본 페이지와 [제공자의 이용 조건](https://bigsoundbank.com/licenses.html)에서 CC0를 확인했고, [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/)에 따라 앱에 포함·편집·재배포·상업 이용할 수 있다. 표시 의무는 없으나 출처를 보존한다.

| 앱 소리 | 현재 파일 | 원본 | 원래 형식 |
|---|---|---|---|
| 빗소리 | rain-windshield-cc0-v1.wav | [Rain on car windshield · 1295](https://bigsoundbank.com/rain-on-car-windshield-s1295.html) | 48 kHz, mono, 24-bit · 차량 안에서 유리에 떨어지는 비 |
| 숲 소리 | forest-edge-cc0-v1.wav | [Forest: On the Edge · 0905](https://bigsoundbank.com/forest-on-the-edge-s0905.html) | 48 kHz, stereo, 16-bit · 숲 가장자리의 새·바람 |
| 버스 주행 | bus-london-cc0-v1.wav | [London bus · 0644](https://bigsoundbank.com/london-bus-s0644.html) | 48 kHz, stereo, 16-bit · 런던 2층 버스 차내 |
| 핑크 노이즈 | pink-noise-cc0-v1.wav | [Pink Noise · 0432](https://bigsoundbank.com/pink-noise-s0432.html) | 44.1 kHz, stereo, 16-bit · 스튜디오 노이즈 샘플 |

빗소리·숲·버스는 실제 녹음이며, 핑크 노이즈는 의도적인 잡음 샘플이다. 서울 노선 현장 녹음으로 표현하지 않는다. 기존 ‘화이트 노이즈’ 선택은 ‘핑크 노이즈’로 바꿨다.

## 앱용 편집

원본 WAV를 정상 다운로드 버튼과 5초 대기 흐름으로 받았다. `sources.json`에는 원본 URL·파일명·SHA-256·작성자·라이선스를 보존했다. 원본은 `.impeccable/review/audio-sources/`, 이전 합성 파일은 `.impeccable/review/audio-before/`에 있다.

평온한 구간을 1초 음량 변동과 피크로 선택했고, 2초 equal-power 교차 연결로 반복 가능한 파일을 만들었다. 자연 소리는 40초, 핑크 노이즈는 30초다. 샘플레이트와 채널 수를 유지하고 앱 파일은 16-bit PCM WAV로 저장한다. 강한 저역통과 필터나 노이즈 제거로 고음을 뭉개지 않는다. DC 오프셋을 제거하고 이전 시안과 같은 RMS -26 dBFS로 맞춰, 단순히 더 큰 소리로 비교하지 않게 했다. 기기에서 출력하는 음압은 이 수치와 다르다.

현재 앱 파일의 클리핑 표본은 0이다. 실제 재생 함수를 Web Audio로 두 바퀴 렌더링했고, 반복 경계의 변화량이 일반 인접 표본 변화의 99백분위 범위 안에 있는지 확인했다. 시작 120 ms·중지 60 ms의 음량 페이드도 검사했다. 자세한 값은 `audio-stats.json`과 `.impeccable/review/recorded-audio/verification.json`에 있다. 이것은 디코딩·렌더링·수치 검사이며 스피커·이어폰으로 직접 청취한 검증은 아니다.

재현: `node scripts/download-ambient-sources.cjs` → `python scripts/prepare-recorded-ambience.py`. Chrome·Playwright, FFmpeg, NumPy를 사용한다. 이전 `generate-travel-audio.py`는 과거 합성 시안 생성기이며 현재 앱에서 사용하지 않는다.
