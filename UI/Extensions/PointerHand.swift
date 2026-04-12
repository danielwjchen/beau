import AppKit
import SwiftUI

extension View {
  func pointingHandCursor() -> some View {
    #if os(macOS)
      self.onHover { hovering in
        if hovering {
          NSCursor.pointingHand.push()
        } else {
          NSCursor.pop()
        }
      }
    #else
      self
    #endif
  }
}
