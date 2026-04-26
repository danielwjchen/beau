import SwiftUI

struct OptimizableGroupView: View {

  let group: OptimizableGroup
  @Binding var selectedIds: Set<UUID>
  @Environment(\.colorScheme) var colorScheme
  var textColor: Color {
    return colorScheme == .dark ? .white : .gray
  }

  var selectedCount: Int {
    return group.items.filter { selectedIds.contains($0.id) }.count
  }

  var body: some View {
    VStack(alignment: .leading) {
      HStack(alignment: .center) {
        Text("\(selectedCount)/\(group.items.count) selected")
          .font(.footnote)
        BreadcrumbPathView(url: group.url)
      }
      ForEach(Array(group.items.enumerated()), id: \.element.id) { index, item in
        OptimizableView(item, group.url, $selectedIds)
          .background(index % 2 == 0 ? Color.gray.opacity(0.1) : Color.clear)
          .listRowSeparator(.hidden)
      }
    }
  }
}

#Preview {
  OptimizableGroupView(
    group: BeauPreviewMocks.getGroupWithItems(),
    selectedIds: .constant([])
  )
}
