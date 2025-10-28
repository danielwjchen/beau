import SwiftUI

struct BeauItemView: View {
  @ObservedObject var item: BeauItem

  var body: some View {
    VStack(alignment: .leading) {
      Text(item.sourceURL.lastPathComponent)
      ProgressView(value: item.completionPercentage)
      if !item.error.isEmpty {
        Text(item.error)
          .foregroundColor(.red)
      }
    }
  }
}
