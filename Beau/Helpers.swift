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

func createBeauItems(
  _ fileURLs: [URL], _ targetResolution: CGSize, _ targetEncoding: String,
  progressHandler: @escaping (Float, String) -> Void
) async -> [any BeauMediaOptimizable] {

  var result: [any BeauMediaOptimizable] = []
  progressHandler(0, "Loading files")
  for (index, fileURL) in fileURLs.enumerated() {
    let progressPercentage = Float((index + 1) / fileURLs.count)
    progressHandler(progressPercentage, "\(fileURL.lastPathComponent) is found")
    if let BeauMediaOptimizableType = getBeauMediaOptimizableType(for: fileURL) {
      let item = BeauMediaOptimizableType.init(
        sourceURL: fileURL
      )
      do {
        item.sourceSize = try getFileSize(at: item.sourceURL)
        progressHandler(
          progressPercentage, "\(item.sourceURL.lastPathComponent): Loading video properties"
        )
        item.sourceResolution = try await BeauMediaOptimizableType.getDimensions(
          from: item.sourceURL
        )
      } catch {
        item.error = error.localizedDescription
      }
      result.append(item)
    } else {
      progressHandler(
        progressPercentage, "\(fileURL.lastPathComponent): Skipped unsupported file type"
      )
      continue
    }
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

func getTempFileURL(
  from sourceURL: URL,
  as targetFileExtension: String = ".tmp"
) throws -> URL {
  let folderURL = sourceURL.deletingLastPathComponent()
  var isDirectory: ObjCBool = false
  if FileManager.default.fileExists(atPath: folderURL.path, isDirectory: &isDirectory),
    !isDirectory.boolValue
  {
    throw BeauError.DirectoryNotFound()
  }
  let originalFileName = sourceURL.deletingPathExtension().lastPathComponent
  let tempFileName = originalFileName + targetFileExtension
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

func processBeauMediaOptimizable(
  _ item: any BeauMediaOptimizable, _ tempFileNamePattern: String
) async {
  do {
    if !item.isSelected {
      return
    }
    item.completionPercentage = 0
    let tempFileURL = try getTempFileURL(
      from: item.sourceURL, pattern: tempFileNamePattern
    )
    item.timeBegin = Date()
    try await item.optimizeWithProgress { progress in
      item.completionPercentage = progress
    }
    item.targetSize = try getFileSize(at: tempFileURL)
    if item.targetURL.path == item.sourceURL.path {
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
  _ items: [any BeauMediaOptimizable], _ videoPreset: VideoPreset
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

func getBeauMediaOptimizableType(for url: URL) -> (any BeauMediaOptimizable.Type)? {
  do {
    if let contentType = try url.resourceValues(forKeys: [.contentTypeKey]).contentType {
      if contentType.conforms(to: .movie) || contentType.conforms(to: .video) {
        return BeauVideoOptimizable.self
      } else if contentType.conforms(to: .image) {
        return BeauImageOptimizable.self
      }
    }
  } catch {
    print("Error getting content type for URL \(url): \(error)")
  }
  return nil
}
