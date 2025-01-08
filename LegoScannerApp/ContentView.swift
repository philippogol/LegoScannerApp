import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    @State private var isCameraActive = false
    @State private var classificationResult = ""
    @State private var accuracy: Float = 0.0 // Add accuracy state
    @State private var isInferring = false // Throttling inference
    private let modelManager = ModelManager()
    
    private let boundingBoxSize: CGFloat = 200.0 // Bounding box size

    var body: some View {
        ZStack {
            // Camera feed
            if isCameraActive {
                CameraPreview(image: cameraManager.frame)
                    .ignoresSafeArea()
                    .onChange(of: cameraManager.frame) { newFrame in
                        guard !isInferring, let frame = newFrame else { return }
                        isInferring = true
                        
                        // Perform inference on a background thread
                        DispatchQueue.global(qos: .userInitiated).async {
                            let result = modelManager.classifyWithAccuracy(frame: frame)
                            DispatchQueue.main.async {
                                classificationResult = result.label
                                accuracy = result.accuracy
                                isInferring = false
                            }
                        }
                    }
            }
            
            // Overlay bounding box
            if isCameraActive {
                Rectangle()
                    .stroke(Color.green, lineWidth: 3)
                    .frame(width: boundingBoxSize, height: boundingBoxSize)
                    .position(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY)
            }
            
            // Classification result
            VStack {
                Spacer()
                
                // Move the classification text higher
                Text("\(classificationResult) (\(String(format: "%.2f", accuracy * 100))%)")
                    .font(.title2)
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(10)
                    .padding(.bottom, 150) // Adjust padding to move the text higher
            }
            
            // Start/Stop camera button
            VStack {
                Spacer()
                Button(action: {
                    isCameraActive.toggle()
                    if isCameraActive {
                        cameraManager.start()
                    } else {
                        cameraManager.stop()
                    }
                }) {
                    Image(systemName: isCameraActive ? "camera.fill" : "camera")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .padding(.bottom, 20)
            }
        }
    }
}

struct CameraPreview: View {
    let image: CGImage?

    var body: some View {
        if let image = image {
            GeometryReader { geometry in
                Image(image, scale: 1.0, label: Text("Camera Feed"))
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
            }
        } else {
            Color.black
        }
    }
}
