import Foundation
import Vision
import CoreGraphics
import UIKit

enum FaceAnalyzerError: LocalizedError {
    case badImage
    case noFaceFound
    case faceTooSmall
    case landmarksMissing

    var errorDescription: String? {
        switch self {
        case .badImage: return "Couldn't read that photo. Try again."
        case .noFaceFound: return "No face detected. Face the camera straight on in good light."
        case .faceTooSmall: return "You're too far away. Bring the camera to about arm's length."
        case .landmarksMissing: return "Couldn't trace your jawline. Remove anything covering your jaw and try again."
        }
    }
}

/// On-device jawline analysis built on Vision's face-landmark detection.
/// Nothing is uploaded anywhere — the image is analyzed and discarded.
enum FaceAnalyzer {
    /// Runs Vision on a background thread and extracts jawline metrics.
    static func analyze(_ image: UIImage) async throws -> JawlineMetrics {
        guard let cgImage = image.normalizedUp.cgImage else { throw FaceAnalyzerError.badImage }
        return try await Task.detached(priority: .userInitiated) {
            try analyzeSync(cgImage: cgImage)
        }.value
    }

    private static func analyzeSync(cgImage: CGImage) throws -> JawlineMetrics {
        let request = VNDetectFaceLandmarksRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
        try handler.perform([request])

        let faces = request.results ?? []
        guard let face = faces.max(by: { $0.boundingBox.width < $1.boundingBox.width }) else {
            throw FaceAnalyzerError.noFaceFound
        }

        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        guard face.boundingBox.width * imageSize.width > 180 else {
            throw FaceAnalyzerError.faceTooSmall
        }
        guard let landmarks = face.landmarks,
              let contourRegion = landmarks.faceContour,
              let leftEyeRegion = landmarks.leftEye,
              let rightEyeRegion = landmarks.rightEye,
              let noseRegion = landmarks.nose else {
            throw FaceAnalyzerError.landmarksMissing
        }

        // Points come back in image coordinates, origin at the bottom-left,
        // so the chin is the contour point with the smallest y.
        let contour = contourRegion.pointsInImage(imageSize: imageSize)
        guard contour.count >= 11 else { throw FaceAnalyzerError.landmarksMissing }

        let earA = contour.first!
        let earB = contour.last!
        let chin = contour.min(by: { $0.y < $1.y })!

        // Approximate gonions (jaw corners) ~15% in from each contour end.
        let n = contour.count
        let gonA = contour[Int(round(Double(n - 1) * 0.15))]
        let gonB = contour[Int(round(Double(n - 1) * 0.85))]

        // Gonial-angle proxy: angle at the jaw corner between the ramus
        // (toward the ear) and the jaw body (toward the chin), both sides.
        let angleA = angle(at: gonA, toward: earA, and: chin)
        let angleB = angle(at: gonB, toward: earB, and: chin)
        let gonialAngle = (angleA + angleB) / 2

        let faceWidth = max(distance(earA, earB), .ulpOfOne)
        let jawWidth = distance(gonA, gonB)

        // Vertical proportions off the eye line and nose base.
        let leftEyeCenter = centroid(leftEyeRegion.pointsInImage(imageSize: imageSize))
        let rightEyeCenter = centroid(rightEyeRegion.pointsInImage(imageSize: imageSize))
        let eyeLineY = (leftEyeCenter.y + rightEyeCenter.y) / 2
        let noseBaseY = noseRegion.pointsInImage(imageSize: imageSize).map(\.y).min() ?? eyeLineY
        let eyesToChin = max(eyeLineY - chin.y, .ulpOfOne)
        let lowerFaceRatio = max(0, (noseBaseY - chin.y) / eyesToChin)

        // Symmetry: jaw corners equidistant from the midline, chin on it.
        let midX = (leftEyeCenter.x + rightEyeCenter.x) / 2
        let dA = abs(gonA.x - midX)
        let dB = abs(gonB.x - midX)
        let cornerBalance = 1 - abs(dA - dB) / max(dA, dB, .ulpOfOne)
        let chinCentering = 1 - min(1, abs(chin.x - midX) / (faceWidth / 2))
        let symmetry = min(1, max(0, cornerBalance * 0.6 + chinCentering * 0.4))

        return JawlineMetrics(
            gonialAngle: gonialAngle,
            jawToFaceWidthRatio: jawWidth / faceWidth,
            lowerFaceRatio: lowerFaceRatio,
            symmetry: symmetry
        )
    }

    // MARK: - Geometry helpers

    private static func distance(_ a: CGPoint, _ b: CGPoint) -> Double {
        Double(hypot(a.x - b.x, a.y - b.y))
    }

    private static func centroid(_ points: [CGPoint]) -> CGPoint {
        guard !points.isEmpty else { return .zero }
        let sum = points.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
        return CGPoint(x: sum.x / CGFloat(points.count), y: sum.y / CGFloat(points.count))
    }

    /// Angle in degrees at `vertex` between rays toward `p1` and `p2`.
    private static func angle(at vertex: CGPoint, toward p1: CGPoint, and p2: CGPoint) -> Double {
        let v1 = CGVector(dx: p1.x - vertex.x, dy: p1.y - vertex.y)
        let v2 = CGVector(dx: p2.x - vertex.x, dy: p2.y - vertex.y)
        let dot = Double(v1.dx * v2.dx + v1.dy * v2.dy)
        let mag = Double(hypot(v1.dx, v1.dy) * hypot(v2.dx, v2.dy))
        guard mag > 0 else { return 0 }
        let cosine = min(1, max(-1, dot / mag))
        return acos(cosine) * 180 / .pi
    }
}

extension UIImage {
    /// Redraws the image so its pixel data matches `.up` orientation —
    /// simplest way to hand Vision correctly-oriented pixels.
    var normalizedUp: UIImage {
        guard imageOrientation != .up else { return self }
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
