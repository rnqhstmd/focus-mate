# FocusFlight 방식의 지도 애니메이션을 버스 집중앱에 적용할 수 있는가

조사일: 2026-10-11

## 결론

Apple MapKit의 지도 카메라를 버스 노선에 따라 움직여 동영상처럼 보이는 여행 화면을 만드는 것은 기술적으로 가능하다. 로드뷰 사진을 순서대로 교체하는 방식과 달리 지도 시점 자체를 애니메이션하므로 사진 사이 점프를 피할 수 있다. 단, 실제 iPhone에서 서울 노선의 입체 데이터·카메라 제한·로딩을 확인해야 완성 품질을 판단할 수 있다. 이 조사는 기능 및 공개 화면 확인이며 앱 프로토타입 완성이나 서울 노선 재생 검증이 아니다.

## FocusFlight에서 확인한 사실

공식 App Store 설명에 3D Map Window View, 집중 시간에 따른 세계 지도 이동, 3D 비행 경로가 명시돼 있다. 공식 스크린샷 iPhone-EN-4에는 3D·위성·일반 지도 선택 안내와 지도 하단 Apple Maps 로고 및 Legal 표시가 있다. 이 이미지는 브라우저로 직접 관찰했다. 따라서 해당 화면이 Apple 지도 기반이라는 시각적 근거는 확보했다.

하지만 내부에서 MKMapView, SwiftUI Map, 어떤 카메라 애니메이션 코드를 사용했는지 공개 자료로 확정하지 못했다. 저장한 영상을 재생하는지까지 내부 코드 수준으로 단정할 수는 없다. 공개 기능은 실시간 지도 카메라 이동으로 재현 가능한 종류다. 비슷한 이름의 GitHub 프로젝트를 원본 앱 소스로 간주하지 않았다.

## 우리 앱의 구현 제안

서울 공공데이터에서 얻은 노선 경로와 정류장 순서를 앱에 저장하고, 집중 시간 진행률을 경로상의 이동 위치로 변환한다. MapKit 지도 카메라의 위치·거리·pitch·heading을 그 위치와 진행 방향에 맞춰 변경한다. SwiftUI의 mapCameraKeyframeAnimator 또는 MKMapView의 setCamera(animated:)가 공식 애니메이션 수단이다.

지도 모드에서는 버스를 조금 높은 시점에서 따라간다. 창문 모드에서는 같은 경로를 바라보는 방향을 왼쪽/오른쪽으로 돌리고 창틀 UI를 결합한다. 정확한 좌우 시점을 구성하려면 단순 heading 변경만이 아니라 카메라 위치와 바라보는 중심점을 함께 설정해야 한다. 공급자의 필수 로고·저작권 표시는 유지한다.

처음에는 실제 버스 눈높이를 고집하기보다 지도 품질이 잘 보이는 높이에서 이동감을 확인하고, 이후 낮은 측면 시점을 시험한다. 이는 테스트 제안이며 실제 품질이 확인된 수치는 없다.

## 제한

- 카메라 애니메이션 기능이 있어도 서울이 사진 같은 3D 도시로 렌더링된다는 뜻은 아니다. 일반 지도 건물 돌출, 지형 입체 표현, 사진 기반 Flyover, Detailed City Experience는 다른 기능이다.
- Apple 공식 Flyover 및 Detailed City Experience 목록에 서울/한국은 없다. 이는 일반 3D 지도 건물 전체가 없다는 증거는 아니다. 실제 선택한 노선의 표현은 SDK로 확인해야 한다.
- MapKit은 지도 가독성을 위해 카메라 pitch를 고도에 따라 제한할 수 있다. 도로 높이에서 수평으로 창밖을 바라보는 카메라를 보장할 수 없다. 촬영된 거리 사진처럼 간판·유리창·가로수·차량이 정밀하게 보인다고 약속하면 안 된다.
- 화면 움직임은 애니메이션해도 지도 타일·입체 데이터의 로딩, 급회전, 다리·터널, 기기 성능과 발열은 별도 검증 대상이다.
- 자체 서버 없이 네이티브 MapKit으로 구현하는 구조는 가능하다. 타이머·기록·노선은 로컬 저장할 수 있지만 지도 자료는 네트워크와 공급자 캐시에 의존한다. 완전 오프라인 또는 지도 영상 사전 제작·영구 번들링을 자동으로 허용한다고 해석하면 안 된다.

## 검증 범위와 다음 단계

확인 완료: FocusFlight 공식 설명 및 Apple Maps 로고가 보이는 공식 스크린샷, Apple 카메라·애니메이션·지도 elevation API, 공식 지역별 지원 목록.

서울 Apple 지도 앱의 3D 모드도 열어 확인을 시도했지만 이 환경에서는 지도 캔버스가 회색으로 남아 건물 품질을 시각적으로 확인하지 못했다. 3D 버튼이 존재하거나 접근성에 장소 목록이 나온 것만으로 풍경 렌더링 성공을 주장하지 않는다. 이 실패를 서울에 3D 데이터가 없다는 근거로 해석하지 않는다.

다음 단계는 iPhone용 MapKit 프로토타입 하나다. 서울 실제 버스 노선 1~2km를 60초로 압축하여 재생하고, 일반/위성 입체 스타일과 높은 추적/낮은 측면 시점을 비교한다. 전환 점프, 회전, 좌우 풍경, 건물 표현, 교량, 로딩, 발열을 확인하면 이 방식의 적합성을 판단할 수 있다.

## 공식 출처

- [FocusFlight App Store](https://apps.apple.com/us/app/focusflight-deepfocus-timer/id6648771147)
- [공식 지도 선택 스크린샷](https://is1-ssl.mzstatic.com/image/thumb/PurpleSource221/v4/c3/e2/b0/c3e2b020-e355-5390-886f-16de4a8b7576/iPhone-EN-4.jpg/660x1434bb.jpg)
- [MKMapCamera](https://developer.apple.com/documentation/mapkit/mkmapcamera)
- [MapKit 카메라 애니메이션](https://developer.apple.com/documentation/swiftui/view/mapcamerakeyframeanimator(trigger:keyframes:))
- [MKMapView setCamera](https://developer.apple.com/documentation/mapkit/mkmapview/setcamera(_:animated:))
- [3D elevation 설정](https://developer.apple.com/documentation/mapkit/mapstyle/elevation)
- [pitch의 고도별 제한](https://developer.apple.com/documentation/mapkit/mkmapcamera/pitch)
- [Apple 지역별 지원 목록](https://www.apple.com/ios/feature-availability/)
- [MapKit 오프라인 관련 Apple 공식 답변](https://developer.apple.com/forums/thread/772258)
