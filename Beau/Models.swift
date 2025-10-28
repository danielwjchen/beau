//
//  Models.swift
//  Beau
//
//  Created by Daniel Chen on 10/20/25.
//
import Foundation

class BeauItem: ObservableObject {
  var sourceURL: URL
  var targetURL: URL
  var rename: String = ""
  var timeBegin: Date?
  var timeEnd: Date?
  var resolution: String
  var encoding: String
  @Published var error: String = ""
  @Published var completionPercentage: Float = 0.0
  init(
    sourceURL: URL,
    targetURL: URL,
    resolution: String,
    encoding: String
  ) {
    self.sourceURL = sourceURL
    self.targetURL = targetURL
    self.resolution = resolution
    self.encoding = encoding
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
