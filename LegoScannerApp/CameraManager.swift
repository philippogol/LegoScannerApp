import AVFoundation
import UIKit
import Photos

class CameraManager: NSObject, ObservableObject {
    @Published var frame: CGImage?
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var videoOrientation: AVCaptureVideoOrientation = .portrait
    private var lastSavedTime: TimeInterval = 0 // Timestamp of the last saved frame
    private let saveInterval: TimeInterval = 10 // Save every 3 seconds

    override init() {
        super.init()
        checkPermissions()
    }

    private func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        self?.setupCamera()
                    }
                }
            }
        case .restricted, .denied:
            print("Camera access restricted or denied")
            return
        case .authorized:
            setupCamera()
        @unknown default:
            print("Unknown authorization status")
            return
        }
    }

    private func setupCamera() {
        let session = AVCaptureSession()
        session.beginConfiguration()

        // Set camera input
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            print("Failed to create camera input")
            return
        }

        session.addInput(input)

        // Set video output
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera_frame_processing"))
        session.addOutput(videoOutput)

        // Set video orientation
        if let connection = videoOutput.connection(with: .video) {
            connection.videoOrientation = .portrait
        }

        session.commitConfiguration()

        self.captureSession = session
        self.videoOutput = videoOutput
    }

    func start() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }

    func stop() {
        captureSession?.stopRunning()
    }

    private func saveFrameToPhotoLibrary(frame: CGImage) {
        let uiImage = UIImage(cgImage: frame)

        // Request photo library authorization if not already granted
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                print("Photo Library access not authorized")
                return
            }

            DispatchQueue.main.async {
                UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
                print("Frame saved to Photo Library")
            }
        }
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }

        DispatchQueue.main.async {
            self.frame = cgImage
        }

        // Screen dimensions
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height

        // Camera feed dimensions (CGImage)
        let cameraWidth = CGFloat(cgImage.width)
        let cameraHeight = CGFloat(cgImage.height)

        // Calculate scale factors
        let scaleX = cameraWidth / screenWidth
        let scaleY = cameraHeight / screenHeight

        // Green box dimensions and position on the screen
        let greenBoxWidth: CGFloat = 200 // Match your green box size
        let greenBoxHeight: CGFloat = 200
        let greenBoxOriginX = (screenWidth - greenBoxWidth) / 2
        let greenBoxOriginY = (screenHeight - greenBoxHeight) / 2

        // Scale green box dimensions and position to the camera feed
        let scaledBoxX = greenBoxOriginX * scaleX
        let scaledBoxY = greenBoxOriginY * scaleY
        let scaledBoxWidth = greenBoxWidth * scaleX
        let scaledBoxHeight = greenBoxHeight * scaleY

        let scaledBoundingBox = CGRect(x: scaledBoxX, y: scaledBoxY, width: scaledBoxWidth, height: scaledBoxHeight)

        // Crop the image to the scaled bounding box
        guard let croppedImage = cgImage.cropping(to: scaledBoundingBox) else {
            print("Failed to crop image to scaled bounding box")
            return
        }

        // Save the cropped image before sending it to the model
        let currentTime = Date().timeIntervalSince1970
        if currentTime - lastSavedTime >= saveInterval {
            lastSavedTime = currentTime
            saveFrameToPhotoLibrary(frame: croppedImage) // Save cropped image
        }

        // Send the cropped image to the model
        processCroppedImage(croppedImage)
    }

    private func processCroppedImage(_ croppedImage: CGImage) {
        DispatchQueue.global(qos: .userInitiated).async {
            let modelManager = ModelManager()
            let result = modelManager.classifyWithAccuracy(frame: croppedImage)
            DispatchQueue.main.async {
                print("Model Prediction: \(result.label), Confidence: \(result.accuracy)")
            }
        }
    }
}

