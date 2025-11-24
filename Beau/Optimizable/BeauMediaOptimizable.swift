import Foundation

protocol BeauMediaOptimizable: ObservableObject, AnyObject {
  var timeBegin: Date? { get set }
  var timeEnd: Date? { get set }
  var sourceURL: URL { get set }
  var targetURL: URL { get set }
  var sourceResolution: CGSize? { get set }
  var targetResolution: CGSize? { get set }
  var sourceEncoding: String { get set }
  var targetEncoding: String { get set }
  var sourceSize: Int64? { get set }
  var targetSize: Int64? { get set }

  var error: String { get set }
  var completionPercentage: Float? { get set }
  var isSelected: Bool { get set }
  init(sourceURL: URL)
  func optimizeWithProgress(_ tempFileURL: URL, _ progressHandler: @escaping (Float) -> Void)
    async throws
  func updateTargetResolution(_ targetResolution: CGSize)
  static func getDimensions(from url: URL) async throws -> CGSize
}

extension BeauMediaOptimizable {
  func updateTargetResolution(_ targetResolution: CGSize) {
    let maxTargetDimension = max(targetResolution.width, targetResolution.height)
    let maxSourceDimension = max(sourceResolution?.width ?? 0, sourceResolution?.height ?? 0)
    let scale = maxTargetDimension / maxSourceDimension
    self.targetResolution = CGSize(
      width: (sourceResolution?.width ?? 0) * scale,
      height: (sourceResolution?.height ?? 0) * scale
    )
  }
}
