import CoreGraphics
import Foundation

let BEAU_SIGNATURE = "Optimized with Beau"

protocol Optimizable: ObservableObject, Identifiable {
  var id: UUID { get }
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
  var thumbnail: CGImage? { get set }
  var processedOn: Date? { get set }

  var error: String { get set }
  var completionPercentage: Float? { get set }
  init(sourceURL: URL)
  func optimizeWithProgress(_ tempFileURL: URL, _ progressHandler: @escaping (Float) -> Void)
    async throws
  func updateTargetResolution(_ targetResolution: CGSize)
  static func getDimensions(from url: URL) async throws -> CGSize
}

extension Optimizable {
  func updateTargetResolution(_ targetResolution: CGSize) {
    let maxTargetDimension = max(targetResolution.width, targetResolution.height)
    let maxSourceDimension = max(sourceResolution?.width ?? 0, sourceResolution?.height ?? 0)
    let scale = maxTargetDimension / maxSourceDimension
    self.targetResolution = CGSize(
      width: (sourceResolution?.width ?? 0) * scale,
      height: (sourceResolution?.height ?? 0) * scale
    )
  }

  func getProcessedOnDate(value: String) -> Date? {
    let pieces = value.components(separatedBy: "\(BEAU_SIGNATURE):")
    if pieces.count == 2 {
      let dateString = pieces[1].trimmingCharacters(in: .whitespacesAndNewlines).replacing(
        ")", with: "")
      let formatter = ISO8601DateFormatter()
      return formatter.date(from: dateString)
    }
    return nil
  }

  func getSignature() -> String {
    let formatter = ISO8601DateFormatter()
    let timestamp = formatter.string(from: Date())
    return "[\(BEAU_SIGNATURE): \(timestamp)]"
  }

  func removeSignature(from input: String) -> String {
    let pattern = "\\[\(BEAU_SIGNATURE):[^\\]]*\\]"
    guard let regex = try? Regex(pattern) else { return input }
    return input.replacing(regex, with: "")
  }
}
