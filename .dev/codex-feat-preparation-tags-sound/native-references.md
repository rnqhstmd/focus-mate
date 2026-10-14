# W03 공식 API 근거

- Apple AVAudioPlayer prepareToPlay(): Bool 반환; false 실패, 오디오세션 활성화. 선택 시 호출하지 않고 사용자 미리듣기 요청에서만 사용. https://developer.apple.com/documentation/avfaudio/avaudioplayer/preparetoplay()
- Apple AVAudioPlayer setVolume(_:fadeDuration:): Float 볼륨/초단위 TimeInterval로 페이드. https://developer.apple.com/documentation/avfaudio/avaudioplayer/setvolume(_:fadeduration:)
- numberOfLoops 음수는 stop까지 계속 반복. 기존WAV을반복재생. https://developer.apple.com/documentation/avfaudio/avaudioplayer/numberofloops
- play(): Bool; false를재생실패로취급. https://developer.apple.com/documentation/avfaudio/avaudioplayer/play()
- 2026-10-14 공식문서검색과Apple마크다운직접읽기로확인. .md페이지는webtool의content-type한계로urllib조회.

## 시안 서울알림체(후속UI표현)
Apple Fonts overview https://developer.apple.com/documentation/technologyoverviews/fonts : 번들폰트를등록해사용. CoreText process-scope CTFontManagerRegisterFontsForURL https://developer.apple.com/documentation/coretext/ctfontmanagerregisterfontsforurl(_:_:_:) . 사용자설치폰트권한/새외부폰트없음; 승인TTF기존자산만사용예정.
