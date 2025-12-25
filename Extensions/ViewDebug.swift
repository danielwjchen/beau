//
//  ViewDebug.swift
//  Beau
//
//  Created by Daniel Chen on 12/25/25.
//
import SwiftUI

// Extension to make it easy to use
extension View {
  func debugHover(color: Color = .orange) -> some View {
    self.modifier(InspectorModifier(color))
  }
}

#Preview("Default") {
  Text("Hover over me")
    .padding()
    .debugHover(color: .red)
}

#Preview("Custom Color") {
  Text("Hover over me")
    .padding()
    .debugHover(color: .green)
}
