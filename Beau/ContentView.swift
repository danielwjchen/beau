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

  @State private var isImporterPresented = false

  private func findVideos(at folderURL: URL) async -> [URL] {
    let videoFileURLs = getVideoFileURLs(in: folderURL)
    let result = await find4KVideoFiles(in: videoFileURLs)
    return result
  }

  var body: some View {
    Button("Select Folder") {
      isImporterPresented = true
    }.fileImporter(
      isPresented: $isImporterPresented,
      allowedContentTypes: allowedContentTypes,
      allowsMultipleSelection: false
    ) { result in
      switch result {
      case .success(let urls):
        if let sourceURL = urls.first {
          self.session.sourceURL = sourceURL
          self.session.targetURL = sourceURL
          Task {
            for videoURL in await self.findVideos(at: sourceURL) {
              self.session.items.append(
                BeauItem(
                  sourceURL: videoURL,
                  targetURL: videoURL,
                  resolution: session.resolution,
                  encoding: session.encoding
                ))
            }
          }
        }
      case .failure(let error):
        print("\(error.localizedDescription)")
      }
    }
    List(session.items, id: \.sourceURL) { item in
      Text(item.sourceURL.absoluteString)
    }
  }
}

#Preview {
}
