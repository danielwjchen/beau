import SwiftUI

struct BeauNameAndSizeView: View {
  let name: String
  let size: CGSize?

  var body: some View {
    Text(name)
      .font(.headline)
    let sizeString = String(
      format: "%dx%d",
      Int(size?.width ?? 0),
      Int(size?.height ?? 0)
    )
    Text(sizeString)
      .font(.subheadline)
      .fontWeight(.light)
  }
}

#Preview {
  BeauNameAndSizeView(name: "foobar.mov", size: CGSize(width: 1920, height: 1080))
}
