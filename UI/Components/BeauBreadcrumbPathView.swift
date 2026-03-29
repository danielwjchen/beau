import SwiftUI

struct BeauBreadcrumbPathView: View {
  let url: URL
  let components: [String]
  let isICloud: Bool
  let hasLeadingChevron: Bool

  init(url: URL, hasLeadingChevron: Bool = false) {
    let pieces = url.path.components(separatedBy: "/Library/Mobile Documents")
    if pieces.count > 1 {
      let subPieces = pieces[1].components(separatedBy: "/com~apple~CloudDocs")
      if subPieces.count > 1 {
        self.components = "/iCloud/\(subPieces[1])".split(separator: "/").map(String.init)
      } else {
        self.components = "/iCloud/\(pieces[1])".split(separator: "/").map(String.init)
      }
      self.isICloud = true
    } else {
      self.isICloud = false
      self.components = url.path.split(separator: "/").map(String.init)
    }

    self.url = url
    self.hasLeadingChevron = hasLeadingChevron
  }

  var body: some View {
    HStack(spacing: 4) {
      if hasLeadingChevron {
        Image(systemName: "chevron.right")
          .font(.caption)
          .foregroundColor(.secondary)
      }
      ForEach(Array(components.enumerated()), id: \.0) { index, element in
        Text(element)
          .font(.caption)
          .foregroundColor(.primary)
        if index < components.count - 1 {
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

#Preview {
  BeauBreadcrumbPathView(url: URL(string: "/home/foobar/Documents/Secrets/config.json")!)
    .padding(10)
}

#Preview("Path to Folder") {
  BeauBreadcrumbPathView(url: URL(string: "/home/foobar/Documents/Secrets/")!)
    .padding(10)
}

#Preview("iCloud") {
  BeauBreadcrumbPathView(
    url: URL(string: "/home/foobar/Library/Mobile Documents/Secrets/config.json")!
  )
  .padding(10)
}

#Preview("iCloud Docs") {
  BeauBreadcrumbPathView(
    url: URL(
      string: "/home/foobar/Library/Mobile Documents/com~apple~CloudDocs/Secrets/config.json")!
  )
  .padding(10)
}
