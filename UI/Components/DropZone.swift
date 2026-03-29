import SwiftUI

struct DropZoneView: View {

  @ObservedObject var session: BeauSession
  @State private var isImporterPresented: Bool = false

  var body: some View {
    VStack(spacing: 16) {
      ZStack {
        RoundedRectangle(cornerRadius: 16)
          .fill(Color.brandLight.opacity(0.08))
          .frame(width: 72, height: 72)
        RoundedRectangle(cornerRadius: 16)
          .stroke(Color.brandLight.opacity(0.3), lineWidth: 1.5)
          .frame(width: 72, height: 72)
        Image(systemName: "arrow.up.doc.on.clipboard")
          .font(.system(size: 28, weight: .light))
          .foregroundColor(.brandLight)
      }

      VStack(spacing: 5) {
        Text("Drop files or folders here")
          .font(.system(size: 15, weight: .medium))
          .foregroundColor(.labelPrimary.opacity(0.75))
        Text("Supports PDF, PNG, JPG, HEIC, MP4, MOV")
          .font(.system(size: 13))
          .foregroundColor(.labelTertiary)
      }

      Button {
        session.isReady = false
        isImporterPresented = true
      } label: {
        Text("or click to select files")
          .font(.system(size: 12))
          .foregroundColor(.labelTertiary)
          .padding(.horizontal, 14)
          .padding(.vertical, 5)
          .background(Color.white.opacity(0.05))
          .clipShape(RoundedRectangle(cornerRadius: 6))
          .overlay(
            RoundedRectangle(cornerRadius: 6)
              .stroke(Color.white.opacity(0.08), lineWidth: 1)
          )
      }
      .buttonStyle(.plain)
      .fileImporter(
        isPresented: $isImporterPresented,
        allowedContentTypes: allowedContentTypes,
        allowsMultipleSelection: false
      ) { result in
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .stroke(
          session.isDragging ? Color.brandLight : Color.white.opacity(0.1),
          style: StrokeStyle(lineWidth: 2, dash: [6])
        )
        .background(
          RoundedRectangle(cornerRadius: 12)
            .fill(session.isDragging ? Color.brandLight.opacity(0.05) : Color.clear)
        )
        .padding(20)
    )
    .animation(.easeInOut(duration: 0.15), value: session.isDragging)
  }
}

#Preview {
  DropZoneView(session: BeauPreviewMocks.getSessionEmpty())
}
