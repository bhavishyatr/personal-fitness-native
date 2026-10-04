import Foundation
import Vision

let arguments = CommandLine.arguments
 guard arguments.count == 3 else { fatalError("Expected screenshot path and tab") }
let request = VNRecognizeTextRequest()
request.recognitionLevel = .accurate
let handler = VNImageRequestHandler(url: URL(fileURLWithPath: arguments[1]), options: [:])
do {
    try handler.perform([request])
    let observations = request.results ?? []
    let title = arguments[2].lowercased()
    let headerPresent = observations.contains {
        $0.boundingBox.midY > 0.65 && $0.topCandidates(1).first?.string.lowercased() == title
    }
    let content = observations.compactMap { $0.topCandidates(1).first?.string.lowercased() }.joined(separator: " ")
    let marker = title == "history" ? "compare two sessions" : "sessions"
    guard headerPresent && content.contains(marker) else {
        print("Waiting for \(title) title and content to render")
        exit(1)
    }
    print("Verified \(title) screenshot title and content")
} catch {
    print("Screenshot verification failed: \(error)")
    exit(1)
}
