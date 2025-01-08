import TensorFlowLite

class ModelManager {
    private var interpreter: Interpreter?
    private let classLabels = ["10247", "11090", "11211"]

    init() {
        guard let modelPath = Bundle.main.path(forResource: "legocheck-model", ofType: "tflite") else {
            print("Failed to load model")
            return
        }
        
        do {
            interpreter = try Interpreter(modelPath: modelPath)
            try interpreter?.allocateTensors()
        } catch {
            print("Failed to create interpreter: \(error.localizedDescription)")
        }
    }
    
    func classifyWithAccuracy(frame: CGImage) -> (label: String, accuracy: Float) {
        // Preprocess the image
        guard let input = preprocessImage(frame, width: 64, height: 64) else {
            return ("Error", 0.0)
        }
        
        do {
            // Perform inference
            try interpreter?.copy(input, toInputAt: 0)
            try interpreter?.invoke()
            
            // Get the output tensor
            guard let outputTensor = try interpreter?.output(at: 0) else {
                return ("Error", 0.0)
            }
            
            // Extract results
            let outputSize = outputTensor.data.count / MemoryLayout<Float32>.size
            var results = [Float32](repeating: 0, count: outputSize)
            _ = results.withUnsafeMutableBytes { outputTensor.data.copyBytes(to: $0) }
            
            // Find the label with the highest probability
            if let maxIndex = results.indices.max(by: { results[$0] < results[$1] }) {
                let confidence = results[maxIndex]
                return (classLabels[maxIndex], confidence)
            }
        } catch {
            print("Inference error: \(error.localizedDescription)")
        }
        
        return ("Unknown", 0.0)
    }
    
    private func preprocessImage(_ image: CGImage, width: Int, height: Int) -> Data? {
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else {
            print("Error creating CGContext")
            return nil
        }
        
        // Resize the image
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let resizedBuffer = context.data else {
            print("Error getting resized image data")
            return nil
        }
        
        var normalizedBuffer = [Float32](repeating: 0, count: width * height * 3)
        let pixelData = resizedBuffer.bindMemory(to: UInt8.self, capacity: width * height * 4)
        
        for i in 0..<(width * height) {
            normalizedBuffer[i * 3 + 0] = Float32(pixelData[i * 4 + 0]) / 255.0 // Red
            normalizedBuffer[i * 3 + 1] = Float32(pixelData[i * 4 + 1]) / 255.0 // Green
            normalizedBuffer[i * 3 + 2] = Float32(pixelData[i * 4 + 2]) / 255.0 // Blue
        }
        
        return Data(bytes: normalizedBuffer, count: normalizedBuffer.count * MemoryLayout<Float32>.size)
    }
}