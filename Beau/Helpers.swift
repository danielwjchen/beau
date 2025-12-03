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

func createBeauMediaOptimizable(
  _ fileURLs: [URL], _ targetResolution: CGSize, _ targetEncoding: String,
  progressHandler: @escaping (Float, String) -> Void
) async -> [any BeauOptimizable] {
  let thumbnailSize: CGSize = CGSize(width: 100, height: 100)
  var result: [any BeauOptimizable] = []
  progressHandler(0, "Loading files")
  for (index, fileURL) in fileURLs.enumerated() {
    let itemNumber = index + 1
    let progressPercentage = Float(itemNumber) / Float(fileURLs.count)
    let progressMessage = "\(itemNumber)/\(fileURLs.count)"
    progressHandler(progressPercentage, "\(progressMessage) \(fileURL.lastPathComponent) is found")
    if let BeauMediaOptimizableType = getBeauMediaOptimizableType(for: fileURL) {
      let item = BeauMediaOptimizableType.init(
        sourceURL: fileURL
      )
      do {
        item.sourceSize = try getFileSize(at: item.sourceURL)
        progressHandler(
          progressPercentage,
          "\(progressMessage) \(item.sourceURL.lastPathComponent): Loading properties"
        )
        item.sourceResolution = try await BeauMediaOptimizableType.getDimensions(
          from: item.sourceURL
        )
        item.updateTargetResolution(targetResolution)
        progressHandler(
          progressPercentage,
          "\(progressMessage) \(item.sourceURL.lastPathComponent): Generating thumbnail"
        )
        item.thumbnail = try await generateThumbnail(
          for: item.sourceURL, size: thumbnailSize
        )
      } catch {
        item.error = error.localizedDescription
      }
      result.append(item)
    } else {
      progressHandler(
        progressPercentage,
        "\(progressMessage) \(fileURL.lastPathComponent): Skipped unsupported file type"
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

@discardableResult
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
  _ item: any BeauOptimizable, _ tempFileNamePattern: String
) async {
  item.completionPercentage = 0
  do {
    let tempFileURL = try getTempFileURL(from: item.sourceURL)
    do {

      item.timeBegin = Date()
      try await item.optimizeWithProgress(tempFileURL) { progress in
        item.completionPercentage = progress
      }
      item.targetSize = try getFileSize(at: tempFileURL)
      let isAbleToMoveSourceFileToTrash = try moveFileToTrashIfExists(
        item.sourceURL
      )
      if !isAbleToMoveSourceFileToTrash {
        throw BeauError.UnableToRemoveSourceFile()
      }
      try FileManager.default.moveItem(
        at: tempFileURL,
        to: item.targetURL
      )
    } catch {
      item.error = error.localizedDescription
      try moveFileToTrashIfExists(tempFileURL)
    }
  } catch {
    item.error = error.localizedDescription
  }
  item.timeEnd = Date()
}

func getBeauMediaOptimizableType(for url: URL) -> (any BeauOptimizable.Type)? {
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
