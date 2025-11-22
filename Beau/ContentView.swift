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
  let allowedContentTypes = [UTType.directory]
#else
  let allowedContentTypes = [UTType.folder]
#endif

struct ContentView: View {

  @StateObject private var session: BeauSession = BeauSession(
    resolution: "4k",
    encoding: "HEVC",
  )

  @State private var isImporterPresented: Bool = false
  @State private var isReady: Bool = false
  @State private var selectedVideoPreset: VideoPreset = .defaultValue
  @State private var isAccessing: Bool = false
  @State public var itemProgressPercentage: Float? = nil
  @State public var itemProgressMessage: String = ""

  private func cleanUpAccess() {
    if isAccessing {
      if let sourceURL = session.sourceURL {
        sourceURL.stopAccessingSecurityScopedResource()
      }
    }
  }

  var body: some View {
    VStack(alignment: .leading) {
      Picker("Target", selection: $selectedVideoPreset) {
        ForEach(VideoPreset.all) { preset in
          Text(preset.label).tag(preset)
        }
      }
      .padding(.vertical, 8.0)
      .padding(.horizontal, 8.0)
      .onChange(of: selectedVideoPreset) {
        session.resolution = "\(selectedVideoPreset.width)x\(selectedVideoPreset.height)"
        session.encoding = selectedVideoPreset.encoding
        setBeauItemsIsSelectedByVideoPreset(session.items, selectedVideoPreset)
      }

      if let sourceURL = session.sourceURL {
        BeauBreadcrumbPathView(url: sourceURL)
          .padding(8)
        List(session.items, id: \.sourceURL) { item in
          BeauItemView(item: item, sourceURL)
        }
      } else {
        Spacer()
      }
      if session.sourceURL != nil && session.items.count == 0 {
        Text(itemProgressMessage)
          .font(.caption)
          .padding(.leading, 8)
        ProgressView(value: itemProgressPercentage)
      }
    }
    .toolbar {
      ToolbarItemGroup(placement: .primaryAction) {
        Button("Select Folder", systemImage: "folder") {
          isReady = false
          isImporterPresented = true
        }
        .labelStyle(.titleAndIcon)
        .fileImporter(
          isPresented: $isImporterPresented,
          allowedContentTypes: allowedContentTypes,
          allowsMultipleSelection: false
        ) { result in
          itemProgressPercentage = nil
          itemProgressMessage = ""
          session.items = []
          cleanUpAccess()
          switch result {
          case .success(let urls):
            if let sourceURL = urls.first {
              self.isAccessing = sourceURL.startAccessingSecurityScopedResource()
              session.sourceURL = sourceURL
              session.targetURL = sourceURL
              let videoFileURLs = getVideoFileURLs(in: sourceURL)
              let targetResolution = CGSize(width: 1920, height: 1080)
              let targetEncoding = ""
              Task {
                session.items = await createBeauItems(
                  videoFileURLs, targetResolution, targetEncoding
                ) { progressPercentage, message in
                  self.itemProgressPercentage = progressPercentage
                  self.itemProgressMessage = message
                }
                setBeauItemsIsSelectedByVideoPreset(session.items, selectedVideoPreset)
                isReady = session.items.count > 0
              }
            }
          case .failure(let error):
            print("\(error.localizedDescription)")
          }
        }
        .disabled(session.timeBegin != nil && session.timeEnd == nil)
        Button("Start", systemImage: "play") {
          session.timeBegin = Date()
          isReady = false
          Task {
            for i in session.items.indices {
              await processBeauItem(session.items[i], session.tempFileNamePattern)
            }
            session.timeEnd = Date()
            cleanUpAccess()
          }
        }
        .labelStyle(.titleAndIcon)
        .disabled(!isReady)
      }
    }
  }
}

#Preview {
  ContentView()
}
