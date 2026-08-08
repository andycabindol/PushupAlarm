import SwiftUI
import AVFoundation

struct CameraView: UIViewRepresentable {
    let pushupDetector: PushupDetector
    
    func makeUIView(context: Context) -> CameraPreviewView {
        let view = CameraPreviewView()
        context.coordinator.setupCamera(with: view, detector: pushupDetector)
        return view
    }
    
    func updateUIView(_ uiView: CameraPreviewView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        private var captureSession: AVCaptureSession?
        private weak var detector: PushupDetector?
        
        func setupCamera(with previewView: CameraPreviewView, detector: PushupDetector) {
            self.detector = detector
            
            let session = AVCaptureSession()
            session.sessionPreset = .high
            
            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
                  let input = try? AVCaptureDeviceInput(device: camera) else {
                print("Failed to access camera")
                return
            }
            
            if session.canAddInput(input) {
                session.addInput(input)
            }
            
            let output = AVCaptureVideoDataOutput()
            output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            output.alwaysDiscardsLateVideoFrames = true
            
            if session.canAddOutput(output) {
                session.addOutput(output)
            }
            
            if let connection = output.connection(with: .video) {
                connection.videoOrientation = .portrait
                if connection.isVideoMirroringSupported {
                    connection.isVideoMirrored = true
                }
            }
            
            previewView.videoPreviewLayer.session = session
            previewView.videoPreviewLayer.videoGravity = .resizeAspectFill
            
            self.captureSession = session
            
            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
            }
        }
        
        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            detector?.processFrame(sampleBuffer)
        }
        
        func stopCamera() {
            captureSession?.stopRunning()
        }
    }
}

class CameraPreviewView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        videoPreviewLayer.frame = bounds
    }
}
