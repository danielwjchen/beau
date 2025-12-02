import SwiftUI

struct BeauItemView<T: BeauOptimizable>: View {
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
        HStack(alignment: .top, spacing: 2) {
          VStack {
            if let cgImage = item.thumbnail {
              let nsImage = NSImage(cgImage: cgImage, size: .zero)
              Image(nsImage: nsImage)
                .resizable()
                .scaledToFit()
                .opacity(item.isSelected ? 1 : 0.5).frame(maxWidth: 100)
            } else {
              Image(systemName: "questionmark.square.dashed")
                .resizable()
                .scaledToFit()
                .opacity(item.isSelected ? 1 : 0.5).frame(maxWidth: 100)
            }
          }
          .frame(width: 100, height: 100)
          VStack(alignment: .leading) {
            BeauBreadcrumbPathView(url: relativeURL, hasLeadingChevron: true)
              .padding(10)
            Spacer()
            HStack(alignment: .bottom) {
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
          }.frame(maxHeight: 100)
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

#Preview("Is selected") {
  BeauItemView(
    BeauPreviewMocks.getVideoOptimizableIsSelected(),
    BeauPreviewMocks.folderURL
  )
  .padding(10)
}

#Preview("Is successful") {
  BeauItemView(
    BeauPreviewMocks.getImageOptimizableSuccessful(),
    BeauPreviewMocks.folderURL
  )
  .padding(10)
}

#Preview("Has errors") {
  BeauItemView(
    BeauPreviewMocks.getImageOptimizableWithError(),
    BeauPreviewMocks.folderURL
  )
  .padding(10)
}
