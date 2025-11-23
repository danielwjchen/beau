//
//  Helpers.swift
//  Beau
//
//  Created by Daniel Chen on 10/20/25.
//

import AVFoundation
import CoreGraphics
import Foundation

#if os(macOS)
  import AppKit
#else
  import UIKit  // use AppKit instead if macOS
#endif

enum BeauError: Error {
  case DirectoryNotFound(String = "Directory not found")
  case FileExists(String = "File already exists")
  case UnableToEncode(String = "Unable to encode video")
  case UnknownExportError(String = "Unknown export error")
  case Cancelled(String = "Export cancelled")
  case UnableToLoadVideoTrack(String = "Unable to load video track")
  case UnableToRemoveSourceFile(String = "Unable to remove source file")
}

func getVideoFileURLs(in folderURL: URL) -> [URL] {
  let fileManager = FileManager.default
  var result: [URL] = []

  // Define a set of common video file extensions to filter by.
  let videoExtensions: Set<String> = [
    "mp4", "mov", "m4v", "avi", "mkv", "wmv", "flv", "webm",
  ]

  guard
    let enumerator = fileManager.enumerator(
      at: folderURL,
      includingPropertiesForKeys: nil,
      options: [.skipsHiddenFiles])
    //   includingPropertiesForKeys: [.isRegularFileKey],
    //   options: [.skipsHiddenFiles, .skipsPackageDescendants])
  else {
    print("Could not create enumerator for folder: \(folderURL.path)")
    return result
  }
  for case let fileURL as URL in enumerator {
    do {
      // Check if the item is a regular file.
      let fileAttributes = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
      if fileAttributes.isRegularFile != true {
        continue
      }
      if videoExtensions.contains(fileURL.pathExtension.lowercased()) {
        result.append(fileURL)
      }
    } catch {
      print("Error accessing file \(fileURL.path): \(error)")
    }
  }
  return result
}

func getFileSize(at url: URL) throws -> Int64? {
  let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
  return attributes[.size] as? Int64
}

/// Scans a directory and its subdirectories for 4K video files.
/// - Parameter folderURL: The URL of the folder to begin the search.
/// - Returns: An array of URLs pointing to the 4K video files found.
func createBeauItems(
  _ videoFileURLs: [URL], _ targetResolution: CGSize, _ targetEncoding: String,
  _ targetFileExtension: String = "mp4",
  progressHandler: @escaping (Float, String) -> Void
) async -> [BeauItem] {

  var result: [BeauItem] = []
  progressHandler(0, "Loading files")
  for (index, videoFileURL) in videoFileURLs.enumerated() {
    let progressPercentage = Float((index + 1) / videoFileURLs.count)
    progressHandler(progressPercentage, "\(videoFileURL.lastPathComponent) is found")
    let targetURL = videoFileURL.deletingPathExtension().appendingPathExtension(targetFileExtension)
    let item = BeauItem(
      sourceURL: videoFileURL,
      targetURL: targetURL,
      targetResolution: targetResolution,
      targetEncoding: targetEncoding
    )
    do {
      let asset: AVAsset = AVAsset(url: item.sourceURL)
      progressHandler(progressPercentage, "\(item.sourceURL.lastPathComponent): Loading file")
      guard let videoTrack: AVAssetTrack = try await asset.loadTracks(withMediaType: .video).first
      else {
        throw BeauError.UnableToLoadVideoTrack()
      }
      progressHandler(
        progressPercentage, "\(item.sourceURL.lastPathComponent): Loading video properties"
      )
      item.sourceResolution = try await videoTrack.load(.naturalSize)
      item.sourceSize = try getFileSize(at: item.sourceURL)
    } catch {
      item.error = error.localizedDescription
    }
    result.append(item)
  }

  return result
}

func is1080pVideo(videoSize: CGSize) -> Bool {
  let result: Bool =
    (videoSize.width >= 1920 && videoSize.height >= 1080)
    || (videoSize.height >= 1920 && videoSize.width >= 1080)

  return result
}

func is4KVideo(videoSize: CGSize) -> Bool {
  let result: Bool =
    (videoSize.width >= 3840 && videoSize.height >= 2160)
    || (videoSize.height >= 3840 && videoSize.width >= 2160)

  return result
}

