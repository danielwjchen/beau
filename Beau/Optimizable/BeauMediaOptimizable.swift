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
  func optimizeWithProgress(progressHandler: @escaping (Float) -> Void) async throws
  static func getDimensions(from url: URL) async throws -> CGSize
}
