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
    @Environment(Entitlements.self) private var entitlements
    @StateObject private var camera = CameraService()
    @State private var isAnalyzing = false
    @State private var result: AnalysisResult?
    @State private var errorMessage: String?
    @State private var photoItem: PhotosPickerItem?
    @State private var showPaywall = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                content
                if isAnalyzing { AnalyzingOverlay() }
            }
            .navigationTitle("Scan")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !entitlements.isPro {
                        Button {
                            showPaywall = true
                        } label: {
                            Label("PRO", systemImage: "crown.fill")
                                .font(.caption.bold())
                                .foregroundStyle(Theme.accent)
                        }
                    }
                }
            }
            .navigationDestination(item: $result) { result in
                ResultsView(metrics: result.metrics)
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
        .tint(Theme.accent)
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

    /// Free tier: `Entitlements.freeScansPerWeek` saved scans per rolling week.
    private var scanQuotaAvailable: Bool {
        entitlements.isPro || store.scansInLast7Days < Entitlements.freeScansPerWeek
    }

    @ViewBuilder
    private var content: some View {
        VStack(spacing: 14) {
            ZStack {
                cameraArea
                ScanningOverlay(active: camera.status == .running)
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(3.0 / 4.0, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .padding(6)
            .neuRaised(cornerRadius: 30)
            .padding(.horizontal)

            VStack(spacing: 5) {
                Label("Face the camera straight on, hair off the jaw", systemImage: "person.crop.circle")
                Label("Neutral expression, teeth gently closed", systemImage: "face.dashed")
                Label("Even light, camera at eye level", systemImage: "sun.max")
            }
            .font(.caption)
            .foregroundStyle(Theme.textSecondary)

            Spacer(minLength: 0)

            HStack(spacing: 18) {
                PhotosPicker(selection: $photoItem, matching: .images) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.title3)
                        .foregroundStyle(Theme.ink)
                        .frame(width: 54, height: 54)
                }
                .buttonStyle(NeuButtonStyle(cornerRadius: 27))

                Button {
                    guard scanQuotaAvailable else {
                        showPaywall = true
                        return
                    }
                    Task { await captureAndAnalyze() }
                } label: {
                    ZStack {
                        Circle().fill(Theme.surface)
                            .shadow(color: Theme.shadowDark.opacity(0.5), radius: 8, x: 6, y: 6)
                            .shadow(color: Theme.shadowLight.opacity(0.9), radius: 8, x: -6, y: -6)
                            .frame(width: 84, height: 84)
                        Circle().fill(Theme.accentGradient).frame(width: 64, height: 64)
                            .shadow(color: Theme.accent.opacity(0.45), radius: 8, y: 4)
                        Image(systemName: "faceid")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)
                .disabled(camera.status != .running || isAnalyzing)
                .opacity(camera.status == .running ? 1 : 0.5)

                // Balances the photo-picker button so the shutter stays centered.
                Color.clear.frame(width: 54, height: 54)
            }
            .padding(.bottom, 8)

            if !entitlements.isPro {
                Text(scanQuotaAvailable
                     ? "Free plan: \(Entitlements.freeScansPerWeek) scan per week"
                     : "Weekly free scan used — Pro unlocks unlimited scans")
                    .font(.caption2)
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.bottom, 4)
            }
        }
        .padding(.top, 4)
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
            Color(red: 0.82, green: 0.85, blue: 0.90)
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

    // MARK: - Actions

    private func captureAndAnalyze() async {
        isAnalyzing = true
        defer { isAnalyzing = false }
        do {
            let photo = try await camera.capturePhoto()
            let metrics = try await analyzeWithMinimumDelay(photo)
            result = AnalysisResult(metrics: metrics)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Runs Vision, but lets the staged overlay play for at least ~2.2s —
    /// instant results read as fake even when they're real.
    private func analyzeWithMinimumDelay(_ image: UIImage) async throws -> JawlineMetrics {
        let start = Date()
        let metrics = try await FaceAnalyzer.analyze(image)
        let remaining = 2.2 - Date().timeIntervalSince(start)
        if remaining > 0 {
            try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
        }
        return metrics
    }

    private func analyzePickedPhoto(_ item: PhotosPickerItem) async {
        guard scanQuotaAvailable else {
            photoItem = nil
            showPaywall = true
            return
        }
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
            let metrics = try await analyzeWithMinimumDelay(image)
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

/// Animated scan chrome over the camera: pulsing face guide, corner
/// brackets, and a sweeping scan line with a soft glow.
struct ScanningOverlay: View {
    var active: Bool
    @State private var sweep = false
    @State private var pulse = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let ovalWidth = w * 0.62
            let ovalHeight = h * 0.66
            let ovalCenter = CGPoint(x: w / 2, y: h * 0.46)

            ZStack {
                // Face guide
                Ellipse()
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                    .foregroundStyle(Color.white.opacity(pulse ? 0.9 : 0.55))
                    .frame(width: ovalWidth, height: ovalHeight)
                    .scaleEffect(pulse ? 1.015 : 1)
                    .position(ovalCenter)

                // Jaw arc — the region we actually measure
                JawArc()
                    .stroke(Theme.accent, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                    .frame(width: ovalWidth, height: ovalHeight)
                    .position(ovalCenter)
                    .shadow(color: Theme.accent.opacity(0.8), radius: 6)

                // Corner brackets
                CornerBrackets()
                    .stroke(Color.white.opacity(0.85), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .padding(18)

                // Sweeping scan line
                if active {
                    LinearGradient(
                        colors: [Theme.accent.opacity(0), Theme.accent.opacity(0.35), Theme.accent.opacity(0)],
                        startPoint: .top, endPoint: .bottom
                    )
                    .frame(height: 90)
                    .overlay(Rectangle().fill(Theme.accent.opacity(0.9)).frame(height: 1.5))
                    .position(x: w / 2,
                              y: ovalCenter.y + (sweep ? ovalHeight / 2 : -ovalHeight / 2))
                    .allowsHitTesting(false)
                }
            }
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                    sweep = true
                }
                withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
        }
        .allowsHitTesting(false)
    }
}

/// Full-screen staged progress shown while Vision works.
struct AnalyzingOverlay: View {
    private static let stages = [
        "Detecting your face…",
        "Tracing 60+ landmarks…",
        "Measuring jaw angles…",
        "Scoring your jawline…",
    ]
    @State private var stage = 0
    @State private var ringSpin = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Theme.background.opacity(0.96).ignoresSafeArea()
            VStack(spacing: 22) {
                ZStack {
                    Circle()
                        .fill(Theme.surface)
                        .frame(width: 110, height: 110)
                        .shadow(color: Theme.shadowDark.opacity(0.5), radius: 10, x: 7, y: 7)
                        .shadow(color: Theme.shadowLight.opacity(0.9), radius: 10, x: -7, y: -7)
                    Circle()
                        .trim(from: 0, to: 0.72)
                        .stroke(Theme.accentGradient, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 82, height: 82)
                        .rotationEffect(.degrees(ringSpin ? 360 : 0))
                    Image(systemName: "faceid")
                        .font(.title)
                        .foregroundStyle(Theme.accent)
                }

                VStack(spacing: 8) {
                    Text(Self.stages[stage])
                        .font(.headline)
                        .foregroundStyle(Theme.ink)
                        .contentTransition(.opacity)
                        .animation(.easeInOut(duration: 0.3), value: stage)
                    Text("Analysis runs entirely on this device")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }

                // Stage dots
                HStack(spacing: 8) {
                    ForEach(0..<Self.stages.count, id: \.self) { i in
                        Circle()
                            .fill(i <= stage ? AnyShapeStyle(Theme.accentGradient) : AnyShapeStyle(Theme.shadowDark.opacity(0.4)))
                            .frame(width: 8, height: 8)
                    }
                }
            }
        }
        .onAppear {
            if !reduceMotion {
                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    ringSpin = true
                }
            }
        }
        .task {
            for i in 1..<Self.stages.count {
                try? await Task.sleep(nanoseconds: 550_000_000)
                stage = i
            }
        }
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

/// Four L-shaped viewfinder brackets.
struct CornerBrackets: Shape {
    func path(in rect: CGRect) -> Path {
        let len: CGFloat = 26
        var p = Path()
        // Top-left
        p.move(to: CGPoint(x: rect.minX, y: rect.minY + len))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX + len, y: rect.minY))
        // Top-right
        p.move(to: CGPoint(x: rect.maxX - len, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + len))
        // Bottom-right
        p.move(to: CGPoint(x: rect.maxX, y: rect.maxY - len))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX - len, y: rect.maxY))
        // Bottom-left
        p.move(to: CGPoint(x: rect.minX + len, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - len))
        return p
    }
}

#Preview {
    ScanView()
        .environment(ScanStore())
        .environment(Entitlements())
}
