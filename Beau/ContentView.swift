//
//  ContentView.swift
//  Beau
//
//  Created by Daniel Chen on 10/20/25.
//

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

  var body: some View {
    Button("Select Folder") {
      isReady = false
      isImporterPresented = true
    }.fileImporter(
      isPresented: $isImporterPresented,
      allowedContentTypes: allowedContentTypes,
      allowsMultipleSelection: false
    ) { result in
      switch result {
      case .success(let urls):
        if let sourceURL = urls.first {
          session.sourceURL = sourceURL
          session.targetURL = sourceURL
          let videoFileURLs = getVideoFileURLs(in: sourceURL)
          let targetResolution = CGSize(width: 1920, height: 1080)
          let targetEncoding = ""
          Task {
            session.items = await createBeauItems(videoFileURLs, targetResolution, targetEncoding)
            isReady = true
          }
        }
      case .failure(let error):
        print("\(error.localizedDescription)")
      }
    }
    List(session.items, id: \.sourceURL) { item in
      BeauItemView(item: item)
    }
    Button("Start") {
      session.timeBegin = Date()
      isReady = false
      for i in session.items.indices {
        Task {
          await processBeauItem(session.items[i], session.tempFileNamePattern)
        }
      }

    }
    .disabled(!isReady)
  }
}

#Preview {
}
