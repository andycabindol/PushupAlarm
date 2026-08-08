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
    @Published var feedback = "Position yourself in front of camera"
    @Published var bodyDetected = false
    
    private var lastPhase: PushupPhase = .neutral
    private let downThreshold: CGFloat = 90.0
    private let upThreshold: CGFloat = 160.0
    private var isInValidPosition = false
    
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
                    self.feedback = "No body detected - step back"
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
        guard let leftShoulder = try? observation.recognizedPoint(.leftShoulder),
              let rightShoulder = try? observation.recognizedPoint(.rightShoulder),
              let leftElbow = try? observation.recognizedPoint(.leftElbow),
              let rightElbow = try? observation.recognizedPoint(.rightElbow),
              let leftWrist = try? observation.recognizedPoint(.leftWrist),
              let rightWrist = try? observation.recognizedPoint(.rightWrist),
              let leftHip = try? observation.recognizedPoint(.leftHip),
              let rightHip = try? observation.recognizedPoint(.rightHip)
        else {
            DispatchQueue.main.async {
                self.bodyDetected = false
                self.feedback = "Can't see full body"
            }
            return
        }
        
        let minConfidence: Float = 0.3
        guard leftShoulder.confidence > minConfidence,
              rightShoulder.confidence > minConfidence,
              leftElbow.confidence > minConfidence,
              rightElbow.confidence > minConfidence,
              leftWrist.confidence > minConfidence,
              rightWrist.confidence > minConfidence,
              leftHip.confidence > minConfidence,
              rightHip.confidence > minConfidence
        else {
            DispatchQueue.main.async {
                self.bodyDetected = false
                self.feedback = "Position entire body in frame"
            }
            return
        }
        
        DispatchQueue.main.async {
            self.bodyDetected = true
        }
        
        let leftElbowAngle = self.calculateAngle(
            point1: leftShoulder.location,
            point2: leftElbow.location,
            point3: leftWrist.location
        )
        
        let rightElbowAngle = self.calculateAngle(
            point1: rightShoulder.location,
            point2: rightElbow.location,
            point3: rightWrist.location
        )
        
        let averageElbowAngle = (leftElbowAngle + rightElbowAngle) / 2
        
        let shoulderMidY = (leftShoulder.location.y + rightShoulder.location.y) / 2
        let hipMidY = (leftHip.location.y + rightHip.location.y) / 2
        let bodyAlignment = abs(shoulderMidY - hipMidY)
        
        let isBodyStraight = bodyAlignment > 0.1
        
        let newPhase: PushupPhase
        var newFeedback = ""
        
        if averageElbowAngle < downThreshold && isBodyStraight {
            newPhase = .down
            newFeedback = "Down position ✓"
        } else if averageElbowAngle > upThreshold && isBodyStraight {
            newPhase = .up
            newFeedback = "Up position ✓"
        } else {
            newPhase = .neutral
            if !isBodyStraight {
                newFeedback = "Keep your body straight"
            } else if averageElbowAngle < upThreshold && averageElbowAngle > downThreshold {
                newFeedback = "Go lower or push up"
            } else {
                newFeedback = "Continue..."
            }
        }
        
        if lastPhase == .up && newPhase == .down {
            DispatchQueue.main.async {
                self.pushupCount += 1
                self.feedback = "Rep \(self.pushupCount) complete! 🔥"
            }
        } else {
            DispatchQueue.main.async {
                self.feedback = newFeedback
                self.currentPhase = newPhase
            }
        }
        
        lastPhase = newPhase
    }
    
    private func calculateAngle(point1: CGPoint, point2: CGPoint, point3: CGPoint) -> CGFloat {
        let vector1 = CGPoint(x: point1.x - point2.x, y: point1.y - point2.y)
        let vector2 = CGPoint(x: point3.x - point2.x, y: point3.y - point2.y)
        
        let dotProduct = vector1.x * vector2.x + vector1.y * vector2.y
        let magnitude1 = sqrt(vector1.x * vector1.x + vector1.y * vector1.y)
        let magnitude2 = sqrt(vector2.x * vector2.x + vector2.y * vector2.y)
        
        let cosineAngle = dotProduct / (magnitude1 * magnitude2)
        let angleRadians = acos(max(-1, min(1, cosineAngle)))
        let angleDegrees = angleRadians * 180 / .pi
        
        return angleDegrees
    }
    
    func reset() {
        pushupCount = 0
        currentPhase = .neutral
        lastPhase = .neutral
        feedback = "Position yourself in front of camera"
        bodyDetected = false
    }
}
