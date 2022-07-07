//
//  PhotoVC.swift
//  BreakfastFinder
//
//  Created by Andi Xu on 7/6/22.
//  Copyright © 2022 Apple. All rights reserved.
//

import UIKit
import Vision

@available(iOS 13.0, *)
class PhotoVC: UIViewController {
    
    @IBOutlet weak var imageview: UIImageView!
    var image : UIImage?
    @IBOutlet weak var ondevice_ocr_button: UIButton!
    
    @IBOutlet weak var resultTextview: UITextView!
    override func viewDidLoad() {
        
        super.viewDidLoad()
        //imageview.
        resultTextview.isScrollEnabled=true
        imageview.image = image
        self.view.bringSubviewToFront(ondevice_ocr_button)
    }
    
    @IBAction func backToVideo(_ sender: Any) {
        self.dismiss(animated: true) {
            //restartsession()
            return
        }
    }
    
    @IBAction func doOnDeviceOCR(_ sender: UIButton) {
        
        guard let cgImage = image?.cgImage else { return }


        // Create a new image-request handler.
        let requestHandler = VNImageRequestHandler(cgImage: cgImage,orientation:.right)


        // Create a new request to recognize text.
        let request = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)


        do {
            // Perform the text-recognition request.
            try requestHandler.perform([request])
        } catch {
            print("Unable to perform the requests: \(error).")
        }
    }
   
    private func recognizeTextHandler(request: VNRequest, error: Error?) {
        guard let observations =
                request.results as? [VNRecognizedTextObservation] else {
            return
        }
        
        let boundingRects: [CGRect] = observations.compactMap { observation in
            // Find the top observation.
            guard let candidate = observation.topCandidates(1).first else { return .zero }
            
            // Find the bounding-box observation for the string range.
            let stringRange = candidate.string.startIndex..<candidate.string.endIndex
            let boxObservation = try? candidate.boundingBox(for: stringRange)
            
            // Get the normalized CGRect value.
            let boundingBox = boxObservation?.boundingBox ?? .zero
            
            // Convert the rectangle from normalized coordinates to image coordinates.
            return VNImageRectForNormalizedRect(boundingBox,
                                                Int(image!.size.width),
                                                Int(image!.size.height))
        }
        boundingRects.forEach(draw(rect:))
       
        
        let recognizedStrings = observations.compactMap { observation in
            // Return the string of the top VNRecognizedText instance.
            return observation.topCandidates(1).first?.string
        }
        
        // Process the recognized strings.
        print(recognizedStrings)
        resultTextview.text=""
        for str in recognizedStrings{
            resultTextview.text! += "\n \(str)"
        }
        print(resultTextview.text)
        
    }
    
    func draw(rect: CGRect) {
        let layer = CAShapeLayer()
        layer.opacity = 0.5
        layer.borderColor = UIColor.blue.cgColor
        layer.borderWidth = 1
        layer.frame = rect
        self.imageview.layer.addSublayer(layer)
//        self.imageview.layer.append(layer)
//        previewView.videoPreviewLayer.insertSublayer(layer, at: 1)
    }
    
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
