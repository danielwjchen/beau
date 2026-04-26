import SwiftUI

struct BeauOptimizableGroupView: View {

  let group: BeauOptimizableGroup
  @Binding var selectedIds: Set<UUID>
  @Environment(\.colorScheme) var colorScheme
  var textColor: Color {
    return colorScheme == .dark ? .white : .gray
  }

  var body: some View {
    VStack(alignment: .leading) {
      BreadcrumbPathView(url: group.url)
      ForEach(group.items, id: \.id) { item in
        BeauOptimizableView(item, group.url, $selectedIds)
          .listRowSeparator(.hidden)
      }
    }
  }
}

#Preview {
  BeauOptimizableGroupView(
    group: BeauPreviewMocks.getGroupWithItems(),
    selectedIds: .constant([])
  )
}
