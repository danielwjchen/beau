import AVFoundation
import Foundation

class BeauVideoOptimizable: BeauMediaOptimizable {

  var sourceURL: URL
  var targetURL: URL

  @Published var timeBegin: Date?
  @Published var timeEnd: Date?
  @Published var sourceSize: Int64?
  @Published var targetSize: Int64?
  @Published var sourceResolution: CGSize?
  @Published var targetResolution: CGSize?
  @Published var sourceEncoding: String = ""
  @Published var targetEncoding: String = ""
  @Published var error: String = ""
  @Published var completionPercentage: Float? = nil
  @Published var isSelected: Bool = true

  required init(
    sourceURL: URL
  ) {
    self.sourceURL = sourceURL
    self.targetURL = sourceURL.deletingPathExtension().appendingPathExtension("mp4")
  }

  func optimizeWithProgress(progressHandler: @escaping (Float) -> Void) async throws {
    let asset = AVAsset(url: sourceURL)
    let presetName: String = AVAssetExportPreset1920x1080

    guard
      let exportSession = AVAssetExportSession(
        asset: asset,
        presetName: presetName,
      )
    else {
      throw BeauError.UnableToEncode()
    }

    exportSession.outputFileType = .mp4
    exportSession.outputURL = targetURL

    // Remove old file if it exists to avoid conflicts.
    if FileManager.default.fileExists(atPath: targetURL.path) {
      throw BeauError.FileExists()
    }

    progressHandler(0.0)
    // Use a Task for progress reporting.
    let progressTask = Task {
      while exportSession.progress < 1.0 {
        progressHandler(exportSession.progress)
        try await Task.sleep(for: .milliseconds(500))  // Report every half-second.
      }
    }

    // Start the export operation.
    await exportSession.export()

    // End the progress monitoring task.
    progressTask.cancel()

    // Handle completion or failure.
    switch exportSession.status {
    case .completed:
      progressHandler(1.0)  // Report 100% completion.
    case .failed:
      if let error = exportSession.error {
        throw error
      }
      throw BeauError.UnknownExportError()
    case .cancelled:
      throw BeauError.Cancelled()
    default:
      break
    }
  }

  class func getDimensions(from url: URL) async throws -> CGSize {
    let asset: AVAsset = AVAsset(url: url)
    guard let videoTrack: AVAssetTrack = try await asset.loadTracks(withMediaType: .video).first
    else {
      throw BeauError.UnableToLoadVideoTrack()
    }
    let result = try await videoTrack.load(.naturalSize)
    return result
  }
}
