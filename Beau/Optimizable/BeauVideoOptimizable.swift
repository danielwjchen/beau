import AVFoundation
import Foundation

class BeauVideoOptimizable: BeauOptimizable {

  let id = UUID()
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
  @Published var thumbnail: CGImage?
  @Published var processedOn: Date?

  required init(
    sourceURL: URL
  ) {
    self.sourceURL = sourceURL
    self.targetURL = sourceURL.deletingPathExtension().appendingPathExtension("mp4")
    let asset = AVAsset(url: sourceURL)

    Task {
      do {
        let metadata = try await asset.load(.metadata)
        let descriptionItems = AVMetadataItem.metadataItems(
          from: metadata,
          filteredByIdentifier: .commonIdentifierDescription
        )
        for item in descriptionItems {
          guard let value = try await item.load(.value) as? String else { return }
          if value.contains(BEAU_SIGNATURE) {
            self.processedOn = getProcessedOnDate(value: value)
          }
        }
      } catch {
        print("Unable to read video metadata for \(sourceURL).")
      }
    }
  }

  func optimizeWithProgress(_ tempFileURL: URL, _ progressHandler: @escaping (Float) -> Void)
    async throws
  {
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
    exportSession.outputURL = tempFileURL

    // Remove old file if it exists to avoid conflicts.
    if FileManager.default.fileExists(atPath: tempFileURL.path) {
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

    var metadata = try await asset.load(.metadata)
    let signature = getSignature()
    var replacesExisting = false
    if let index = metadata.firstIndex(where: {
      return $0.identifier == .commonIdentifierDescription
    }) {
      let existingValue = try await metadata[index].load(.value)
      let existing = (existingValue as? String) ?? ""
      if existing.contains(BEAU_SIGNATURE) {
        let filtered = removeSignature(from: existing)
        if let mutableItem = metadata[index].mutableCopy() as? AVMutableMetadataItem {
          mutableItem.value = "\(filtered) \(signature)" as NSString
          metadata[index] = mutableItem
          exportSession.metadata = metadata
          replacesExisting = true
        }
      }
    }
    if !replacesExisting {
      let metadataItem = AVMutableMetadataItem()
      metadataItem.keySpace = .common
      metadataItem.value = signature as NSString
      metadataItem.extendedLanguageTag = "und"
      metadataItem.identifier = .commonIdentifierDescription
      metadata.append(metadataItem)
      exportSession.metadata = metadata
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
