import SwiftUI

struct BeauSessionView: View {
  @ObservedObject var session: BeauSession

  init(_ session: BeauSession) {
    self.session = session
  }

  var body: some View {
    VStack(alignment: .leading) {
      if let sourceURL = session.sourceURL {
        BeauBreadcrumbPathView(url: sourceURL)
          .padding(8)
        List(session.items, id: \.sourceURL) { item in
          // Type erasure to determine the concrete type of BeauMediaOptimizable
          if let videoItem = item as? BeauVideoOptimizable {
            BeauItemView(videoItem, sourceURL)
          } else if let imageItem = item as? BeauImageOptimizable {
            BeauItemView(imageItem, sourceURL)
          } else {
            Text("Unsupported item type")
          }
        }
      } else {
        Text("No source directory selected.")
          .padding(8)
        Spacer()
      }
    }
  }
}

#Preview("Empty Session") {
  BeauSessionView(
    BeauSession(
      from: TargetPreset.defaultValue
    )
  )
}

#Preview("With Items") {
  let session = BeauSession(from: TargetPreset.defaultValue)
  session.sourceURL = URL(string: "/Users/foobar/Videos")!

  // Create sample video item
  let videoItem = BeauVideoOptimizable(
    sourceURL: URL(string: "/Users/foobar/Videos/sample_4k.mov")!
  )
  videoItem.sourceResolution = CGSize(width: 3840, height: 2160)
  videoItem.sourceSize = 5_000_000_000
  videoItem.targetResolution = CGSize(width: 1920, height: 1080)
  videoItem.targetSize = 1_200_000_000
  videoItem.isSelected = true
  videoItem.completionPercentage = 0.65

  // Create sample image item
  let imageItem = BeauImageOptimizable(
    sourceURL: URL(string: "/Users/foobar/Pictures/photo_large.png")!
  )
  imageItem.sourceResolution = CGSize(width: 4000, height: 3000)
  imageItem.sourceSize = 30_000_000
  imageItem.targetResolution = CGSize(width: 1920, height: 1440)
  imageItem.targetSize = 2_500_000
  imageItem.isSelected = true
  imageItem.timeEnd = Date()

  // Create completed item with error
  let errorItem = BeauVideoOptimizable(
    sourceURL: URL(string: "/Users/foobar/Videos/corrupted.mov")!
  )
  errorItem.sourceResolution = CGSize(width: 2560, height: 1440)
  errorItem.sourceSize = 2_000_000_000
  errorItem.error = "Unable to load video track"
  errorItem.isSelected = false

  session.items = [videoItem, imageItem, errorItem]

  return BeauSessionView(session)
}
