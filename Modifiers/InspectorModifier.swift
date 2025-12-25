//
//  InspectorModifier.swift
//  Beau
//
//  Created by Daniel Chen on 12/25/25.
//
import SwiftUI

struct InspectorModifier: ViewModifier {
  @State private var isHovering = false
  @State private var isPinned = false
  @State private var size: CGSize = .zero

  var color: Color = .orange

  init(_ color: Color = .orange) {
    self.color = color
  }

  func body(content: Content) -> some View {
    content
      .background(
        GeometryReader { geo in
          Color.clear
            .onAppear { size = geo.size }
            .onChange(of: geo.size) { _, newValue in size = newValue }
        }
      )
      .onHover { hovering in
        withAnimation(.easeInOut(duration: 0.2)) {
          isHovering = hovering
        }
      }
      // Use simultaneousGesture to avoid hijacking button clicks
      .simultaneousGesture(
        TapGesture().onEnded {
          isPinned.toggle()
        }
      )
      .overlay(
        ZStack {
          if isHovering || isPinned {
            Rectangle()
              .stroke(color, lineWidth: 1)
          }
        }
      )
      .overlay(
        ZStack {
          if isHovering || isPinned {
            VStack {
              Spacer()
              HStack(spacing: 4) {
                Image(
                  systemName: isPinned ? "pin.fill" : "pin"
                )
                Text("\(Int(size.width)) × \(Int(size.height))")
              }
              .fixedSize()
              .font(.system(size: 10, design: .monospaced))
              .padding(2)
              .background(color)
              .foregroundColor(.white)
              .cornerRadius(4)
              .buttonStyle(.plain)
              .offset(y: size.height < 20 ? 20 : 0)
              .offset(x: size.width < 100 ? 40 : 0)
            }
          }
        }
        .allowsHitTesting(false)  // Don't let the overlay block clicks
      )
  }
}

#Preview {
  Text("Hover over me")
    .padding()
    .modifier(InspectorModifier())
}
