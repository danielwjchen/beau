//
//  Models.swift
//  Beau
//
//  Created by Daniel Chen on 10/20/25.
//
import Foundation

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
  @Published var items: [any BeauMediaOptimizable] = []
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
    items: [any BeauMediaOptimizable] = [],
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

  init(from preset: TargetPreset) {
    self.isInPlace = true
    self.resolution = getResolutionFromTargetPreset(preset)
    self.encoding = preset.encoding
    self.renamePattern = ""
    self.tempFileNamePattern = ".tmp"
    self.preservesMeta = true
    self.sourceURL = nil
    self.targetURL = nil
    self.preservesFolders = true
    self.items = []
    self.timeBegin = nil
    self.timeEnd = nil
  }

  public func setPropertiesFromPreset(_ preset: TargetPreset) {
    self.resolution = "\(preset.width)x\(preset.height)"
    self.encoding = preset.encoding
  }
}
