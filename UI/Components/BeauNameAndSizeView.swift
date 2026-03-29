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
  let resolutionString: String
  let fileSizeString: String

  init(
    name: String,
    resolution: CGSize?,
    fileSize: Int64?
  ) {
    self.name = name
    self.resolutionString = String(
      format: "%dx%d",
      Int(resolution?.width ?? 0),
      Int(resolution?.height ?? 0)
    )
    self.fileSizeString = getFileSizeString(fileSize: fileSize)
  }

  var body: some View {
    VStack(alignment: .leading) {
      Text(name)
        .font(.headline)
        .multilineTextAlignment(.leading)
      Text(resolutionString)
        .font(.subheadline)
        .fontWeight(.light)
        .multilineTextAlignment(.leading)
      Text(fileSizeString)
        .font(.subheadline)
        .fontWeight(.light)
        .multilineTextAlignment(.leading)
    }
    .frame(
      minWidth: 100,
      maxWidth: 200,
      alignment: .leading
    )
  }
}

#Preview {
  BeauNameAndSizeView(
    name: "foobar.mov",
    resolution: CGSize(width: 1920, height: 1080),
    fileSize: 123456
  )
  .padding(10)
}
