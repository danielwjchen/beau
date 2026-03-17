import Foundation
import os

extension Logger {
  private static var subsystem = Bundle.main.bundleIdentifier!

  public static let app = Logger(subsystem: subsystem, category: "App")
  public static let fileManager = Logger(subsystem: subsystem, category: "FileManager")
  public static let ui = Logger(subsystem: subsystem, category: "UI")
  public static let optimizable = Logger(subsystem: subsystem, category: "Optimizable")
}
