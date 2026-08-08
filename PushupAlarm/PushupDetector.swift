import Vision
import AVFoundation
import UIKit

class PushupDetector: ObservableObject {
    enum PushupPhase {
        case neutral
        case down
        case up
    }
    
    @Published var pushupCount = 0
    @Published var currentPhase: PushupPhase = .neutral
    @Published var feedback = "Place phone on the floor and face the camera"
    @Published var bodyDetected = false
    
    /// Remembers that the bottom of a rep was reached, even if frames
    /// briefly go through neutral or Vision loses the pose at the floor.
    private var hasReachedBottom = false
    private var consecutiveMisses = 0
    private var smoothedDepth: CGFloat?
    
    /// Depth 0 = arms extended / up, 1 = chest near floor / down.
    private let downEnter: CGFloat = 0.52
    private let upEnter: CGFloat = 0.32
    private let minConfidence: Float = 0.15
    /// Hold the last good pose through short dropouts (~0.5s at 30fps).
    private let maxMissesToHold = 18
    private let depthSmoothing: CGFloat = 0.35
    
    func processFrame(_ sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let request = VNDetectHumanBodyPoseRequest { [weak self] request, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Pose detection error: \(error)")
                self.handleMiss(reason: "Pose error — keep facing the camera")
                return
            }
            
            guard let observations = request.results as? [VNHumanBodyPoseObservation],
                  let observation = observations.first else {
                self.handleMiss(reason: "No one detected — face the camera")
                return
            }
            
            self.analyzePose(observation)
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            print("Failed to perform pose detection: \(error)")
            handleMiss(reason: "Camera hiccup — hold position")
        }
    }
    
    private func analyzePose(_ observation: VNHumanBodyPoseObservation) {
        let nose = try? observation.recognizedPoint(.nose)
        let neck = try? observation.recognizedPoint(.neck)
        let leftShoulder = try? observation.recognizedPoint(.leftShoulder)
        let rightShoulder = try? observation.recognizedPoint(.rightShoulder)
        let leftElbow = try? observation.recognizedPoint(.leftElbow)
        let rightElbow = try? observation.recognizedPoint(.rightElbow)
        let leftWrist = try? observation.recognizedPoint(.leftWrist)
        let rightWrist = try? observation.recognizedPoint(.rightWrist)
        
        let depthSignals = depthSignals(
            nose: nose,
            neck: neck,
            leftShoulder: leftShoulder,
            rightShoulder: rightShoulder,
            leftElbow: leftElbow,
            rightElbow: rightElbow,
            leftWrist: leftWrist,
            rightWrist: rightWrist
        )
        
        guard !depthSignals.isEmpty else {
            // At the bottom, landmarks often vanish when the chest fills the
            // frame. Keep treating that as "still down" instead of failing.
            handleMiss(reason: "Move back a little so arms stay visible")
            return
        }
        
        consecutiveMisses = 0
        
        let rawDepth = depthSignals.reduce(0, +) / CGFloat(depthSignals.count)
        let depth: CGFloat
        if let smoothedDepth {
            depth = smoothedDepth + (rawDepth - smoothedDepth) * depthSmoothing
        } else {
            depth = rawDepth
        }
        smoothedDepth = depth
        
        let newPhase: PushupPhase
        var newFeedback: String
        var didCount = false
        
        if depth >= downEnter {
            newPhase = .down
            hasReachedBottom = true
            newFeedback = "Down ✓ — now push up"
        } else if depth <= upEnter {
            newPhase = .up
            if hasReachedBottom {
                hasReachedBottom = false
                didCount = true
                newFeedback = "Rep \(pushupCount + 1) complete!"
            } else {
                newFeedback = "Up ✓ — lower your chest"
            }
        } else {
            // Mid-rep: keep hasReachedBottom so down → neutral → up still counts.
            newPhase = .neutral
            if hasReachedBottom {
                newFeedback = "Push all the way up"
            } else {
                newFeedback = "Lower your chest toward the floor"
            }
        }
        
        DispatchQueue.main.async {
            self.bodyDetected = true
            self.currentPhase = newPhase
            if didCount {
                self.pushupCount += 1
            }
            self.feedback = didCount ? "Rep \(self.pushupCount) complete!" : newFeedback
        }
    }
    
    /// Builds 0...1 depth cues from arms/head. Missing joints are skipped,
    /// so a partial view (one arm, or shoulders only) can still work.
    private func depthSignals(
        nose: VNRecognizedPoint?,
        neck: VNRecognizedPoint?,
        leftShoulder: VNRecognizedPoint?,
        rightShoulder: VNRecognizedPoint?,
        leftElbow: VNRecognizedPoint?,
        rightElbow: VNRecognizedPoint?,
        leftWrist: VNRecognizedPoint?,
        rightWrist: VNRecognizedPoint?
    ) -> [CGFloat] {
        var signals: [CGFloat] = []
        
        let shoulderPoints = visiblePoints([leftShoulder, rightShoulder])
        let wristPoints = visiblePoints([leftWrist, rightWrist])
        let elbowAngles = [
            elbowAngle(shoulder: leftShoulder, elbow: leftElbow, wrist: leftWrist),
            elbowAngle(shoulder: rightShoulder, elbow: rightElbow, wrist: rightWrist)
        ].compactMap { $0 }
        
        // 1) Elbow flexion — primary when the full arm is visible.
        if !elbowAngles.isEmpty {
            let avg = elbowAngles.reduce(0, +) / CGFloat(elbowAngles.count)
            // ~170° => up (0), ~80° => down (1)
            signals.append(clamped((165 - avg) / 85))
        }
        
        // 2) Shoulder-to-wrist proximity — strong for floor-camera pushups.
        if let shoulderMid = midpoint(of: shoulderPoints),
           let wristMid = midpoint(of: wristPoints) {
            let span = hypot(shoulderMid.x - wristMid.x, shoulderMid.y - wristMid.y)
            let scale: CGFloat
            if shoulderPoints.count == 2 {
                scale = max(hypot(shoulderPoints[0].x - shoulderPoints[1].x,
                                  shoulderPoints[0].y - shoulderPoints[1].y), 0.08)
            } else {
                scale = 0.18
            }
            let ratio = span / scale
            // Extended plank ~2.2+, chest-down ~0.9
            signals.append(clamped((2.1 - ratio) / 1.2))
        }
        
        // 3) Head/neck near hands — useful until the face fills the lens.
        let headPoint = visibleLocation(nose) ?? visibleLocation(neck)
        if let headPoint, let wristMid = midpoint(of: wristPoints) {
            let distance = hypot(headPoint.x - wristMid.x, headPoint.y - wristMid.y)
            signals.append(clamped((0.42 - distance) / 0.28))
        }
        
        // 4) Shoulders alone vs prior depth: if we already started a rep and
        // only shoulders remain, bias toward "down" rather than dropping out.
        if signals.isEmpty, !shoulderPoints.isEmpty, hasReachedBottom {
            signals.append(0.7)
        }
        
        return signals
    }
    
    /// Vision often blanks at the bottom; hold pose briefly so the rep can finish.
    private func handleMiss(reason: String) {
        consecutiveMisses += 1
        
        if hasReachedBottom && consecutiveMisses <= maxMissesToHold {
            DispatchQueue.main.async {
                self.bodyDetected = true
                self.currentPhase = .down
                self.feedback = "Down ✓ — now push up"
            }
            return
        }
        
        if consecutiveMisses > maxMissesToHold {
            smoothedDepth = nil
        }
        
        DispatchQueue.main.async {
            self.bodyDetected = false
            self.feedback = reason
        }
    }
    
    private func elbowAngle(
        shoulder: VNRecognizedPoint?,
        elbow: VNRecognizedPoint?,
        wrist: VNRecognizedPoint?
    ) -> CGFloat? {
        guard let shoulder, let elbow, let wrist,
              shoulder.confidence > minConfidence,
              elbow.confidence > minConfidence,
              wrist.confidence > minConfidence
        else {
            return nil
        }
        
        return calculateAngle(
            point1: shoulder.location,
            point2: elbow.location,
            point3: wrist.location
        )
    }
    
    private func visiblePoints(_ points: [VNRecognizedPoint?]) -> [CGPoint] {
        points.compactMap { visibleLocation($0) }
    }
    
    private func visibleLocation(_ point: VNRecognizedPoint?) -> CGPoint? {
        guard let point, point.confidence > minConfidence else { return nil }
        return point.location
    }
    
    private func midpoint(of points: [CGPoint]) -> CGPoint? {
        guard !points.isEmpty else { return nil }
        let sum = points.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
        return CGPoint(x: sum.x / CGFloat(points.count), y: sum.y / CGFloat(points.count))
    }
    
    private func clamped(_ value: CGFloat) -> CGFloat {
        min(1, max(0, value))
    }
    
    private func calculateAngle(point1: CGPoint, point2: CGPoint, point3: CGPoint) -> CGFloat {
        let vector1 = CGPoint(x: point1.x - point2.x, y: point1.y - point2.y)
        let vector2 = CGPoint(x: point3.x - point2.x, y: point3.y - point2.y)
        
        let dotProduct = vector1.x * vector2.x + vector1.y * vector2.y
        let magnitude1 = sqrt(vector1.x * vector1.x + vector1.y * vector1.y)
        let magnitude2 = sqrt(vector2.x * vector2.x + vector2.y * vector2.y)
        
        guard magnitude1 > 0, magnitude2 > 0 else { return 180 }
        
        let cosineAngle = dotProduct / (magnitude1 * magnitude2)
        let angleRadians = acos(max(-1, min(1, cosineAngle)))
        return angleRadians * 180 / .pi
    }
    
    func reset() {
        pushupCount = 0
        currentPhase = .neutral
        hasReachedBottom = false
        consecutiveMisses = 0
        smoothedDepth = nil
        feedback = "Place phone on the floor and face the camera"
        bodyDetected = false
    }
}
