import AppKit
import Foundation

class BeauImageOptimizable: BeauMediaOptimizable {

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
    self.targetURL = sourceURL.deletingPathExtension().appendingPathExtension("jpg")
  }

  func optimizeWithProgress(progressHandler: @escaping (Float) -> Void) async throws {
    let maxDimension: CGFloat = 1600
    let quality: CGFloat = 0.75
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

  class func getDimensions(from url: URL) async throws -> CGSize {

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
}
