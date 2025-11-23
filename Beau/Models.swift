//
//  Models.swift
//  Beau
//
//  Created by Daniel Chen on 10/20/25.
//
import Foundation

enum BeauContentType {
  case video
  case image
  case other
}

class BeauItem: ObservableObject {
  var sourceURL: URL
  var targetURL: URL
  var rename: String = ""
  var contentType: BeauContentType = .other
  @Published var timeBegin: Date?
  @Published var timeEnd: Date?
  var sourceResolution: CGSize?
  var targetResolution: CGSize
  var sourceEncoding: String = ""
  var targetEncoding: String
  var sourceSize: Int64? = nil
  @Published var targetSize: Int64? = nil
  @Published var error: String = ""
  @Published var completionPercentage: Float? = nil
  @Published var isSelected: Bool = true
  @Published var replacesSource: Bool = true
  init(
    sourceURL: URL,
    targetURL: URL,
    targetResolution: CGSize,
    targetEncoding: String,
    contentType: BeauContentType
  ) {
    self.sourceURL = sourceURL
    self.targetURL = targetURL
    self.targetResolution = targetResolution
    self.targetEncoding = targetEncoding
    self.contentType = contentType
  }
  init(
    sourceURL: URL,
    targetURL: URL,
    targetResolution: CGSize,
    targetEncoding: String,
    sourceResolution: CGSize,
    sourceEncoding: String,
    sourceFileSize: Int64?
  ) {
    self.sourceURL = sourceURL
    self.targetURL = targetURL
    self.targetResolution = targetResolution
    self.targetEncoding = targetEncoding
    self.sourceResolution = sourceResolution
    self.sourceEncoding = sourceEncoding
    self.sourceSize = sourceFileSize
  }
}

class BeauSession: ObservableObject {
  var isInPlace: Bool
  var resolution: String
  var encoding: String
  var renamePattern: String
  var tempFileNamePattern: String
  var preservesMeta: Bool
  var sourceURL: URL?
  var targetURL: URL?
  var preservesFolders: Bool
  @Published var items: [BeauItem] = []
  @Published var replacesSource: Bool = true
  var timeBegin: Date?
  var timeEnd: Date?

  init(
    isInPlace: Bool = true,
    resolution: String,
    encoding: String,
    renamePattern: String = "",
    tempFileNamePattern: String = ".tmp",
    preservesMeta: Bool = true,
    sourceURL: URL? = nil,
    targetURL: URL? = nil,
    preservesFolders: Bool = true,
    items: [BeauItem] = [],
    timeBegin: Date? = nil,
    timeEnd: Date? = nil
  ) {
    self.isInPlace = isInPlace
    self.resolution = resolution
    self.encoding = encoding
    self.renamePattern = renamePattern
    self.tempFileNamePattern = tempFileNamePattern
    self.preservesMeta = preservesMeta
    self.sourceURL = sourceURL
    self.targetURL = targetURL
    self.preservesFolders = preservesFolders
    self.items = items
    self.timeBegin = timeBegin
    self.timeEnd = timeEnd
  }
}
