import SwiftUI

struct BeauOptimizableGroupView: View {

  let group: BeauOptimizableGroup
  @Binding var selectedIds: Set<UUID>

  var body: some View {
    VStack(alignment: .leading) {
      BreadcrumbPathView(url: group.url)
      List(group.items, id: \.id) { item in
        // Type check to determine the concrete type of BeauMediaOptimizable
        if type(of: item) == BeauVideoOptimizable.self {
          BeauItemView(item as! BeauVideoOptimizable, group.url, $selectedIds)
            .listRowSeparator(.hidden)
        } else if type(of: item) == BeauImageOptimizable.self {
          BeauItemView(item as! BeauImageOptimizable, group.url, $selectedIds)
            .listRowSeparator(.hidden)
        } else if type(of: item) == BeauPDFOptimizable.self {
          BeauItemView(item as! BeauPDFOptimizable, group.url, $selectedIds)
            .listRowSeparator(.hidden)
        } else {
          Text("Unsupported item type")
            .listRowSeparator(.hidden)
        }
        Divider()
      }
    }
  }
}
