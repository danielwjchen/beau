import SwiftUI

struct BeauSessionView: View {
  @ObservedObject var session: BeauSession

  init(_ session: BeauSession) {
    self.session = session
  }

  var body: some View {
    VStack(alignment: .leading) {
      if !session.accessedURLs.isEmpty {
        Text("\(self.session.selectedIds.count)/\(self.session.itemCount) selected")
          .font(.footnote)
        List(session.groups, id: \.id) { group in
          BeauOptimizableGroupView(
            group: group,
            selectedIds: $session.selectedIds
          )
          Divider()
        }
      } else {
        DropZoneView(session: session)
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
