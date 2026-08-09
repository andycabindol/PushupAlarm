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
    @Published var headPosition: CGFloat = 0.5
    
    private var hasReachedBottom = false
    private var consecutiveMisses = 0
    private var smoothedHeadY: CGFloat?
    
    private let targetLineY: CGFloat = 0.65
    private let downThreshold: CGFloat = 0.05
    private let upThreshold: CGFloat = 0.10
    private let minConfidence: Float = 0.2
    private let maxMissesToHold = 15
    private let smoothing: CGFloat = 0.3
    
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
        
        guard let nosePoint = nose, nosePoint.confidence > minConfidence else {
            handleMiss(reason: "Face the camera so we can see your head")
            return
        }
        
        consecutiveMisses = 0
        
        let rawHeadY = nosePoint.location.y
        
        let headY: CGFloat
        if let smoothedHeadY {
            headY = smoothedHeadY + (rawHeadY - smoothedHeadY) * smoothing
        } else {
            headY = rawHeadY
        }
        smoothedHeadY = headY
        
        let distanceFromLine = targetLineY - headY
        
        let isDown = distanceFromLine <= -downThreshold
        let isUp = distanceFromLine >= upThreshold
        
        let newPhase: PushupPhase
        var newFeedback: String
        var didCount = false
        
        if isDown {
            newPhase = .down
            hasReachedBottom = true
            newFeedback = "Down ✓ — now push up"
        } else if isUp {
            newPhase = .up
            if hasReachedBottom {
                hasReachedBottom = false
                didCount = true
                newFeedback = "Rep \(pushupCount + 1) complete!"
            } else {
                newFeedback = "Start position — lower your head below the line"
            }
        } else {
            newPhase = .neutral
            if hasReachedBottom {
                newFeedback = "Push up past the line"
            } else {
                newFeedback = "Dip your head below the red line"
            }
        }
        
        DispatchQueue.main.async {
            self.bodyDetected = true
            self.headPosition = headY
            self.currentPhase = newPhase
            if didCount {
                self.pushupCount += 1
            }
            self.feedback = didCount ? "Rep \(self.pushupCount) complete!" : newFeedback
        }
    }
    
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
            smoothedHeadY = nil
        }
        
        DispatchQueue.main.async {
            self.bodyDetected = false
            self.feedback = reason
        }
    }
    
    func reset() {
        pushupCount = 0
        currentPhase = .neutral
        hasReachedBottom = false
        consecutiveMisses = 0
        smoothedHeadY = nil
        headPosition = 0.5
        feedback = "Place phone on the floor and face the camera"
        bodyDetected = false
    }
}
