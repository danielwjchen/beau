import SwiftUI

class BeauOptimizableGroup: ObservableObject, Identifiable {

  let url: URL

  let id = UUID()
  @Published var items: [any BeauOptimizable] = []

  init(url: URL, items: [any BeauOptimizable] = []) {
    self.url = url
    self.items = items
  }
}
