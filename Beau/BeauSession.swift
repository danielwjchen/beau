import Foundation

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

  public func setPropertiesFromPreset(_ preset: BeauTargetPreset) {
    self.resolution = preset.getResolution()
    self.encoding = preset.encoding
  }

  public func setSelectedIds(
    _ preset: BeauTargetPreset
  ) {
    self.selectedIds.removeAll()
    self.items.forEach({ item in
      if let width = item.sourceResolution?.width,
        let height = item.sourceResolution?.height
      {
        if (width > preset.width
          && height > preset.height)
          || (height > preset.width
            && width > preset.height)
        {
          self.selectedIds.insert(item.id)
        }
      }
    })
  }
}
