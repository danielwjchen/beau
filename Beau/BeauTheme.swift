import SwiftUI

struct BeauTheme {

  let isActive: Bool
  let canRun: Bool
  let colorScheme: ColorScheme

  var textColor: Color {
    if isActive {
      return colorScheme == .dark ? .white : .gray
    }
    return colorScheme == .dark ? .white : canRun ? .white : .gray
  }

  var brandColor: Color {
    return colorScheme == .dark ? Color.brandDark : Color.brandLight
  }
}
private struct BeauThemeKey: EnvironmentKey {
  static let defaultValue: BeauTheme = BeauTheme(
    isActive: false, canRun: false, colorScheme: .dark)
}

extension EnvironmentValues {
  var beauTheme: BeauTheme {
    get { self[BeauThemeKey.self] }
    set { self[BeauThemeKey.self] = newValue }
  }
}
