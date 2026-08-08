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
    
    private var lastPhase: PushupPhase = .neutral
    
    /// Elbow angle (degrees) below this counts as the bottom of a rep.
    /// Slightly forgiving so foreshortened floor-camera views still register.
    private let downThreshold: CGFloat = 110.0
    /// Elbow angle above this counts as the top of a rep.
    private let upThreshold: CGFloat = 150.0
    /// Soft band where head position can tip a borderline pose into up/down.
    private let borderlineDown: CGFloat = 130.0
    private let borderlineUp: CGFloat = 125.0
    private let minConfidence: Float = 0.25
    
    func processFrame(_ sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let request = VNDetectHumanBodyPoseRequest { [weak self] request, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Pose detection error: \(error)")
                return
            }
            
            guard let observations = request.results as? [VNHumanBodyPoseObservation],
                  let observation = observations.first else {
                DispatchQueue.main.async {
                    self.bodyDetected = false
                    self.feedback = "No one detected — face the camera"
                }
                return
            }
            
            self.analyzePose(observation)
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            print("Failed to perform pose detection: \(error)")
        }
    }
    
    private func analyzePose(_ observation: VNHumanBodyPoseObservation) {
        // Track upper body only: arms + head. Hips/legs are often hidden when
        // the phone is on the floor and the torso covers them.
        let nose = try? observation.recognizedPoint(.nose)
        let leftShoulder = try? observation.recognizedPoint(.leftShoulder)
        let rightShoulder = try? observation.recognizedPoint(.rightShoulder)
        let leftElbow = try? observation.recognizedPoint(.leftElbow)
        let rightElbow = try? observation.recognizedPoint(.rightElbow)
        let leftWrist = try? observation.recognizedPoint(.leftWrist)
        let rightWrist = try? observation.recognizedPoint(.rightWrist)
        
        let headVisible = pointVisible(nose)
        
        var armAngles: [CGFloat] = []
        if let angle = elbowAngle(shoulder: leftShoulder, elbow: leftElbow, wrist: leftWrist) {
            armAngles.append(angle)
        }
        if let angle = elbowAngle(shoulder: rightShoulder, elbow: rightElbow, wrist: rightWrist) {
            armAngles.append(angle)
        }
        
        guard !armAngles.isEmpty else {
            DispatchQueue.main.async {
                self.bodyDetected = false
                self.feedback = "Show your arms to the camera"
            }
            return
        }
        
        guard headVisible, let nose else {
            DispatchQueue.main.async {
                self.bodyDetected = false
                self.feedback = "Keep your head in frame"
            }
            return
        }
        
        DispatchQueue.main.async {
            self.bodyDetected = true
        }
        
        let averageElbowAngle = armAngles.reduce(0, +) / CGFloat(armAngles.count)
        let headIsLowered = isHeadLowered(
            nose: nose,
            leftShoulder: leftShoulder,
            rightShoulder: rightShoulder,
            leftWrist: leftWrist,
            rightWrist: rightWrist
        )
        
        let newPhase: PushupPhase
        var newFeedback = ""
        
        // Arms drive the phase; head proximity tips borderline floor-camera poses.
        if averageElbowAngle < downThreshold || (averageElbowAngle < borderlineDown && headIsLowered) {
            newPhase = .down
            newFeedback = "Down ✓ — now push up"
        } else if averageElbowAngle > upThreshold || (averageElbowAngle > borderlineUp && !headIsLowered) {
            newPhase = .up
            newFeedback = "Up ✓ — lower down"
        } else {
            newPhase = .neutral
            if headIsLowered {
                newFeedback = "Go a bit lower, then push up"
            } else {
                newFeedback = "Bend your elbows to go down"
            }
        }
        
        // Count a completed rep when rising from the bottom.
        if lastPhase == .down && newPhase == .up {
            DispatchQueue.main.async {
                self.pushupCount += 1
                self.currentPhase = newPhase
                self.feedback = "Rep \(self.pushupCount) complete!"
            }
        } else {
            DispatchQueue.main.async {
                self.feedback = newFeedback
                self.currentPhase = newPhase
            }
        }
        
        lastPhase = newPhase
    }
    
    /// True when the head has dropped toward the hands — reliable for a
    /// phone-on-the-floor view where elbows can look foreshortened.
    private func isHeadLowered(
        nose: VNRecognizedPoint,
        leftShoulder: VNRecognizedPoint?,
        rightShoulder: VNRecognizedPoint?,
        leftWrist: VNRecognizedPoint?,
        rightWrist: VNRecognizedPoint?
    ) -> Bool {
        let wrists = [leftWrist, rightWrist].compactMap { point -> CGPoint? in
            guard let point, point.confidence > minConfidence else { return nil }
            return point.location
        }
        
        if !wrists.isEmpty {
            let wristMid = averagePoint(wrists)
            let distance = hypot(nose.location.x - wristMid.x, nose.location.y - wristMid.y)
            // Nose near planted hands ⇒ bottom of the pushup.
            if distance < 0.28 {
                return true
            }
        }
        
        let shoulders = [leftShoulder, rightShoulder].compactMap { point -> CGPoint? in
            guard let point, point.confidence > minConfidence else { return nil }
            return point.location
        }
        
        guard !shoulders.isEmpty else { return false }
        
        let shoulderMid = averagePoint(shoulders)
        // Vision coords: Y increases upward. Head below the shoulder line ⇒ lowered.
        return nose.location.y < shoulderMid.y - 0.04
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
    
    private func pointVisible(_ point: VNRecognizedPoint?) -> Bool {
        guard let point else { return false }
        return point.confidence > minConfidence
    }
    
    private func averagePoint(_ points: [CGPoint]) -> CGPoint {
        let sum = points.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
        return CGPoint(x: sum.x / CGFloat(points.count), y: sum.y / CGFloat(points.count))
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
        lastPhase = .neutral
        feedback = "Place phone on the floor and face the camera"
        bodyDetected = false
    }
}
