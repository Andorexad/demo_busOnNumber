
import SwiftUI

class TextRecognizer: ObservableObject {
    
    @Published private var classifier = Recognizer()
    
    
    @Published var recognizedStrings: [String]  = []
        
    // MARK: Intent(s)
    func detect(uiImage: UIImage) {
        guard let cgImage = uiImage.cgImage else { return }
        
        let recoString = classifier.detect(cgImage: cgImage)
        print("CoreML original Strings \(recoString)")
        
        self.recognizedStrings = recoString
    
    }
    
    func detectByGCV(for image: UIImage) {
      GoogleCloudOCR().detect(from: image) { ocrResult in
        guard let ocrResult = ocrResult else {
          fatalError("Did not recognize any text in this image")
        }
        
          var observedStrings: [String] = []
          for annotation in ocrResult.annotations{
              observedStrings.append(annotation.text)
          }
          observedStrings.remove(at: 0)
          print("GCV original string \(observedStrings)")

          self.recognizedStrings = observedStrings
      }
    }
        
}



