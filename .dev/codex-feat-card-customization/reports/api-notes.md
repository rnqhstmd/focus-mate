# W10 플랫폼 API 근거

문서 전문은 document-specialist가 공식 Apple 문서와 설치 SDK 선언으로 확인. 프로젝트 iOS17.0.

- PhotosPicker/PhotosPickerItem.loadTransferable: iOS16+, 항목은 placeholder. async throws T? nil/throw/iCloud 실패를 처리한다. 현재 선택/generation이 달라지면 늦은 결과를 버린다. 8MiB는 로드한 표현Data.count로 검사하며 사진보관함 원본파일의 크기라고 표현하지 않는다. 순차처리로 원본Data수명을 줄인다.
  https://developer.apple.com/documentation/photokit/bringing-photos-picker-to-your-swiftui-app
- ImageIO: 원본 UIImage 전체decode 없이 thumbnail. CreateThumbnailFromImageAlways, ThumbnailMaxPixelSize, CreateThumbnailWithTransform을 사용하여 크기·orientation을 정규화하고 nil을 처리한다. 변환된 픽셀에 원래orientation을 다시 적용하지 않는다.
  https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/ImageIOGuide/imageio_source/ikpg_source.html
- CGImageDestination: quality는 용량보장이 아니다. 유한 인코딩/축소와Finalize 성공·실제Data.count 검사가 필요하다. alpha는 JPEG에서 사라지므로 보존형식을 별도로 결정한다. 장당1MiB/합계6MiB는 인코딩이미지 바이트이며 base64 JSON 전체크기와 구분한다.
  https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/ImageIOGuide/ikpg_dest/ikpg_dest.html
- ScrollView는 기본적으로bounds clipping. scrollClipDisabled(true)는 영역밖그리기를 허용한다. 기본clip 여부만으로 현재hit/안전영역 문제를 설명하지 않는다.
  https://developer.apple.com/documentation/swiftui/view/scrollclipdisabled(_:)
- safeAreaInset은 버튼높이만큼safearea를 조정하나 모든modifier조합의hit경로까지 보장하지 않는다.
  https://developer.apple.com/documentation/swiftui/view/safeareainset(edge:alignment:spacing:content:)-4s51l
- dynamicTypeSize 값/범위는iOS15+이며 크기상한으로핵심콘텐츠도달성을대체하지 않는다.
  https://developer.apple.com/documentation/swiftui/view/dynamictypesize(_:)-1m2tf
