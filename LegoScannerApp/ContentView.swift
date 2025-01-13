//changes mon 13.01.25 (pipo)
import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    @State private var isCameraActive = false
    @State private var classificationResult = ""
    @State private var accuracy: Float = 0.0
    @State private var isInferring = false
    @State private var selectedModel = "legocheck-model.tflite"
    @StateObject private var modelManager = ModelManager()

    private let availableModels = [
        "legocheck-model.tflite",
        "legocheck-model-2.tflite",
        "legocheck-model-3.tflite"
    ]

    var body: some View {
        ZStack {
            if isCameraActive {
                // Camera feed
                CameraPreview(image: cameraManager.frame)
                    .ignoresSafeArea()
                    .onChange(of: cameraManager.frame) { newFrame in
                        guard !isInferring, let frame = newFrame else { return }
                        isInferring = true

                        DispatchQueue.global(qos: .userInitiated).async {
                            let result = modelManager.classifyWithAccuracy(frame: frame)
                            DispatchQueue.main.async {
                                classificationResult = result.label
                                accuracy = result.accuracy
                                isInferring = false
                            }
                        }
                    }
                
                // Overlay bounding box
                GeometryReader { geometry in
                    Rectangle()
                        .stroke(Color.green, lineWidth: 3)
                        .frame(width: 200, height: 200)
                        .position(x: geometry.size.width / 2,
                                  y: geometry.size.height / 2 - 10) // Adjust dynamically
                }


                
                VStack {
                    Spacer()
                    
                    Text("\(classificationResult) (\(String(format: "%.2f", accuracy * 100))%)")
                        .font(.title2)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                        .padding(.bottom, 150)
                }
                
                // X button to stop the camera and return to the initial view
                VStack {
                    HStack {
                        Button(action: {
                            isCameraActive = false
                            cameraManager.stop()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .padding()
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        .padding(.leading, 20)
                        .padding(.top, 40)
                        Spacer()
                    }
                    Spacer()
                }
            } else {
                VStack {
                    // Dropdown for selecting model
                    Text("Select Model")
                        .font(.headline)
                        .padding(.bottom, 10)
                    
                    Picker("Model", selection: $selectedModel) {
                        ForEach(availableModels, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                    .onChange(of: selectedModel) { newModel in
                        modelManager.loadModel(named: newModel) // Trigger model load when selection changes
                    }

                    // Text box for model loaded status
                    Text(modelManager.currentModelName)
                        .font(.subheadline)
                        .foregroundColor(modelManager.currentModelName.contains("correctly loaded") ? .green : .red)
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)
                        .padding(.bottom, 20)

                    
                    Button(action: {
                        modelManager.loadModel(named: selectedModel)
                        isCameraActive.toggle()
                        if isCameraActive {
                            cameraManager.start()
                        } else {
                            cameraManager.stop()
                        }
                    }) {
                        Image(systemName: "camera")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
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
