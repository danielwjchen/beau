import SwiftUI

enum TriState {
  case off
  case on
  case indeterminate
}

struct TriStateToggle: View {
  // State driven by an external Binding
  @Binding var currentState: TriState

  init(_ currentState: Binding<TriState>) {
    self._currentState = currentState
  }

  var body: some View {
    Button {
      // Logic to cycle the state when tapped
      switch currentState {
      case .off:
        currentState = .on
      case .on:
        currentState = .indeterminate
      case .indeterminate:
        currentState = .off
      }
    } label: {
      // Render a different image based on the current state
      Image(systemName: systemName(for: currentState))
        .resizable()
        .frame(width: 25, height: 25)
        .foregroundColor(color(for: currentState))
    }
    .buttonStyle(.plain)  // Use .plain style to keep only the image
  }

  // Helper function to map the state to an SF Symbol icon
  private func systemName(for state: TriState) -> String {
    switch state {
    case .on:
      return "checkmark.square.fill"
    case .off:
      return "square"
    case .indeterminate:
      return "minus.square.fill"
    }
  }

  // Helper function for coloring the icon
  private func color(for state: TriState) -> Color {
    switch state {
    case .on, .indeterminate:
      return .accentColor
    case .off:
      return .gray
    }
  }
}

#Preview {
  @Previewable @State var value = TriState.off
  TriStateToggle($value)
    .frame(width: 100, height: 100)
}
