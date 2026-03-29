import Foundation
import SwiftUI

class BeauSession: ObservableObject {
  var resolution: String
  var encoding: String
  var renamePattern: String
  var tempFileNamePattern: String
  var preservesMeta: Bool
  var sourceURL: URL?
  var targetURL: URL?
  var preservesFolders: Bool
  @Published var selectedIds: Set<UUID> = []
  @Published var items: [any BeauOptimizable] = []
  @Published var timeBegin: Date?
  @Published var timeEnd: Date?
  @Published var isReady: Bool = false
  @Published var isAccessing: Bool = false
  @Published var isDragging = false
  @Published var itemProgressPercentage: Float? = nil
  @Published public var itemProgressMessage: String = ""
  @Environment(\.colorScheme) var colorScheme

  var textColor: Color {
    if isRunning {
      return colorScheme == .dark ? .white : .gray
    }
    return colorScheme == .dark ? .white : canRun ? .white : .gray
  }

  var brandColor: Color {
    return colorScheme == .dark ? Color.brandDark : Color.brandLight
  }

  init(
    resolution: String,
    encoding: String,
    renamePattern: String = "",
    tempFileNamePattern: String = ".tmp",
    preservesMeta: Bool = true,
    sourceURL: URL? = nil,
    targetURL: URL? = nil,
    preservesFolders: Bool = true,
    items: [any BeauOptimizable] = [],
    timeBegin: Date? = nil,
    timeEnd: Date? = nil
  ) {
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

  init(from preset: BeauTargetPreset) {
    self.resolution = preset.getResolution()
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

  var isRunning: Bool {
    return timeBegin != nil && timeEnd == nil
  }

  var isDone: Bool {
    return timeBegin != nil && timeEnd != nil
  }

  var canRun: Bool {
    return isReady && !selectedIds.isEmpty && !isRunning
  }

  public func setPropertiesFromPreset(_ preset: BeauTargetPreset) {
    self.resolution = preset.getResolution()
    self.encoding = preset.encoding
  }

  public func setSelectedIds(
    _ preset: BeauTargetPreset
  ) {
    self.selectedIds.removeAll()
    self.items.forEach({ item in
      if item.processedOn != nil {
        return
      }
      if let width = item.sourceResolution?.width,
        let height = item.sourceResolution?.height
      {
        if (width > preset.width
          && height > preset.height)
          || (height > preset.width
            && width > preset.height)
          || type(of: item) == BeauPDFOptimizable.self
        {
          self.selectedIds.insert(item.id)
        }
      }
    })
  }

  public func cleanUpAccess() {
    if isAccessing {
      if let sourceURL = sourceURL {
        sourceURL.stopAccessingSecurityScopedResource()
      }
    }
  }

  public func readFiles(selectedTargetPreset: BeauTargetPreset, urls: [URL]) {
    itemProgressPercentage = nil
    itemProgressMessage = ""
    items = []
    selectedIds.removeAll()
    cleanUpAccess()
    if let sourceURL = urls.first {
      timeBegin = nil
      timeEnd = nil
      isAccessing = sourceURL.startAccessingSecurityScopedResource()
      self.sourceURL = sourceURL
      targetURL = sourceURL
      let fileURLs = getFileURLs(in: sourceURL)
      let targetResolution = CGSize(width: 1920, height: 1080)
      let targetEncoding = ""
      Task {
        items = await createBeauOptimizable(
          fileURLs, targetResolution, targetEncoding
        ) { progressPercentage, message in
          self.itemProgressPercentage = progressPercentage
          self.itemProgressMessage = message
        }
        setSelectedIds(selectedTargetPreset)
        isReady = items.count > 0
      }
    }
  }

  public func run() {
    timeBegin = Date()
    isReady = false
    Task {
      for i in items.indices {
        if !selectedIds.contains(items[i].id) {
          continue
        }
        await processBeauOptimizable(items[i], tempFileNamePattern)
      }
      timeEnd = Date()
      cleanUpAccess()
    }

  }
}
