import SwiftUI

struct BeauItemView: View {
  @ObservedObject var item: BeauItem

  var body: some View {
    VStack(alignment: .leading) {
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
      ProgressView(value: item.completionPercentage)
        .opacity(item.completionPercentage == nil ? 0 : 1)
      if !item.error.isEmpty {
        Text(item.error)
          .foregroundColor(.red)
      }
    }
  }
}

#Preview {
  let item = BeauItem(
    sourceURL: URL(string: "files://location/sample.mov")!,
    targetURL: URL(string: "files://location/sample.mp4")!,
    targetResolution: CGSize(width: 1920, height: 1080),
    targetEncoding: "avc",
    sourceResolution: CGSize(width: 3840, height: 2160),
    sourceEncoding: "hevc",
    sourceFileSize: 123456
  )
  BeauItemView(item: item)
}
