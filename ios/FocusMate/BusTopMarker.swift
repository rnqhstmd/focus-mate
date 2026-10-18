import SwiftUI

/// 위에서 내려다본 버스(시안 R07·R13의 초록 버스 그림). 앞(위쪽)이 진행 방향이다.
/// 자산 대신 도형으로 그린다: 몸체(노선색)·검은 테두리·앞유리·뒷유리·옆 창·지붕 판·사이드미러.
struct BusTopMarker: View {
    var color: Color = FMDesign.routeBranch
    /// 몸체 폭. 길이는 폭의 1.9배다.
    var width: CGFloat = 30

    var body: some View {
        let height = width * 1.9
        let u = width / 30
        let glass = Color(hex: 0x0E1A14)
        ZStack(alignment: .top) {
            // 사이드미러
            HStack {
                Capsule().fill(Color.black).frame(width: 3 * u, height: 6 * u)
                Spacer(minLength: 0)
                Capsule().fill(Color.black).frame(width: 3 * u, height: 6 * u)
            }
            .frame(width: width + 4 * u)
            .offset(y: 5 * u)
            RoundedRectangle(cornerRadius: 7 * u)
                .fill(color)
                .overlay {
                    VStack(spacing: 0) {
                        RoundedRectangle(cornerRadius: 3 * u).fill(glass)
                            .frame(height: 9 * u).padding(.horizontal, 3.5 * u).padding(.top, 3.5 * u)
                        HStack(spacing: 0) {
                            RoundedRectangle(cornerRadius: 1 * u).fill(glass.opacity(0.9)).frame(width: 2.5 * u)
                            Spacer(minLength: 0)
                            RoundedRectangle(cornerRadius: 1 * u).fill(glass.opacity(0.9)).frame(width: 2.5 * u)
                        }
                        .padding(.horizontal, 2 * u).padding(.vertical, 3 * u)
                        .overlay {
                            RoundedRectangle(cornerRadius: 2 * u).fill(Color.white.opacity(0.22))
                                .padding(.horizontal, 8 * u).padding(.vertical, 6 * u)
                        }
                        RoundedRectangle(cornerRadius: 2 * u).fill(glass)
                            .frame(height: 5 * u).padding(.horizontal, 5 * u).padding(.bottom, 3 * u)
                    }
                }
                .overlay { RoundedRectangle(cornerRadius: 7 * u).strokeBorder(Color.black.opacity(0.9), lineWidth: 1.5 * u) }
                .frame(width: width, height: height)
        }
        .frame(width: width + 4 * u, height: height)
        .shadow(color: .black.opacity(0.45), radius: 3 * u, y: 1.5 * u)
        .accessibilityHidden(true)
    }
}
