import SwiftUI

struct BeauSessionView: View {
  @ObservedObject var session: BeauSession

  init(_ session: BeauSession) {
    self.session = session
  }

  var body: some View {
    VStack(alignment: .leading) {
      if let sourceURL = session.sourceURL {
        HStack(alignment: .center) {
          Text("\(self.session.selectedIds.count)/\(self.session.items.count) selected")
            .font(.footnote)
          BeauBreadcrumbPathView(url: sourceURL)
        }
        .padding(8)
        List(session.items, id: \.id) { item in
          // Type erasure to determine the concrete type of BeauMediaOptimizable
          if let videoItem = item as? BeauVideoOptimizable {
            BeauItemView(videoItem, sourceURL, $session.selectedIds)
              .listRowSeparator(.hidden)
          } else if let imageItem = item as? BeauImageOptimizable {
            BeauItemView(imageItem, sourceURL, $session.selectedIds)
              .listRowSeparator(.hidden)
          } else {
            Text("Unsupported item type")
              .listRowSeparator(.hidden)
          }
          Divider()
        }
      } else {
        Text("No source directory selected.")
          .padding(8)
        Spacer()
      }
    }
  }
}

#Preview("Empty Session") {
  BeauSessionView(BeauPreviewMocks.getSessionEmpty())
}

#Preview("With Items") {
  BeauSessionView(BeauPreviewMocks.getSessionWithItems())
}
