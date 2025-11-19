import SwiftUI

struct BeauItemView: View {
  @ObservedObject var item: BeauItem
  @State private var thumbnail = Image(systemName: "video")
  let relativeURL: URL

  init(item: BeauItem, _ sourceURL: URL) {
    let urlString = item.sourceURL.path.replacingOccurrences(
      of: sourceURL.path,
      with: ""
    )
    self.relativeURL = URL(fileURLWithPath: urlString).deletingLastPathComponent()
    self.item = item
  }

  var body: some View {
    VStack(alignment: .leading) {
      HStack(alignment: .center) {
        Toggle("Is Selected", isOn: $item.isSelected)
          .labelsHidden()
          .toggleStyle(.checkbox)
        HStack(alignment: .center, spacing: 2) {
          self.thumbnail
            .opacity(item.isSelected ? 1 : 0.5)
        }.frame(maxWidth: 200)
        VStack(alignment: .leading) {
          BeauBreadcrumbPathView(url: relativeURL, hasLeadingChevron: true)
            .padding(.bottom, 4)
          HStack(alignment: .center) {
            BeauNameAndSizeView(
              name: item.sourceURL.lastPathComponent,
              resolution: item.sourceResolution,
              fileSize: item.sourceSize
            )
            Spacer()
            BeauNameAndSizeView(
              name: item.targetURL.lastPathComponent,
              resolution: item.targetResolution,
              fileSize: item.targetSize
            )
          }
        }
      }
      ProgressView(value: item.completionPercentage)
        .opacity(item.completionPercentage == nil ? 0 : 1)
      if !item.error.isEmpty {
        Text(item.error)
          .foregroundColor(.red)
      }
    }
    .task {
      do {
        let cgImage = try await generateThumbnail(for: item.sourceURL)
        #if os(macOS)
          let nsImage = NSImage(cgImage: cgImage, size: .zero)
          self.thumbnail = Image(nsImage: nsImage)
        #else
          let uiImage = UIImage(cgImage: cgImage)
          self.thumbnail = Image(uiImage: uiImage)
        #endif
      } catch {
        item.error = "Thumbnail error: \(error.localizedDescription)"
      }
    }
  }
}

#Preview {
  let item = BeauItem(
    sourceURL: URL(string: "/home/foobar/Documents/sample.mov")!,
    targetURL: URL(string: "/home/foobar/Documents/sample.mp4")!,
    targetResolution: CGSize(width: 1920, height: 1080),
    targetEncoding: "avc",
    sourceResolution: CGSize(width: 3840, height: 2160),
    sourceEncoding: "hevc",
    sourceFileSize: 123456
  )
  BeauItemView(item: item, URL(string: "/home/foobar/Documents")!)
    .padding(10)
}
