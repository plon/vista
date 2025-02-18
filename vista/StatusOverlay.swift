import SwiftUI

struct StatusOverlay: View {
    @Binding var status: ProcessingStatus
    @State private var isAnimating = false

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Group {
                    switch status {
                    case .processing:
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .rotationEffect(.degrees(isAnimating ? 360 : 0))
                            .onAppear {
                                withAnimation(
                                    .linear(duration: 1).repeatForever(autoreverses: false)
                                ) {
                                    isAnimating = true
                                }
                            }
                        Text("Processing...")
                    case .success:
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Success")
                    case .error(let message):
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                        Text(message)
                    case .none:
                        EmptyView()
                    }
                }
                .font(.title2)
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(10)
            .position(
                x: geometry.size.width / 2,
                y: geometry.size.height / 2
            )
        }
    }
}

#Preview {
    StatusOverlay(status: .constant(.processing))
}
