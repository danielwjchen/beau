import AVFoundation

struct BeauTargetPreset: Identifiable, Hashable {
  var id: String { label }
  let videoPreset: String
  let label: String
  let width: CGFloat
  let height: CGFloat
  let encoding: String

  static let defaultValue: BeauTargetPreset = .init(
    videoPreset: AVAssetExportPreset1920x1080,
    label: "Full HD (1080p)",
    width: 1920,
    height: 1080,
    encoding: "avc"
  )

  static let all: [BeauTargetPreset] = [
    .init(
      videoPreset: AVAssetExportPreset3840x2160, label: "4K (2160p)", width: 3840, height: 2160,
      encoding: "avc"),
    defaultValue,
    .init(
      videoPreset: AVAssetExportPreset1280x720, label: "HD (720p)", width: 1280, height: 720,
      encoding: "avc"),
    .init(
      videoPreset: AVAssetExportPreset960x540, label: "qHD (540p)", width: 960, height: 540,
      encoding: "avc"),
    .init(
      videoPreset: AVAssetExportPreset640x480, label: "SD (480p)", width: 640, height: 480,
      encoding: "avc"),
    .init(
      videoPreset: AVAssetExportPresetLowQuality, label: "Low Quality (360p)", width: 480,
      height: 360, encoding: "avc"),
  ]

  func getResolution() -> String {
    return "\(self.width)x\(self.height)"
  }

  func setBeauItemsIsSelected(
    _ items: [any BeauOptimizable]
  ) {
    items.forEach({ item in
      if let width = item.sourceResolution?.width,
        let height = item.sourceResolution?.height
      {
        item.isSelected =
          ((width > self.width
            && height > self.height)
            || (height > self.width
              && width > self.height))
      } else {
        item.isSelected = false
      }
    })
  }
}
