import SwiftUI

struct RunButton: View {

  @ObservedObject var session: Session
  @State private var isHovered = false

  var body: some View {
    Button {
      session.run()
    } label: {
      HStack(spacing: 7) {
        if session.isRunning {
          ProgressView()
            .progressViewStyle(.circular)
            .scaleEffect(0.6)
            .frame(width: 14, height: 14)
          Text("Processing…")
            .foregroundColor(session.textColor)
        } else if session.isDone {
          Image(systemName: "checkmark")
            .font(.system(size: 12, weight: .bold))
          Text("Done!")
            .foregroundColor(session.textColor)
        } else {
          Image(systemName: "bolt.fill")
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(session.textColor)
          Text("Optimize")
            .foregroundColor(session.textColor)
        }
      }
      .font(.system(size: 13, weight: .semibold))
      .padding(.horizontal, 20)
      .padding(.vertical, 7)
      .background(
        Group {
          if session.canRun {
            LinearGradient(
              colors: [.brandLight, .brandDark],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          } else {
            Color.white.opacity(0.07)
          }
        }
      )
      .clipShape(RoundedRectangle(cornerRadius: 8))
      .shadow(color: session.canRun ? Color.brandDark.opacity(0.45) : .clear, radius: 8, y: 3)
      .scaleEffect(isHovered && session.canRun ? 1.02 : 1.0)
      .animation(.spring(response: 0.2), value: isHovered)
    }
    .buttonStyle(.plain)
    .disabled(!session.canRun)
    .onHover { isHovered = $0 }
  }
}

#Preview("Empty Session") {
  RunButton(session: BeauPreviewMocks.getSessionEmpty())
}

#Preview("With Items") {
  RunButton(session: BeauPreviewMocks.getSessionWithItems())
}

#Preview("With Selected Items") {
  RunButton(session: BeauPreviewMocks.getSessionWithSelectedItems())
}

#Preview("Processing State") {
  RunButton(session: BeauPreviewMocks.getSessionWithSelectedItemsProcessing())
}
