import SwiftUI

class OptimizableGroup: ObservableObject, Identifiable {

  let url: URL

  let id = UUID()
  @Published var items: [any Optimizable] = []

  init(url: URL, items: [any Optimizable] = []) {
    self.url = url
    self.items = items
  }
}
