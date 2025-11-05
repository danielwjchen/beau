import SwiftUI

func getFileSizeString(fileSize: Int64?) -> String {
  guard let fileSize = fileSize else {
    return "N/A"
  }
  let formatter = ByteCountFormatter()
  formatter.allowedUnits = [.useKB, .useMB, .useGB]
  formatter.countStyle = .file
  return formatter.string(fromByteCount: fileSize)
}

struct BeauNameAndSizeView: View {
  let name: String
  let resolution: CGSize?
  let fileSize: Int64?

  var body: some View {
    let resolutionString = String(
      format: "%dx%d",
      Int(resolution?.width ?? 0),
      Int(resolution?.height ?? 0)
    )
    let fileSizeString = getFileSizeString(fileSize: fileSize)
    VStack(alignment: .leading) {
      Text(name)
        .font(.headline)
      Text(resolutionString)
        .font(.subheadline)
        .fontWeight(.light)
      Text(fileSizeString)
        .font(.subheadline)
        .fontWeight(.light)

    }
  }
}

#Preview {
  BeauNameAndSizeView(
    name: "foobar.mov",
    resolution: CGSize(width: 1920, height: 1080),
    fileSize: 123456
  )
}
