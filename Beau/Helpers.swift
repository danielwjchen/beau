//
//  Helpers.swift
//  Beau
//
//  Created by Daniel Chen on 10/20/25.
//

import AVFoundation
import AppKit
import CoreGraphics
import Foundation
import QuickLookThumbnailing
import UniformTypeIdentifiers

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
  case UnableToLoadImage(String = "Unable to load image")
  case UnableToRemoveSourceFile(String = "Unable to remove source file")
}

func getFileURLs(in folderURL: URL) -> [URL] {
  let fileManager = FileManager.default
  var result: [URL] = []

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
      let fileAttributes = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
      if fileAttributes.isRegularFile != true {
        continue
      }
      result.append(fileURL)
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
  _ fileURLs: [URL], _ targetResolution: CGSize, _ targetEncoding: String,
  _ targetFileExtension: String = "mp4",
  progressHandler: @escaping (Float, String) -> Void
) async -> [BeauItem] {

  var result: [BeauItem] = []
  progressHandler(0, "Loading files")
  for (index, fileURL) in fileURLs.enumerated() {
    let progressPercentage = Float((index + 1) / fileURLs.count)
    progressHandler(progressPercentage, "\(fileURL.lastPathComponent) is found")
    let beauContentType = getBeauContentType(for: fileURL)
    if beauContentType == .other {
      continue
    }
    let targetURL = fileURL.deletingPathExtension().appendingPathExtension(targetFileExtension)
    let item = BeauItem(
      sourceURL: fileURL,
      targetURL: targetURL,
      targetResolution: targetResolution,
      targetEncoding: targetEncoding,
      contentType: beauContentType
    )
    do {
      item.sourceSize = try getFileSize(at: item.sourceURL)
      if item.contentType == .video {
        progressHandler(
          progressPercentage, "\(item.sourceURL.lastPathComponent): Loading video properties"
        )
        item.sourceResolution = try await getVideoDimensions(from: item.sourceURL)
      } else if item.contentType == .image {
        progressHandler(
          progressPercentage, "\(item.sourceURL.lastPathComponent): Loading image properties"
        )
        item.sourceResolution = try await getImageDimensions(from: item.sourceURL)
      }
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

func generateThumbnail(for url: URL, size: CGSize) async throws -> CGImage {
  let request = QLThumbnailGenerator.Request(
    fileAt: url,
    size: size,
    scale: NSScreen.main?.backingScaleFactor ?? 2,
    representationTypes: .all
  )

  return try await withCheckedThrowingContinuation { continuation in
    QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { rep, error in
      if let rep = rep {
        continuation.resume(returning: rep.cgImage)
      } else {
        continuation.resume(throwing: error ?? NSError(domain: "QL", code: -1))
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
    if item.contentType == .video {
      // @todo: support encoding
      try await encodeVideoWithProgress(
        from: item.sourceURL, to: tempFileURL
      ) { progress in
        item.completionPercentage = progress
      }
    } else if item.contentType == .image {
      try await optimizeImageWithProgress(
        from: item.sourceURL, to: tempFileURL
      ) { progress in
        item.completionPercentage = progress
      }
    } else {
      throw BeauError.UnknownExportError("Unsupported content type")
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

func getBeauContentType(for url: URL) -> BeauContentType {
  do {
    if let contentType = try url.resourceValues(forKeys: [.contentTypeKey]).contentType {
      if contentType.conforms(to: .movie) || contentType.conforms(to: .video) {
        return .video
      } else if contentType.conforms(to: .image) {
        return .image
      }
    }
  } catch {
    print("Error getting content type for URL \(url): \(error)")
  }
  return .other
}

func optimizeImageWithProgress(
  from sourceURL: URL,
  to targetURL: URL,
  maxDimension: CGFloat = 1600,
  quality: CGFloat = 0.75,
  progressHandler: @escaping (Float) -> Void
) async throws {
  progressHandler(0.0)
  guard let imageData = try? Data(contentsOf: sourceURL) else {
    throw BeauError.UnknownExportError("Could not load file from source URL.")
  }

  guard let image = NSImage(data: imageData) else {
    throw BeauError.UnknownExportError("Could not load image from source URL.")
  }

  progressHandler(0.1)

  let originalSize = image.size
  let scale: CGFloat

  if originalSize.width > maxDimension || originalSize.height > maxDimension {
    let maxCurrentDimension = max(originalSize.width, originalSize.height)
    scale = maxDimension / maxCurrentDimension
  } else {
    scale = 1.0
  }

  let newSize = NSSize(
    width: originalSize.width * scale,
    height: originalSize.height * scale
  )

  // Resizing
  let resizedImage = NSImage(size: newSize)
  resizedImage.lockFocus()
  image.draw(
    in: NSRect(origin: .zero, size: newSize),
    from: NSRect(origin: .zero, size: originalSize),
    operation: .sourceOver,
    fraction: 1.0)
  resizedImage.unlockFocus()

  guard let tiffData = resizedImage.tiffRepresentation else {
    throw BeauError.UnknownExportError("Could not load bitmap data from source URL.")
  }
  progressHandler(0.4)
  guard let bitmapRep = NSBitmapImageRep(data: tiffData) else {
    throw BeauError.UnknownExportError("Could not convert bitmap data from source URL.")
  }

  progressHandler(0.6)
  let properties: [NSBitmapImageRep.PropertyKey: Any] = [
    .compressionFactor: quality
  ]

  guard let jpegData = bitmapRep.representation(using: .jpeg, properties: properties) else {
    throw BeauError.UnknownExportError("Could not convert jpeg data from source URL.")
  }

  progressHandler(0.7)
  do {
    try jpegData.write(to: targetURL, options: .atomic)
    progressHandler(1.0)
  } catch {
    throw BeauError.UnknownExportError("Could not write to \(targetURL).")
  }
}

func getVideoDimensions(from url: URL) async throws -> CGSize {
  let asset: AVAsset = AVAsset(url: url)
  guard let videoTrack: AVAssetTrack = try await asset.loadTracks(withMediaType: .video).first
  else {
    throw BeauError.UnableToLoadVideoTrack()
  }
  let result = try await videoTrack.load(.naturalSize)
  return result
}

func getImageDimensions(from url: URL) async throws -> CGSize {

  guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
    throw BeauError.UnableToLoadImage()
  }

  let options: [NSString: Any] = [
    kCGImageSourceShouldCache as NSString: false  // Crucial: don't cache the full image data
  ]

  guard
    let imageProperties = CGImageSourceCopyPropertiesAtIndex(
      imageSource, 0, options as CFDictionary) as? [NSString: Any]
  else {
    throw BeauError.UnableToLoadImage("Could not retrieve image properties.")
  }

  // 3. Extract Width and Height.
  // ImageIO properties are often stored as CGImageProperty-related keys.
  guard let pixelWidth = imageProperties[kCGImagePropertyPixelWidth] as? CGFloat,
    let pixelHeight = imageProperties[kCGImagePropertyPixelHeight] as? CGFloat
  else {
    throw BeauError.UnableToLoadImage("Could not load image dimeensions.")
  }

  let result = CGSize(width: pixelWidth, height: pixelHeight)
  return result
}
