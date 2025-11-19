import SwiftUI

struct BeauBreadcrumbPathView: View {
  let url: URL

  private var pathComponents: [URL] {
    var components: [URL] = []
    var current = url

    while current.path != "/" {
      components.insert(current, at: 0)
      current.deleteLastPathComponent()
    }

    return components
  }

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 4) {
        ForEach(Array(pathComponents.enumerated()), id: \.element) { index, element in
          Text(element.lastPathComponent)
            .font(.caption)
            .foregroundColor(.primary)
          if index < pathComponents.count - 1 {
            Image(systemName: "chevron.right")
              .font(.caption)
              .foregroundColor(.secondary)
          }
        }
      }
      .lineLimit(1)
      .truncationMode(.middle)
    }
  }
}

#Preview {
    BeauBreadcrumbPathView(url: URL(string: "/home/foobar/Documents/Secrets/config.json")!)
}
