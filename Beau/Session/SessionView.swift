import SwiftUI

struct SessionView: View {
  @ObservedObject var session: Session

  init(_ session: Session) {
    self.session = session
  }

  var body: some View {
    VStack(alignment: .leading) {
      if !session.groups.isEmpty {
        Text("\(self.session.selectedIds.count)/\(self.session.itemCount) selected")
          .font(.footnote)
          .padding(.leading, 14)
          .padding(.top, 8)
          .padding(.bottom, 2)
        List(session.groups, id: \.id) { group in
          OptimizableGroupView(
            group: group,
            selectedIds: $session.selectedIds
          )
          .listRowSeparator(.hidden)
        }
      } else {
        DropZoneView(session: session)
      }
    }
  }
}

#Preview("Empty Session") {
  SessionView(BeauPreviewMocks.getSessionEmpty())
}

#Preview("With Items") {
  SessionView(BeauPreviewMocks.getSessionWithItems())
}
