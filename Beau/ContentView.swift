//
//  ContentView.swift
//  Beau
//
//  Created by Daniel Chen on 10/20/25.
//

import AVFoundation
import SwiftUI
import UniformTypeIdentifiers

#if os(macOS)
  let allowedContentTypes: [UTType] = [
    .directory,
    .image,
    .movie,
    .pdf,
  ]
#else
  let allowedContentTypes: [UTType] = [
    .folder,
    .image,
    .movie,
    .pdf,
  ]
#endif

struct ContentView: View {

  @StateObject private var session = BeauSession(
    from: BeauTargetPreset.defaultValue
  )

  @State private var isImporterPresented: Bool = false

  var body: some View {
    VStack(alignment: .leading) {

      BeauSessionView(session)
      if !session.accessedURLs.isEmpty && session.groups.count == 0 {
        BeauLoadingView(session.itemProgressMessage)
          .font(.caption)
          .padding(.top, 4)
          .padding(.leading, 8)
          .padding(.trailing, 8)
          .padding(.bottom, 2)
        ProgressView(value: session.itemProgressPercentage)
          .padding(.top, 2)
          .padding(.leading, 8)
          .padding(.trailing, 8)
          .padding(.bottom, 8)
      }
    }
    .toolbar {
      ToolbarItemGroup(placement: .primaryAction) {
        Picker("Target", selection: $session.selectedTargetPreset) {
          ForEach(BeauTargetPreset.all) { preset in
            Text(preset.label).tag(preset)
          }
        }
        .padding(.vertical, 8.0)
        .padding(.horizontal, 8.0)
        .onChange(of: session.selectedTargetPreset) {
          session.setPropertiesFromPreset(session.selectedTargetPreset)
          session.setSelectedIds(session.selectedTargetPreset)
          session.groups.forEach { group in
            group.items.forEach { item in
              item.updateTargetResolution(
                CGSize(
                  width: session.selectedTargetPreset.width,
                  height: session.selectedTargetPreset.height
                )
              )
            }
          }
        }
        Button("Reset", systemImage: "arrow.2.circlepath") {
          session.reset()
        }
        .disabled(session.isRunning || session.accessedURLs.isEmpty)
        RunButton(session: session)
      }
    }
  }
}

#Preview {
  ContentView()
}
