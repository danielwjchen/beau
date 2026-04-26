import SwiftUI

class BeauSession: ObservableObject {
  var resolution: String
  var encoding: String
  var renamePattern: String
  var tempFileNamePattern: String
  var preservesMeta: Bool
  var accessedURLs: [URL] = []
  var preservesFolders: Bool
  @Published var selectedIds: Set<UUID> = []
  @Published var groups: [BeauOptimizableGroup] = []
  @Published var timeBegin: Date?
  @Published var timeEnd: Date?
  @Published var isReady: Bool = false
  @Published var isAccessing: Bool = false
  @Published var isDragging = false
  @Published var itemProgressPercentage: Float? = nil
  @Published var itemProgressMessage: String = ""
  @Published var selectedTargetPreset: BeauTargetPreset = .defaultValue
  @Published var isRunning: Bool = false
  @Environment(\.colorScheme) var colorScheme

  var textColor: Color {
    if isRunning || isDragging {
      return colorScheme == .dark ? .white : .gray
    }
    return colorScheme == .dark ? .white : canRun ? .white : .gray
  }

  var brandColor: Color {
    return colorScheme == .dark ? Color.brandDark : Color.brandLight
  }

  var itemCount: Int {
    return groups.reduce(0) { $0 + $1.items.count }
  }

  init(
    resolution: String,
    encoding: String,
    renamePattern: String = "",
    tempFileNamePattern: String = ".tmp",
    preservesMeta: Bool = true,
    preservesFolders: Bool = true,
    timeBegin: Date? = nil,
    timeEnd: Date? = nil
  ) {
    self.resolution = resolution
    self.encoding = encoding
    self.renamePattern = renamePattern
    self.tempFileNamePattern = tempFileNamePattern
    self.preservesMeta = preservesMeta
    self.preservesFolders = preservesFolders
    self.groups = []
    self.timeBegin = timeBegin
    self.timeEnd = timeEnd
  }

  init(from preset: BeauTargetPreset) {
    self.resolution = preset.getResolution()
    self.encoding = preset.encoding
    self.renamePattern = ""
    self.tempFileNamePattern = ".tmp"
    self.preservesMeta = true
    self.preservesFolders = true
    self.groups = []
    self.timeBegin = nil
    self.timeEnd = nil
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
    self.groups.forEach { group in
      group.items.forEach { item in
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
      }
    }
  }

  public func cleanUpAccess() {
    if isAccessing {
      for url in accessedURLs {
        url.stopAccessingSecurityScopedResource()
      }
      accessedURLs = []
      isAccessing = false
    }
  }

  public func readFiles(urls: [URL]) {
    itemProgressPercentage = nil
    itemProgressMessage = ""
    groups = []
    isRunning = true
    selectedIds.removeAll()
    cleanUpAccess()
    guard !urls.isEmpty else { return }

    timeBegin = nil
    timeEnd = nil

    var fileURLs: [URL] = []
    for url in urls {
      if url.startAccessingSecurityScopedResource() {
        accessedURLs.append(url)
        isAccessing = true
      }

      if url.hasDirectoryPath {
        fileURLs += getFileURLs(in: url)
      } else {
        fileURLs.append(url)
      }
    }

    let targetResolution = CGSize(width: 1920, height: 1080)
    let targetEncoding = ""
    Task {
      let items = await createBeauOptimizable(
        fileURLs, targetResolution, targetEncoding
      ) { progressPercentage, message in
        self.itemProgressPercentage = progressPercentage
        self.itemProgressMessage = message
      }
      self.groups = groupOptimizablesByFolder(items).map { folder, items in
        BeauOptimizableGroup(url: folder, items: items)
      }
      setSelectedIds(selectedTargetPreset)
      isReady = items.count > 0
      isRunning = false
    }
  }

  public func run() {
    timeBegin = Date()
    isReady = false
    isRunning = true
    Task {
      for g in groups.indices {
        for i in groups[g].items.indices {
          if !selectedIds.contains(groups[g].items[i].id) {
            continue
          }
          await processBeauOptimizable(groups[g].items[i], tempFileNamePattern)
        }
      }
      timeEnd = Date()
      cleanUpAccess()
      isRunning = false
    }
  }

  public func reset() {
    timeBegin = nil
    timeEnd = nil
    groups = []
    selectedIds.removeAll()
    isReady = false
    itemProgressPercentage = nil
    itemProgressMessage = ""
    isRunning = false
    cleanUpAccess()
  }
}
