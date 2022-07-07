
import CoreML
import Vision
import CoreImage
import UIKit

struct Recognizer {
    
    private(set) var results: [String]?
    
    mutating func detect(cgImage: CGImage)->[String] {
        
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en-US"]
        request.usesLanguageCorrection = true
        
        
        let handler = VNImageRequestHandler(cgImage: cgImage)
        
        do {
            try handler.perform([request])
        } catch {
            print("Unable to perform the request: \(error).")
        }
        
        guard let observations = request.results as? [VNRecognizedTextObservation] else { return []}
        
        let recognizedStrings = observations.compactMap{observation in
            return observation.topCandidates(1).first?.string
        }
        
//        recognizedStrings = ["13 SEP 19", "2020.12.8", "2022-12-02", "07/05/2022","040917", "2020 NO 14", "AUG 10 2019"]
        return recognizedStrings
    }
}




