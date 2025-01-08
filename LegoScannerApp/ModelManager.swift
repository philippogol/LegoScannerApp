import TensorFlowLite
import SwiftUI

class ModelManager: ObservableObject {
    @Published private(set) var currentModelName: String = "legocheck-model.tflite"
    private var interpreter: Interpreter?
    private let defaultClassLabels = ["10247", "11090", "11211"]
    private var classLabels = [String]()
    private let confidenceThreshold: Float = 0.5 // Threshold for valid predictions

    init(modelName: String = "legocheck-model.tflite") {
        loadModel(named: modelName)
    }

    func loadModel(named modelName: String) {
        guard let modelPath = Bundle.main.path(forResource: modelName, ofType: nil) else {
            print("Failed to load model: \(modelName)")
            return
        }

        do {
            interpreter = try Interpreter(modelPath: modelPath)
            try interpreter?.allocateTensors()
            classLabels = defaultClassLabels // Replace with dynamic labels if needed
            currentModelName = modelName
        } catch {
            print("Failed to create interpreter for \(modelName): \(error.localizedDescription)")
        }
    }

    func classifyWithAccuracy(frame: CGImage) -> (label: String, accuracy: Float) {
        guard let input = preprocessImage(frame, width: 64, height: 64) else {
            return ("Error", 0.0)
        }

        do {
            try interpreter?.copy(input, toInputAt: 0)
            try interpreter?.invoke()

            guard let outputTensor = try interpreter?.output(at: 0) else {
                return ("Error", 0.0)
            }

            let outputSize = outputTensor.data.count / MemoryLayout<Float32>.size
            var results = [Float32](repeating: 0, count: outputSize)
            _ = results.withUnsafeMutableBytes { outputTensor.data.copyBytes(to: $0) }

            if let maxIndex = results.indices.max(by: { results[$0] < results[$1] }) {
                let confidence = results[maxIndex]
                if confidence >= confidenceThreshold {
                    return (classLabels[maxIndex], confidence)
                }
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
