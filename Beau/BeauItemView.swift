import SwiftUI

struct BeauItemView<T: BeauMediaOptimizable>: View {
  @ObservedObject var item: T
  let relativeURL: URL

  init(_ item: T, _ sourceURL: URL) {
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
        if item.error != "" {
          Image(systemName: "exclamationmark.triangle.fill")
            .foregroundColor(.red)
        } else if item.timeEnd != nil {
          Image(systemName: "checkmark.seal.fill")
            .foregroundColor(.green)
        } else {
          Toggle("Is Selected", isOn: $item.isSelected)
            .labelsHidden()
            .toggleStyle(.checkbox)
        }
        HStack(alignment: .center, spacing: 2) {
          if let cgImage = item.thumbnail {
            let nsImage = NSImage(cgImage: cgImage, size: .zero)
            Image(nsImage: nsImage)
              .resizable()
              .scaledToFit()
              .opacity(item.isSelected ? 1 : 0.5)
          } else {
            Image(systemName: "questionmark.square.dashed")
              .resizable()
              .scaledToFit()
              .opacity(item.isSelected ? 1 : 0.5)
          }
        }.frame(maxWidth: 100)
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
        .opacity(
          item.completionPercentage == nil
            || item.completionPercentage! >= 1
            ? 0 : 1
        )
      if !item.error.isEmpty {
        Text(item.error)
          .foregroundColor(.red)
      }
    }
  }
}

#Preview {
  let item = BeauVideoOptimizable(
    sourceURL: URL(string: "/home/foobar/Documents/sample.mov")!
  )
  // item.targetResolution = CGSize(width: 1920, height: 1080)
  // item.targetEncoding = "avc"
  // item.sourceResolution = CGSize(width: 3840, height: 2160)
  // item.sourceEncoding = "hevc"
  // item.sourceSize = 123456
  BeauItemView(item, URL(string: "/home/foobar/Documents")!)
    .padding(10)
}

#Preview("Is completed") {
  var item = BeauVideoOptimizable(
    sourceURL: URL(string: "/home/foobar/Documents/sample.mov")!
  )
  item.timeEnd = Date()
  // item.targetResolution = CGSize(width: 1920, height: 1080)
  // item.targetEncoding = "avc"
  // item.sourceResolution = CGSize(width: 3840, height: 2160)
  // item.sourceEncoding = "hevc"
  // item.sourceSize = 123456
  return BeauItemView(item, URL(string: "/home/foobar/Documents")!)
    .padding(10)
}

#Preview("Has errors") {
  var item = BeauVideoOptimizable(
    sourceURL: URL(string: "/home/foobar/Documents/sample.mov")!
  )
  item.error = "Placeholder error"
  // item.targetResolution = CGSize(width: 1920, height: 1080)
  // item.targetEncoding = "avc"
  // item.sourceResolution = CGSize(width: 3840, height: 2160)
  // item.sourceEncoding = "hevc"
  // item.sourceSize = 123456
  return BeauItemView(item, URL(string: "/home/foobar/Documents")!)
    .padding(10)
}
