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

  private func findVideos(at folderURL: URL) async -> [URL] {
    let videoFileURLs = getVideoFileURLs(in: folderURL)
    let result = await find4KVideoFiles(in: videoFileURLs)
    return result
  }

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
          Task {
            for videoURL in await findVideos(at: sourceURL) {
              session.items.append(
                BeauItem(
                  sourceURL: videoURL,
                  targetURL: videoURL,
                  resolution: session.resolution,
                  encoding: session.encoding
                ))
            }
            isReady = true
          }
        }
      case .failure(let error):
        print("\(error.localizedDescription)")
      }
    }
    List(session.items, id: \.sourceURL) { item in
      Text(item.sourceURL.absoluteString)
      ProgressView(value: item.completionPercentage)
    }
    Button("Start") {
      session.timeBegin = Date()
      for i in session.items.indices {
        do {
          let tempFileUrl = try getTempFileURL(
            from: session.items[i].sourceURL, pattern: session.tempFileNamePattern
          )
          session.items[i].timeBegin = Date()
          Task {
            try await encodeVideoWithProgress(
              from: session.items[i].sourceURL, to: tempFileUrl
            ) { progress in
              session.items[i].completionPercentage = progress
            }
            session.items[i].timeEnd = Date()
          }
        } catch {
          session.items[i].error = error.localizedDescription
        }
      }

    }
    .disabled(!isReady)
  }
}

#Preview {
}
