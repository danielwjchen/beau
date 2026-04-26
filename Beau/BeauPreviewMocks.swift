import Foundation

struct BeauPreviewMocks {

  static let folderURL = URL(fileURLWithPath: "/path/to/folder")

  public static func getVideoOptimizableIsSelected() -> BeauVideoOptimizable {
    let item = BeauVideoOptimizable(sourceURL: URL(fileURLWithPath: "/path/to/folder/video.mp4"))
    item.timeBegin = Date()
    item.sourceResolution = CGSize(width: 1920, height: 1080)
    item.targetResolution = CGSize(width: 1280, height: 720)
    item.sourceEncoding = "h264"
    item.targetEncoding = "h265"
    item.sourceSize = 50_000_000
    item.timeBegin = Date()
    return item
  }

  public static func getVideoOptimizableInProgress() -> BeauVideoOptimizable {
    let item = BeauVideoOptimizable(
      sourceURL: URL(fileURLWithPath: "/path/to/folder/2025-12-01/video.mp4"))
    item.timeBegin = Date()
    item.sourceResolution = CGSize(width: 1920, height: 1080)
    item.targetResolution = CGSize(width: 1280, height: 720)
    item.sourceEncoding = "h264"
    item.targetEncoding = "h265"
    item.sourceSize = 50_000_000
    item.completionPercentage = 0.5
    item.timeBegin = Date()
    return item
  }

  public static func getImageOptimizableSuccessful() -> BeauImageOptimizable {
    let item = BeauImageOptimizable(
      sourceURL: URL(fileURLWithPath: "/path/to/folder/2025-12-02/image.jpg"))
    item.sourceResolution = CGSize(width: 4000, height: 3000)
    item.targetResolution = CGSize(width: 1920, height: 1440)
    item.sourceSize = 25_000_000
    item.targetSize = 3_000_000
    item.timeBegin = Date()
    item.timeEnd = Date().addingTimeInterval(60)
    return item
  }

  public static func getImageOptimizableWithError() -> BeauImageOptimizable {
    let item = BeauImageOptimizable(
      sourceURL: URL(fileURLWithPath: "/path/to/folder/2025-12-03/image.png"))
    item.sourceResolution = CGSize(width: 4000, height: 3000)
    item.targetResolution = CGSize(width: 1920, height: 1440)
    item.sourceSize = 20_000_000
    item.error = "Failed to optimize image due to unsupported format."
    item.timeBegin = Date()
    return item
  }

  public static func getGroupWithItems() -> BeauOptimizableGroup {
    let isSelectedItem = getVideoOptimizableIsSelected()
    let videoItem = getVideoOptimizableInProgress()
    let imageItem = getImageOptimizableSuccessful()
    let errorItem = getImageOptimizableWithError()

    return BeauOptimizableGroup(
      url: URL(fileURLWithPath: "/path/to/folder"),
      items: [isSelectedItem, videoItem, imageItem, errorItem]
    )
  }

  public static func getSessionWithItems() -> BeauSession {
    let session = getSessionEmpty()
    session.groups = [
      getGroupWithItems()
    ]
    return session
  }

  public static func getSessionWithSelectedItems() -> BeauSession {
    let session = getSessionWithItems()
    session.isReady = true
    session.selectedIds = [session.groups[0].items[0].id, session.groups[0].items[2].id]
    return session
  }

  public static func getSessionWithSelectedItemsProcessing() -> BeauSession {
    let session = getSessionWithItems()
    session.selectedIds = [session.groups[0].items[0].id, session.groups[0].items[2].id]
    session.timeBegin = Date()
    return session
  }

  public static func getSessionEmpty() -> BeauSession {
    let session = BeauSession(from: BeauTargetPreset.defaultValue)
    return session
  }

}
