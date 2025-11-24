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
  @Published var thumbnail: CGImage?

  required init(
    sourceURL: URL
  ) {
    self.sourceURL = sourceURL
    self.targetURL = sourceURL.deletingPathExtension().appendingPathExtension("jpg")
  }

  func optimizeWithProgress(_ tempFileURL: URL, _ progressHandler: @escaping (Float) -> Void)
    async throws
  {
    let quality: CGFloat = 0.75
    progressHandler(0.0)

    guard let imageData = try? Data(contentsOf: sourceURL) else {
      throw BeauError.UnknownExportError("Could not load file from source URL.")
    }
    guard let image = NSImage(data: imageData) else {
      throw BeauError.UnknownExportError("Could not load image from source URL.")
    }
    let originalSize = image.size
    progressHandler(0.1)

    // Use an explicit bitmap-backed NSBitmapImageRep at the desired pixel size
    let targetSize = targetResolution ?? image.size
    let pixelWidth = max(1, Int(round(targetSize.width)))
    let pixelHeight = max(1, Int(round(targetSize.height)))

    guard
      let bitmapRep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelWidth,
        pixelsHigh: pixelHeight,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: NSColorSpaceName.deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
      )
    else {
      throw BeauError.UnknownExportError("Could not create bitmap representation.")
    }

    // Draw the source image into the bitmap rep at the requested pixel size.
    NSGraphicsContext.saveGraphicsState()
    guard let context = NSGraphicsContext(bitmapImageRep: bitmapRep) else {
      NSGraphicsContext.restoreGraphicsState()
      throw BeauError.UnknownExportError("Could not create graphics context for resizing.")
    }
    NSGraphicsContext.current = context
    context.cgContext.interpolationQuality = .high

    let drawRect = NSRect(x: 0, y: 0, width: CGFloat(pixelWidth), height: CGFloat(pixelHeight))
    image.draw(
      in: drawRect,
      from: NSRect(origin: .zero, size: originalSize),
      operation: .copy,
      fraction: 1.0,
      respectFlipped: true,
      hints: nil
    )
    NSGraphicsContext.restoreGraphicsState()

    progressHandler(0.4)

    let properties: [NSBitmapImageRep.PropertyKey: Any] = [
      .compressionFactor: quality
    ]

    guard let jpegData = bitmapRep.representation(using: .jpeg, properties: properties) else {
      throw BeauError.UnknownExportError("Could not convert jpeg data from source URL.")
    }

    progressHandler(0.7)
    do {
      try jpegData.write(to: tempFileURL, options: .atomic)
      progressHandler(1.0)
    } catch {
      throw BeauError.UnknownExportError("Could not write to \(tempFileURL).")
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
