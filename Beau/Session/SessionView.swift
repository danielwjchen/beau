import SwiftUI

struct SessionView: View {
  @Bindable var session: Session

  init(_ session: Session) {
    self.session = session
  }

  var body: some View {
    VStack(alignment: .leading) {
      if !session.groups.isEmpty && !session.isLoading {
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
      }
      if session.groups.isEmpty && !session.isLoading {
        DropZoneView(session: session)
      }
      if session.isLoading || session.isOptimizing {
        LoadingView(session.itemProgressMessage)
          .font(.caption)
          .padding(.top, 4)
          .padding(.leading, 8)
          .padding(.trailing, 8)
          .padding(.bottom, 2)
        ProgressView(value: session.itemProgressPercentage)
          .padding(.top, 2)
          .padding(.leading, 8)
          .padding(.trailing, 8)
          .padding(.bottom, 8)
      }
    }
  }
}

#Preview("Empty Session") {
  SessionView(BeauPreviewMocks.getSessionEmpty())
}

#Preview("Is Loading") {
  SessionView(BeauPreviewMocks.getSessionIsLoading())
}

#Preview("With Items") {
  SessionView(BeauPreviewMocks.getSessionWithItems())
}

#Preview("Is Optimizing") {
  SessionView(BeauPreviewMocks.getSessionIsOptimizing())
}
