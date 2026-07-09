import SwiftUI
import BloomCore
import CoreImage
import CoreImage.CIFilterBuiltins

struct RecipeSharePanel: View {
    @Environment(ThemeStore.self) private var theme

    @State private var rawUrl = ""
    @State private var alias = ""
    @State private var qrImage: Image?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            TextField("Paste the recipe link", text: $rawUrl, prompt: Text("Paste the recipe link").foregroundColor(theme.color("muted")))
                .font(bloomBody(14))
                .foregroundStyle(theme.color("text"))
                .keyboardType(.URL)
                .autocorrectionDisabled()
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10).fill(theme.color("surface")))

            HStack {
                TextField("Name this QR (e.g. Blueberry_Muffins)", text: $alias, prompt: Text("Name this QR (e.g. Blueberry_Muffins)").foregroundColor(theme.color("muted")))
                    .font(bloomBody(13))
                    .foregroundStyle(theme.color("text"))
                Button("Make QR") {
                    generateQR()
                }
                .font(bloomBody(13, weight: .semibold))
                .foregroundStyle(theme.color("primaryStrong"))
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 10).fill(theme.color("surfaceSoft")))

            Text("A QR code works fully offline. Make one, then show it or save the image; scanning opens the recipe.")
                .font(bloomBody(11))
                .foregroundStyle(theme.color("muted"))

            if let qrImage {
                VStack(spacing: 10) {
                    qrImage
                        .interpolation(.none)
                        .resizable()
                        .frame(width: 200, height: 200)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    ShareLink(
                        item: qrImage,
                        preview: SharePreview(alias.isEmpty ? "Recipe QR" : alias, image: qrImage)
                    )
                    .font(bloomBody(13, weight: .medium))
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: theme.radius).fill(theme.color("surface")))
    }

    private func generateQR() {
        let cleaned = RecipeParse.cleanUrl(rawUrl)
        guard !cleaned.isEmpty else { return }
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(cleaned.utf8)
        filter.correctionLevel = "M"

        guard let outputImage = filter.outputImage else { return }
        let scale = 200.0 / outputImage.extent.width
        let scaled = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return }
        qrImage = Image(decorative: cgImage, scale: 1.0)
        theme.triggerCurtain()
    }
}
