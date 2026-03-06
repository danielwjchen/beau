import Foundation
import ImageIO
import Quartz

class BeauPDFOptimizable: BeauOptimizable {

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

  required init(
    sourceURL: URL
  ) {
    self.sourceURL = sourceURL
    self.targetURL = sourceURL
  }

  func hasBeenOptimized() throws -> Bool {
    let pdfDocument = PDFDocument(url: sourceURL)
    let attributes = pdfDocument?.documentAttributes ?? [:]
    if let existing = attributes[PDFDocumentAttribute.keywordsAttribute] as? [String] {
      if existing.contains(appSignature) {
        return true
      }
    }
    return false
  }

  func optimizeWithProgress(_ tempFileURL: URL, _ progressHandler: @escaping (Float) -> Void)
    async throws
  {
    // STUB
    return
  }

  class func getDimensions(from url: URL) async throws -> CGSize {
    // STUB
    return CGSize(width: 0, height: 0)

  }
}
