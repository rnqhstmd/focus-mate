# 여행 소리 · 출처와 제작

2026-10-13 기준 앱 소리는 4종이고 기본값은 **버스**다. 모두 48 kHz, 스테레오, 16-bit PCM, 40초 반복 WAV이며 RMS -26 dBFS로 맞췄다.

| 앱 소리 | 파일 | 만든 방법 | 아이콘 |
|---|---|---|---|
| 버스 (기본) | travel-bus-v2.wav | 합성 객실 엔진음 (`scripts/generate-bus-cabin-hum.py`) | 버스 |
| 비 오는 버스 | travel-bus-rain-v2.wav | 위 버스음 0.55 + CC0 차창 빗소리 녹음 0.85 혼합 | 비구름 |
| 지하철 | travel-subway-v2.wav | 합성: 바닥 저음 럼블, 레일 소음, 1.25초마다 둥근 저음 박동 2번(바퀴 이음매) | 지하철 |
| 숲속 | travel-forest-v2.wav | CC0 숲 가장자리 녹음 | 나무 |

`소리 없음`도 선택할 수 있다. 사람 목소리가 든 녹음은 쓰지 않는다.

## 녹음 출처

녹음 원본 제공자는 **Joseph SARDIN / BigSoundBank**다. 각 원본 페이지와 [제공자의 이용 조건](https://bigsoundbank.com/licenses.html)에서 CC0를 확인했고, [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/)에 따라 앱에 포함·편집·재배포·상업 이용할 수 있다. 표시 의무는 없으나 출처를 보존한다(`sources.json`: URL·파일명·SHA-256·작성자·라이선스).

| 사용처 | 원본 | 원래 형식 |
|---|---|---|
| 비 오는 버스 | [Rain on car windshield · 1295](https://bigsoundbank.com/rain-on-car-windshield-s1295.html) | 48 kHz, mono, 24-bit · 차량 안에서 유리에 떨어지는 비 |
| 숲속 | [Forest: On the Edge · 0905](https://bigsoundbank.com/forest-on-the-edge-s0905.html) | 48 kHz, stereo, 16-bit · 숲 가장자리의 새·바람 |

`sources.json`에는 앱에서 뺀 London bus(0644)·Pink Noise(0432)의 기록도 남아 있다. 녹음 장소는 가상 서울 노선과 다르다.

## 듣기 편하게 만드는 정리 — 2026-10-13

튀는 소리·날카로운 고음·초음파 대역이 없도록 네 소리 모두 `scripts/build-travel-ambience.py`의 같은 정리를 거친다.

- 대역 제한: 30 Hz 아래 제거, 4.5 kHz부터 12 kHz까지 완만히 줄이고 12 kHz 위는 0.
- 돌발음 완화: 30 ms 순간 음량이 400 ms 평균의 2배(6 dB)를 넘지 않게 누른다.
- 지하철 박동은 클릭이 아니라 40 ms에 걸쳐 올라오는 58 Hz 저음이다.
- 필터는 반복 전체에 원형으로 적용해 반복 이음매가 이어진다.

| 파일 | 피크 dBFS | 8 kHz 위 에너지 | 최대 순간/평균 | 이음매 단차 / 인접 표본 p99 |
|---|---|---|---|---|
| travel-bus-v2.wav | -13.9 | 0.0007% | 1.90 | 0.0017 / 0.0033 |
| travel-bus-rain-v2.wav | -9.7 | 0.003% | 1.76 | 0.0210 / 0.0216 |
| travel-subway-v2.wav | -11.2 | 0.000001% | 1.94 | 0.0012 / 0.0036 |
| travel-forest-v2.wav | -10.2 | 0.008% | 1.55 | 0.0061 / 0.0269 |

자세한 값은 `audio-stats.json`에 있다. 브라우저 검사(`scripts/recorded-audio-browser-qa.cjs`)로 실제 Web Audio 디코딩, 두 바퀴 렌더링의 이음매, 시작 120 ms·중지 60 ms 페이드를 확인했다. 수치·디코딩 검사이며 스피커·이어폰 청취 검증은 아니다.

## 재현

1. 녹음 원본: `node scripts/download-ambient-sources.cjs` → `python scripts/prepare-recorded-ambience.py` (40초 반복 구간을 `designs/audio-sources/`에 저장)
2. 버스 합성음: `python scripts/generate-bus-cabin-hum.py` (`designs/audio-sources/bus-cabin-hum-v1.wav`)
3. 앱 소리: `python scripts/build-travel-ambience.py` → 이 폴더의 `travel-*-v2.wav`와 `audio-stats.json`

`designs/audio-sources/`의 입력 파일은 앱 패키지에 포함하지 않는다.

## 이력

- 2026-10-12: Python DSP 합성 시안을 CC0 녹음(빗소리·숲·London bus)과 핑크 노이즈로 교체.
- 2026-10-13: London bus 녹음에 승객 목소리와 돌발음이 섞여(300–3400 Hz 음절 리듬 지표 0.417, 돌발 구간 7%) 합성 객실 엔진음으로 교체(지표 0.249, 돌발 0%).
- 2026-10-13: 소리를 버스·비 오는 버스·지하철·숲속으로 바꾸고 기본값을 버스로 정함. 핑크 노이즈 제거, 위 정리 과정 추가.
