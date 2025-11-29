import AppKit
import Foundation
import ImageIO
import UniformTypeIdentifiers

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

    // Create an image source so we can read metadata
    guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil) else {
      throw BeauError.UnknownExportError("Could not create image source.")
    }

    // Grab original metadata (EXIF, TIFF, GPS, etc.)
    let originalMetadata =
      CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any] ?? [:]

    // Create a CGImage from the source for drawing/resizing
    guard let originalCGImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
      throw BeauError.UnknownExportError("Could not create CGImage from source.")
    }

    progressHandler(0.1)

    // Prepare target size
    let targetSize =
      targetResolution ?? CGSize(width: originalCGImage.width, height: originalCGImage.height)
    let pixelWidth = max(1, Int(round(targetSize.width)))
    let pixelHeight = max(1, Int(round(targetSize.height)))

    // Create a bitmap context to draw the resized image
    guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
      throw BeauError.UnknownExportError("Could not create color space.")
    }

    guard
      let context = CGContext(
        data: nil,
        width: pixelWidth,
        height: pixelHeight,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
      )
    else {
      throw BeauError.UnknownExportError("Could not create graphics context for resizing.")
    }

    context.interpolationQuality = .high

    // Flip coordinate system for correct drawing if needed
    context.saveGState()
    context.translateBy(x: 0, y: CGFloat(pixelHeight))
    context.scaleBy(x: 1.0, y: -1.0)

    let drawRect = CGRect(x: 0, y: 0, width: CGFloat(pixelWidth), height: CGFloat(pixelHeight))
    context.draw(originalCGImage, in: drawRect)
    context.restoreGState()

    guard let resizedCGImage = context.makeImage() else {
      throw BeauError.UnknownExportError("Could not create resized CGImage.")
    }

    progressHandler(0.4)

    // Prepare metadata for destination, merging original metadata and compression quality
    var destinationMetadata = originalMetadata
    destinationMetadata[kCGImageDestinationLossyCompressionQuality] = quality as CFNumber

    // Create image destination and write the resized image along with metadata
    guard
      let destination = CGImageDestinationCreateWithURL(
        tempFileURL as CFURL,
        UTType.jpeg.identifier as CFString,
        1,
        nil
      )
    else {
      throw BeauError.UnknownExportError("Could not create image destination.")
    }

    CGImageDestinationAddImage(destination, resizedCGImage, destinationMetadata as CFDictionary)

    progressHandler(0.7)

    if !CGImageDestinationFinalize(destination) {
      throw BeauError.UnknownExportError("Failed to write optimized image with metadata.")
    }

    progressHandler(1.0)
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
