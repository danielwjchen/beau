import Foundation
import ImageIO
import Quartz

let QUARTZ_FILETER_PATH = "/System/Library/Filters/Reduce File Size.qfilter"

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
  @Published var processedOn: Date?

  required init(
    sourceURL: URL
  ) {
    self.sourceURL = sourceURL
    self.targetURL = sourceURL
    let pdfDocument = PDFDocument(url: sourceURL)
    let attributes = pdfDocument?.documentAttributes ?? [:]
    if let existing = attributes[PDFDocumentAttribute.keywordsAttribute] as? [String] {
      for keyword in existing {
        if let date = getProcessedOnDate(value: keyword) {
          self.processedOn = date
          break
        }
      }
    }
  }

  func optimizeWithProgress(_ tempFileURL: URL, _ progressHandler: @escaping (Float) -> Void)
    async throws
  {
    progressHandler(0.0)
    guard let pdfDocument = PDFDocument(url: sourceURL) else {
      throw BeauError.UnknownExportError("Could not load PDF document from source URL.")
    }

    let filterURL = URL(fileURLWithPath: QUARTZ_FILETER_PATH)
    progressHandler(0.1)

    guard let quartzFilter = QuartzFilter(url: filterURL) else {
      throw BeauError.UnknownExportError(
        "Could not load required library at \(QUARTZ_FILETER_PATH)")
    }
    progressHandler(0.4)

    let writeOptions: [PDFDocumentWriteOption: Any] = [
      .init(rawValue: "QuartzFilter"): quartzFilter
    ]

    var attributes = pdfDocument.documentAttributes ?? [:]
    let signature = getSignature()
    if let existing = attributes[PDFDocumentAttribute.keywordsAttribute] as? [String] {
      let filtered = existing.filter { !$0.contains(BEAU_SIGNATURE) }
      attributes[PDFDocumentAttribute.keywordsAttribute] = filtered + [signature]
    } else {
      attributes[PDFDocumentAttribute.keywordsAttribute] = [signature]
    }
    pdfDocument.documentAttributes = attributes
    let success = pdfDocument.write(to: tempFileURL, withOptions: writeOptions)
    progressHandler(0.7)

    guard success else {
      throw BeauError.UnknownExportError("Failed to save the optimized document.")
    }

    progressHandler(1.0)
  }

  class func getDimensions(from url: URL) async throws -> CGSize {
    guard let pdfDocument = PDFDocument(url: url) else {
      throw BeauError.UnknownExportError("Could not load PDF document from URL.")
    }

    guard let pageIndex = pdfDocument.pageCount > 0 ? 0 : nil else {
      throw BeauError.UnknownExportError("PDF document has no pages.")
    }
    let page = pdfDocument.page(at: pageIndex)
    let pageRect = page?.bounds(for: .mediaBox)

    return CGSize(width: (pageRect?.size.width)!, height: (pageRect?.size.height)!)

  }
}
