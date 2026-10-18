# Noto Sans KR 출처

제작: Google · Adobe (Noto Sans CJK / Source Han Sans 계열).
원본: https://github.com/google/fonts/raw/main/ofl/notosanskr/NotoSansKR%5Bwght%5D.ttf (가변 글꼴)
라이선스: SIL Open Font License 1.1 — 전문은 같은 폴더의 `NotoSansKR-OFL.txt`.
다운로드일: 2026-10-17.

## 가공 내용
fonttools로 가변 글꼴에서 굵기 400/600/700 정적 인스턴스를 만들고 아래 문자만 남겨 서브셋했다.
힌팅은 제거했다. 글리프 모양은 바꾸지 않았다.

- ASCII `U+0020–007E`, Latin-1 `U+00A0–00FF`(· × ° 등)
- 일반 문장부호 `U+2010–206F`(— – … ‹ › 등), 화살표 `U+2190–21FF`, 도형 `U+25A0–25FF`, ≤ ≥ ⌖ ™
- CJK 기호 `U+3000–303F`, 한글 자모 `U+3131–318E`, 현대 한글 11,172자 `U+AC00–D7A3`, 전각 `U+FF01–FF5E`

| 파일 | PostScript 이름 | 굵기 |
|---|---|---|
| NotoSansKR-Regular.ttf | NotoSansKR-Regular | 400 |
| NotoSansKR-SemiBold.ttf | NotoSansKR-SemiBold | 600 |
| NotoSansKR-Bold.ttf | NotoSansKR-Bold | 700 |

"Noto"는 OFL Reserved Font Name이 아니므로 서브셋 후에도 이름을 유지했다(원본 저작권 문구의 RFN 'Source'는 이 이름과 무관).
글꼴은 Info.plist `UIAppFonts`로 등록한다.