func encodeVideoWithProgress(
  from sourceURL: URL, to targetURL: URL,
  presetName: String = AVAssetExportPreset1920x1080,
  progressHandler: @escaping (Float) -> Void
) async throws {
  let asset = AVAsset(url: sourceURL)

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

func getTempFileURL(
  from sourceURL: URL, pattern tempFileNamePattern: String, as targetFileExtension: String = ".mp4"
) throws -> URL {
  let folderURL = sourceURL.deletingLastPathComponent()
  var isDirectory: ObjCBool = false
  if FileManager.default.fileExists(atPath: folderURL.path, isDirectory: &isDirectory),
    !isDirectory.boolValue
  {
    throw BeauError.DirectoryNotFound()
  }
  let originalFileName = sourceURL.deletingPathExtension().lastPathComponent
  let tempFileName = originalFileName + tempFileNamePattern + targetFileExtension
  let result = folderURL.appendingPathComponent(tempFileName)
  if FileManager.default.fileExists(atPath: result.path) {
    throw BeauError.FileExists()
  }
  return result
}

func resizeCGImage(_ image: CGImage, to size: CGSize) -> CGImage? {
  guard let colorSpace = image.colorSpace else { return nil }
  guard
    let context = CGContext(
      data: nil,
      width: Int(size.width),
      height: Int(size.height),
      bitsPerComponent: image.bitsPerComponent,
      bytesPerRow: 0,
      space: colorSpace,
      bitmapInfo: image.bitmapInfo.rawValue
    )
  else {
    return nil
  }

  context.interpolationQuality = .high
  context.draw(image, in: CGRect(origin: .zero, size: size))
  return context.makeImage()
}

func generateThumbnail(
  for videoURL: URL,
  targetHeight: CGFloat = 100,
  at time: CMTime = CMTime(seconds: 1, preferredTimescale: 60)
)
  async throws -> CGImage
{
  return try await withCheckedThrowingContinuation { continuation in
    let asset = AVAsset(url: videoURL)
    let imageGenerator = AVAssetImageGenerator(asset: asset)
    imageGenerator.appliesPreferredTrackTransform = true
    imageGenerator.requestedTimeToleranceAfter = .zero
    imageGenerator.requestedTimeToleranceBefore = .zero

    // Get the first frame at time = 1 second (you can adjust this)
    let time = CMTime(seconds: 1.0, preferredTimescale: 600)

    // Generate asynchronously
    imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) {
      _, cgImage, _, result, error in
      if let error = error {
        continuation.resume(throwing: error)
        return
      }

      guard let cgImage = cgImage else {
        continuation.resume(
          throwing: NSError(
            domain: "ThumbnailError", code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Failed to generate thumbnail"]))
        return
      }

      // Scale the image to target height
      let originalWidth = CGFloat(cgImage.width)
      let originalHeight = CGFloat(cgImage.height)
      let scale = targetHeight / originalHeight
      let newSize = CGSize(width: originalWidth * scale, height: targetHeight)

      if let resized = resizeCGImage(cgImage, to: newSize) {
        continuation.resume(returning: resized)
      } else {
        continuation.resume(
          throwing: NSError(
            domain: "ThumbnailResizeError", code: -2,
            userInfo: [NSLocalizedDescriptionKey: "Failed to resize thumbnail"]))
      }
    }
  }
}

func moveFileToTrashIfExists(_ url: URL) throws -> Bool {
  let fileManager = FileManager.default

  // Make sure the file exists first
  guard fileManager.fileExists(atPath: url.path) else {
    return false
  }

  #if os(macOS)
    var resultingURL: NSURL?
    try fileManager.trashItem(at: url, resultingItemURL: &resultingURL)
    return true
  #else
    try fileManager.removeItem(at: url)
    return true
  #endif
}

func processBeauItem(_ item: BeauItem, _ tempFileNamePattern: String) async {
  do {
    if !item.isSelected {
      return
    }
    item.completionPercentage = 0
    let tempFileURL = try getTempFileURL(
      from: item.sourceURL, pattern: tempFileNamePattern
    )
    item.timeBegin = Date()
    try await encodeVideoWithProgress(
      from: item.sourceURL, to: tempFileURL
    ) { progress in
      item.completionPercentage = progress
    }
    item.targetSize = try getFileSize(at: tempFileURL)
    if item.targetURL.path == item.sourceURL.path || item.replacesSource {
      let isAbleToMoveSourceFileToTrash = try moveFileToTrashIfExists(
        item.sourceURL
      )
      if !isAbleToMoveSourceFileToTrash {
        throw BeauError.UnableToRemoveSourceFile()
      }
    }
    try FileManager.default.moveItem(
      at: tempFileURL,
      to: item.targetURL
    )
  } catch {
    item.error = error.localizedDescription
  }
  item.timeEnd = Date()
}

struct VideoPreset: Identifiable, Hashable {
  let id: String
  let label: String
  let width: CGFloat
  let height: CGFloat
  let encoding: String

  static let defaultValue: VideoPreset = .init(
    id: AVAssetExportPreset1920x1080,
    label: "Full HD (1080p)",
    width: 1920,
    height: 1080,
    encoding: "avc"
  )

  static let all: [VideoPreset] = [
    .init(
      id: AVAssetExportPreset3840x2160, label: "4K (2160p)", width: 3840, height: 2160,
      encoding: "avc"),
    defaultValue,
    .init(
      id: AVAssetExportPreset1280x720, label: "HD (720p)", width: 1280, height: 720,
      encoding: "avc"),
    .init(
      id: AVAssetExportPreset960x540, label: "qHD (540p)", width: 960, height: 540,
      encoding: "avc"),
    .init(
      id: AVAssetExportPreset640x480, label: "SD (480p)", width: 640, height: 480,
      encoding: "avc"),
    .init(
      id: AVAssetExportPresetLowQuality, label: "Low Quality (360p)", width: 480,
      height: 360, encoding: "avc"),
  ]
}

func setBeauItemsIsSelectedByVideoPreset(
  _ items: [BeauItem], _ videoPreset: VideoPreset
) {
  items.forEach({ item in
    if let width = item.sourceResolution?.width,
      let height = item.sourceResolution?.height
    {
      item.isSelected =
        ((width > videoPreset.width
          && height > videoPreset.height)
          || (height > videoPreset.width
            && width > videoPreset.height))
    } else {
      item.isSelected = false
    }
  })
}
