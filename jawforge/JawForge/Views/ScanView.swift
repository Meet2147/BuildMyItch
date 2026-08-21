import SwiftUI
import PhotosUI
import AVFoundation

/// Wraps the analyzed metrics so navigationDestination(item:) can present them.
struct AnalysisResult: Identifiable, Hashable {
    let id = UUID()
    let metrics: JawlineMetrics
}

struct ScanView: View {
    @Environment(ScanStore.self) private var store
    @StateObject private var camera = CameraService()
    @State private var isAnalyzing = false
    @State private var result: AnalysisResult?
    @State private var errorMessage: String?
    @State private var photoItem: PhotosPickerItem?
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                content
                if isAnalyzing { analyzingOverlay }
            }
            .navigationTitle("Scan")
            .toolbarBackground(Theme.background, for: .navigationBar)
            .navigationDestination(item: $result) { result in
                ResultsView(metrics: result.metrics)
            }
        }
        .task { await camera.start() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await camera.start() } } else { camera.stop() }
        }
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task { await analyzePickedPhoto(item) }
        }
        .alert("Scan failed", isPresented: .init(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    @ViewBuilder
    private var content: some View {
        VStack(spacing: 16) {
            ZStack {
                cameraArea
                FaceGuideOverlay()
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(3.0 / 4.0, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .padding(.horizontal)

            VStack(spacing: 6) {
                Label("Face the camera straight on, hair off the jaw", systemImage: "person.crop.circle")
                Label("Neutral expression, teeth gently closed", systemImage: "face.dashed")
                Label("Even light, camera at eye level", systemImage: "sun.max")
            }
            .font(.caption)
            .foregroundStyle(Theme.textSecondary)

            Spacer(minLength: 0)

            HStack(spacing: 16) {
                PhotosPicker(selection: $photoItem, matching: .images) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.title2)
                        .frame(width: 56, height: 56)
                        .background(Theme.surface, in: Circle())
                }

                Button {
                    Task { await captureAndAnalyze() }
                } label: {
                    ZStack {
                        Circle().stroke(Theme.accentGradient, lineWidth: 4).frame(width: 84, height: 84)
                        Circle().fill(Theme.accentGradient).frame(width: 68, height: 68)
                    }
                }
                .disabled(camera.status != .running || isAnalyzing)
                .opacity(camera.status == .running ? 1 : 0.4)

                // Balances the photo-picker button so the shutter stays centered.
                Color.clear.frame(width: 56, height: 56)
            }
            .padding(.bottom, 12)
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private var cameraArea: some View {
        switch camera.status {
        case .running:
            CameraPreview(session: camera.session)
        case .denied:
            placeholder(
                icon: "video.slash",
                text: "Camera access is off. Enable it in Settings → JawForge, or analyze a photo from your library below."
            )
        case .unavailable:
            placeholder(
                icon: "camera",
                text: "No front camera available (Simulator?). Pick a selfie from the photo library below instead."
            )
        case .idle:
            placeholder(icon: "camera", text: "Starting camera…")
        }
    }

    private func placeholder(icon: String, text: String) -> some View {
        ZStack {
            Theme.surface
            VStack(spacing: 12) {
                Image(systemName: icon).font(.largeTitle).foregroundStyle(Theme.textSecondary)
                Text(text)
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
    }

    private var analyzingOverlay: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()
            VStack(spacing: 16) {
                SwiftUI.ProgressView()
                    .controlSize(.large)
                    .tint(Theme.accent)
                Text("Tracing your jawline…")
                    .font(.headline)
                Text("Analysis runs entirely on this device")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    // MARK: - Actions

    private func captureAndAnalyze() async {
        isAnalyzing = true
        defer { isAnalyzing = false }
        do {
            let photo = try await camera.capturePhoto()
            let metrics = try await FaceAnalyzer.analyze(photo)
            result = AnalysisResult(metrics: metrics)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func analyzePickedPhoto(_ item: PhotosPickerItem) async {
        isAnalyzing = true
        defer {
            isAnalyzing = false
            photoItem = nil
        }
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                errorMessage = FaceAnalyzerError.badImage.localizedDescription
                return
            }
            let metrics = try await FaceAnalyzer.analyze(image)
            result = AnalysisResult(metrics: metrics)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

/// Live front-camera preview.
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    final class PreviewView: UIView {
        override static var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}
}

/// Dashed oval + jaw arc that helps the user center their face.
struct FaceGuideOverlay: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let ovalWidth = w * 0.62
            let ovalHeight = h * 0.66
            ZStack {
                Ellipse()
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                    .foregroundStyle(Theme.accent.opacity(0.8))
                    .frame(width: ovalWidth, height: ovalHeight)
                    .position(x: w / 2, y: h * 0.46)

                // Emphasize the jaw region — the part we actually measure.
                JawArc()
                    .stroke(Theme.accent, lineWidth: 3)
                    .frame(width: ovalWidth, height: ovalHeight)
                    .position(x: w / 2, y: h * 0.46)
            }
        }
        .allowsHitTesting(false)
    }
}

/// Bottom third of an ellipse — the jawline portion of the face guide.
struct JawArc: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: 1, // replaced by the ellipse transform below
            startAngle: .degrees(35),
            endAngle: .degrees(145),
            clockwise: false
        )
        let transform = CGAffineTransform(translationX: rect.midX, y: rect.midY)
            .scaledBy(x: rect.width / 2, y: rect.height / 2)
            .translatedBy(x: -rect.midX, y: -rect.midY)
        return path.applying(transform)
    }
}

#Preview {
    ScanView()
        .environment(ScanStore())
        .preferredColorScheme(.dark)
}
