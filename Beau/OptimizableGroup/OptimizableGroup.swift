import SwiftUI

@Observable
class OptimizableGroup: Identifiable {

  let url: URL

  let id = UUID()
  var items: [BaseOptimizable] = []

  init(url: URL, items: [BaseOptimizable] = []) {
    self.url = url
    self.items = items
  }
}
