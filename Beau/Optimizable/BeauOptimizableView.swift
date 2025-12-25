import SwiftUI

struct BeauItemView<T: BeauOptimizable>: View {
  @ObservedObject var item: T
  let relativeURL: URL
  @Binding var selectedIds: Set<UUID>

  init(_ item: T, _ sourceURL: URL, _ selectedIds: Binding<Set<UUID>>) {
    let urlString = item.sourceURL.path.replacingOccurrences(
      of: sourceURL.path,
      with: ""
    )
    self.relativeURL = URL(fileURLWithPath: urlString).deletingLastPathComponent()
    self.item = item
    self._selectedIds = selectedIds
  }

  private var isSelected: Binding<Bool> {
    Binding<Bool>(
      get: {
        selectedIds.contains(item.id)
      },
      set: { newValue in
        if newValue {
          selectedIds.insert(item.id)
        } else {
          selectedIds.remove(item.id)
        }
      }
    )
  }

  var body: some View {
    VStack(alignment: .leading) {
      HStack(alignment: .center) {
        if item.error != "" {
          Image(systemName: "exclamationmark.triangle.fill")
            .foregroundColor(.red)
            #if DEBUG
              .debugHover()
            #endif
        } else if item.timeEnd != nil {
          Image(systemName: "checkmark.seal.fill")
            .foregroundColor(.green)
            #if DEBUG
              .debugHover()
            #endif
        } else {
          Toggle("Is Selected", isOn: isSelected)
            .labelsHidden()
            .toggleStyle(.checkbox)
            #if DEBUG
              .debugHover()
            #endif

        }
        if let cgImage = item.thumbnail {
          let nsImage = NSImage(cgImage: cgImage, size: .zero)
          let imageUrl = item.completionPercentage == 1 ? item.targetURL : item.sourceURL
          Button {
            NSWorkspace.shared.open(imageUrl)
          } label: {
            Image(nsImage: nsImage)
              .resizable()
              .scaledToFit()
              .opacity(isSelected.wrappedValue ? 1 : 0.5).frame(maxWidth: 100)
          }
          .buttonStyle(.plain)
          .onHover { hovering in
            hovering ? NSCursor.pointingHand.push() : NSCursor.pop()
          }
          #if DEBUG
            .debugHover()
          #endif
        } else {
          Image(systemName: "questionmark.square.dashed")
            .resizable()
            .scaledToFit()
            .opacity(isSelected.wrappedValue ? 1 : 0.5).frame(maxWidth: 100)
            #if DEBUG
              .debugHover()
            #endif
        }
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
      #if DEBUG
        .debugHover()
      #endif
      ProgressView(value: item.completionPercentage)
        .opacity(
          item.completionPercentage == nil
            || item.completionPercentage! >= 1
            ? 0 : 1
        )
    }
    if !item.error.isEmpty {
      Text(item.error)
        .foregroundColor(.red)
    }
  }
}

#Preview("Is selected") {
  @Previewable @State var selectedIds: Set<UUID> = [
    BeauPreviewMocks.getVideoOptimizableIsSelected().id
  ]
  BeauItemView(
    BeauPreviewMocks.getVideoOptimizableIsSelected(),
    BeauPreviewMocks.folderURL,
    $selectedIds
  )
  .debugHover()
  .padding(10)
}

#Preview("Is successful") {
  @Previewable @State var selectedIds: Set<UUID> = [
    BeauPreviewMocks.getImageOptimizableSuccessful().id
  ]
  BeauItemView(
    BeauPreviewMocks.getImageOptimizableSuccessful(),
    BeauPreviewMocks.folderURL,
    $selectedIds
  )
  .padding(10)
}

#Preview("Has errors") {
  @Previewable @State var selectedIds: Set<UUID> = [
    BeauPreviewMocks.getImageOptimizableWithError().id
  ]
  BeauItemView(
    BeauPreviewMocks.getImageOptimizableWithError(),
    BeauPreviewMocks.folderURL,
    $selectedIds
  )
  .padding(10)
}
