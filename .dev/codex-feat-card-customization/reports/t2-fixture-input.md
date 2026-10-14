# 추가 입력 fixture
번들 Python3 Pillow의 WebP lossless encoder로 직접 생성한 RGB40×20 (220,40,80) 38bytes. 외부사진/라이선스 없음. .dev/.../test-webp-base64.txt에 바이트기록. test-author가 WebP 실제이미지 성공케이스에 넣을수있다.
8MiB정확입력은 PNG ancillary chunk 방식으로유효한PNG생성가능: IEND앞 비필수 tEXtchunk를넣고 CRC32정상작성. ImageIO 실제source/index complete와decode되는것을testhelper에서확인한후 사용한다. arbitrarytrailingpadding은지원불확실이므로간단히PASS로간주않는다.

## 부모 actual fixture 판독
macOS Swift ImageIO 실제 실행 exit0, 두파일모두40x20/source complete0/index complete0/CGContext draw성공. WebP38bytes, PNG8_388_608bytes. 이는 macOS의입력fixture증거이며 대상iOS처리성공은아직검증안됨. PNG구성은signature+IHDR(40,20,8bitRGB)+정상zlib IDAT+IEND앞tEXt("padding\0"+x반복), length/CRC32정상. 세부생성은t2-fixture-validation.log및작업기록. 테스트author동일recipe로자체fixture추가후iOS에검증.
