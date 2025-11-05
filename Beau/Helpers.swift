//
//  Helpers.swift
//  Beau
//
//  Created by Daniel Chen on 10/20/25.
//

import AVFoundation
import Foundation

enum TempFileError: Error {
  case DirectoryNotFound
  case FileExists
  case UnableToEncode
  case unknownExportError
  case cancelled
  case UnableToLoadVideoTrack
}

func getVideoFileURLs(in folderURL: URL) -> [URL] {
  let fileManager = FileManager.default
  var result: [URL] = []

  // Define a set of common video file extensions to filter by.
  let videoExtensions: Set<String> = [
    "mp4", "mov", "m4v", "avi", "mkv", "wmv", "flv", "webm",
  ]

  // Use an enumerator for a recursive, memory-efficient scan.
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

/// Scans a directory and its subdirectories for 4K video files.
/// - Parameter folderURL: The URL of the folder to begin the search.
/// - Returns: An array of URLs pointing to the 4K video files found.
func createBeauItems(
  _ videoFileURLs: [URL], _ targetResolution: CGSize, _ targetEncoding: String,
  _ targetFileExtension: String = "mp4"
) async -> [BeauItem] {

  var result: [BeauItem] = []
  for case let videoFileURL in videoFileURLs {
    let targetURL = videoFileURL.deletingPathExtension().appendingPathExtension(targetFileExtension)
    let item = BeauItem(
      sourceURL: videoFileURL,
      targetURL: targetURL,
      targetResolution: targetResolution,
      targetEncoding: targetEncoding
    )
    do {
      let asset: AVAsset = AVAsset(url: videoFileURL)
      guard let videoTrack: AVAssetTrack = try await asset.loadTracks(withMediaType: .video).first
      else {
        throw TempFileError.UnableToLoadVideoTrack
      }
      item.sourceResolution = try await videoTrack.load(.naturalSize)
    } catch {
      item.error = error.localizedDescription
    }
    // Check the video resolution.
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
    throw TempFileError.UnableToEncode
  }

  exportSession.outputFileType = .mp4
  exportSession.outputURL = targetURL

  // Remove old file if it exists to avoid conflicts.
  if FileManager.default.fileExists(atPath: targetURL.path) {
    throw TempFileError.FileExists
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
    throw TempFileError.unknownExportError
  case .cancelled:
    throw TempFileError.cancelled
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
    throw TempFileError.DirectoryNotFound
  }
  let originalFileName = sourceURL.deletingPathExtension().lastPathComponent
  let tempFileName = originalFileName + tempFileNamePattern + targetFileExtension
  let result = folderURL.appendingPathComponent(tempFileName)
  if FileManager.default.fileExists(atPath: result.path) {
    throw TempFileError.FileExists
  }
  return result
}
