//
//  Helpers.swift
//  Beau
//
//  Created by Daniel Chen on 10/20/25.
//

import AVFoundation
import Foundation

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
func find4KVideoFiles(in videoFileURLs: [URL]) async -> [URL] {

  var result: [URL] = []
  for case let fileURL in videoFileURLs {
    // Check the video resolution.
    if await is4KVideo(at: fileURL) {
      result.append(fileURL)
    }
  }

  return result
}

/// Checks if a video file at a given URL has a 4K resolution (3840x2160 or higher).
/// - Parameter url: The URL of the video file.
/// - Returns: `true` if the video is 4K, otherwise `false`.
func is4KVideo(at url: URL) async -> Bool {
  let asset: AVAsset = AVAsset(url: url)
  do {
    guard let videoTrack: AVAssetTrack = try await asset.loadTracks(withMediaType: .video).first
    else {
      return false
    }

    let videoSize: CGSize = try await videoTrack.load(.naturalSize)
    let result: Bool =
      (videoSize.width >= 3840 && videoSize.height >= 2160)
      || (videoSize.height >= 3840 && videoSize.width >= 2160)
    return result
  } catch {
    return false
  }
}

enum ExportProgress {
  case started
  case progress(Float)
  case completed(URL)
  case failed(Error)
}

func encodeVideoWithProgress(
  from sourceURL: URL, to targetURL: URL,
  presetName: String = AVAssetExportPreset1920x1080
) -> AsyncThrowingStream<
  ExportProgress, Error
> {
  return AsyncThrowingStream { continuation in
    let asset = AVAsset(url: sourceURL)

    guard
      let exportSession = AVAssetExportSession(
        asset: asset,
        presetName: presetName,
      )
    else {
      continuation.finish(
        throwing: NSError(
          domain: "VideoConverter", code: 1,
          userInfo: [
            NSLocalizedDescriptionKey: "Failed to create export session."
          ]))
      return
    }

    exportSession.outputFileType = .mov
    exportSession.outputURL = targetURL

    // Remove old file if it exists to avoid conflicts.
    if FileManager.default.fileExists(atPath: targetURL.path) {
      try? FileManager.default.removeItem(at: targetURL)
    }

    continuation.yield(.started)

    // Start the export in a background task.
    exportSession.exportAsynchronously {
      switch exportSession.status {
      case .completed:
        continuation.yield(.completed(targetURL))
        continuation.finish()
      case .failed:
        if let error = exportSession.error {
          continuation.yield(.failed(error))
        }
        continuation.finish()
      case .cancelled:
        continuation.finish(
          throwing: NSError(
            domain: "VideoConverter", code: 3,
            userInfo: [
              NSLocalizedDescriptionKey: "Video export was cancelled."
            ]))
      default:
        break  // Wait for completion, failure, or cancellation.
      }
    }

    // Use a repeating timer to poll for progress updates.
    let timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
      guard exportSession.status == .exporting else { return }
      let progress = exportSession.progress
      if progress > 0.0 {
        continuation.yield(.progress(progress))
      }
    }

    // Handle cancellation of the `AsyncStream`.
    continuation.onTermination = { @Sendable _ in
      timer.invalidate()
      exportSession.cancelExport()
    }
  }
}

enum TempFileError: Error {
  case DirectoryNotFound
  case FileExists
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
