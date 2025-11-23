import SwiftUI

struct BeauLoadingView: View {
  let baseText: String
  let maxDots: Int
  let speed: Double  // dots per second

  init(_ baseText: String = "Loading", maxDots: Int = 3, speed: Double = 2.0) {
    self.baseText = baseText
    self.maxDots = maxDots
    self.speed = speed
  }

  var body: some View {
    TimelineView(.animation) { context in
      let timeInterval = context.date.timeIntervalSinceReferenceDate
      let step = Int(floor(timeInterval * speed)) % (maxDots + 1)
      HStack(alignment: .center, spacing: 0.0) {
        Text(self.baseText)
        Text(".").opacity(step >= 1 ? 1 : 0)
        Text(".").opacity(step >= 2 ? 1 : 0)
        Text(".").opacity(step >= 3 ? 1 : 0)
      }
      .animation(.default, value: step)
    }
  }
}

#Preview {
  BeauLoadingView("Loading")
    .padding(10)
    .frame(minWidth: 100)
}
