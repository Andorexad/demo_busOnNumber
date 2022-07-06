//
//  DrawingBoundingBoxView.swift
//  ObjectDetectionYOLO
//
//  Created by Andi Xu on 12/22/21.
//

import UIKit
import Vision
import AVFoundation

class DrawingBoundingBoxView: UIView {

    
    static private var colors: [String: UIColor] = [:]
    private var foundSet = Set<String?>()
    var requiredItem: Set<String> = ["bus"]
    
    public func labelColor(with label: String) -> UIColor {
        if let color = DrawingBoundingBoxView.colors[label] {
            return color
        } else {
            let color = UIColor(hue: .random(in: 0...1), saturation: 1, brightness: 1, alpha: 0.8)
            DrawingBoundingBoxView.colors[label] = color
            return color
        }
    }
    
    public var predictedObjects: [VNDetectedObjectObservation] = [] {
        didSet {
            DispatchQueue.main.async{
                self.drawBoxs(with: self.predictedObjects)
                self.setNeedsDisplay()
            }
        }
    }
    
    func drawBoxs(with predictions: [VNDetectedObjectObservation]) {
        
        self.subviews.forEach({ $0.removeFromSuperview() })
        
        for prediction in predictions {
            self.createLabelAndBox(prediction: prediction)
        }
    }
    
    func createLabelAndBox(prediction: VNDetectedObjectObservation) {
        
        let color: UIColor = labelColor(with: "bus")
        let bgRect = VNImageRectForNormalizedRect(prediction.boundingBox,
                                                  Int(self.bounds.width),Int(self.bounds.height))
        
//        let scale = CGAffineTransform.identity.scaledBy(x: bounds.width, y: bounds.height)
//        let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -1)
//        let bgRect = prediction.boundingBox.applying(transform).applying(scale)
        
        let bgView = UIView(frame: bgRect)
        bgView.layer.borderColor = color.cgColor
        bgView.layer.borderWidth = 4
        bgView.backgroundColor = UIColor.clear
        addSubview(bgView)
        
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        label.text = "bus"
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = UIColor.black
        label.backgroundColor = color
        label.sizeToFit()
        label.frame = CGRect(x: bgRect.origin.x, y: bgRect.origin.y - label.frame.height,
                             width: label.frame.width, height: label.frame.height)
        addSubview(label)
        

    }

    func playSound( str: String ){
        let utterance = AVSpeechUtterance(string: str)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
    }
    
    public func findNewItem(newlyDetected: Set<String?>){
        let pred_set = newlyDetected.subtracting(self.foundSet)
        for pred in pred_set {
            if !requiredItem.contains(pred!) {
                return
            }
            self.playSound(str: pred!)
        }
        self.foundSet=newlyDetected
    }

}

extension VNRecognizedObjectObservation {
    var label: String? {
        return self.labels.first?.identifier
    }
}
//
//extension CGRect {
//    func toString(digit: Int) -> String {
//        let xStr = String(format: "%.\(digit)f", origin.x)
//        let yStr = String(format: "%.\(digit)f", origin.y)
//        let wStr = String(format: "%.\(digit)f", width)
//        let hStr = String(format: "%.\(digit)f", height)
//        return "(\(xStr), \(yStr), \(wStr), \(hStr))"
//    }
//}
//

extension UIImage {
    func pixelBufferFromImage() -> CVPixelBuffer {
        let ciimage = CIImage(image: self)
        let tmpcontext = CIContext(options: nil)
        let cgimage =  tmpcontext.createCGImage(ciimage!, from: ciimage!.extent)

        let cfnumPointer = UnsafeMutablePointer<UnsafeRawPointer>.allocate(capacity: 1)
        let cfnum = CFNumberCreate(kCFAllocatorDefault, .intType, cfnumPointer)
        let keys: [CFString] = [kCVPixelBufferCGImageCompatibilityKey, kCVPixelBufferCGBitmapContextCompatibilityKey, kCVPixelBufferBytesPerRowAlignmentKey]
        let values: [CFTypeRef] = [kCFBooleanTrue, kCFBooleanTrue, cfnum!]
        let keysPointer = UnsafeMutablePointer<UnsafeRawPointer?>.allocate(capacity: 1)
        let valuesPointer =  UnsafeMutablePointer<UnsafeRawPointer?>.allocate(capacity: 1)
        keysPointer.initialize(to: keys)
        valuesPointer.initialize(to: values)

        let options = CFDictionaryCreate(kCFAllocatorDefault, keysPointer, valuesPointer, keys.count, nil, nil)

        let width = cgimage!.width
        let height = cgimage!.height

        var pxbuffer: CVPixelBuffer?
        // if pxbuffer = nil, you will get status = -6661
        var status = CVPixelBufferCreate(kCFAllocatorDefault, width, height,
                                         kCVPixelFormatType_32BGRA, options, &pxbuffer)
        status = CVPixelBufferLockBaseAddress(pxbuffer!, CVPixelBufferLockFlags(rawValue: 0));

        let bufferAddress = CVPixelBufferGetBaseAddress(pxbuffer!);


        let rgbColorSpace = CGColorSpaceCreateDeviceRGB();
        let bytesperrow = CVPixelBufferGetBytesPerRow(pxbuffer!)
        let context = CGContext(data: bufferAddress,
                                width: width,
                                height: height,
                                bitsPerComponent: 8,
                                bytesPerRow: bytesperrow,
                                space: rgbColorSpace,
                                bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue);
        context?.concatenate(CGAffineTransform(rotationAngle: 0))
        context?.concatenate(__CGAffineTransformMake( 1, 0, 0, -1, 0, CGFloat(height) ))


        context?.draw(cgimage!, in: CGRect(x:0, y:0, width:CGFloat(width), height:CGFloat(height)));
        status = CVPixelBufferUnlockBaseAddress(pxbuffer!, CVPixelBufferLockFlags(rawValue: 0));
        return pxbuffer!;

    }
}



//
//extension UIView {
//
//
//    // Using a function since `var image` might conflict with an existing variable
//    // (like on `UIImageView`)
//    func asImage() -> UIImage {
//        if #available(iOS 10.0, *) {
//            let renderer = UIGraphicsImageRenderer(bounds: bounds)
//            return renderer.image { rendererContext in
//                layer.render(in: rendererContext.cgContext)
//            }
//        } else {
//            UIGraphicsBeginImageContext(self.frame.size)
//            self.layer.render(in:UIGraphicsGetCurrentContext()!)
//            let image = UIGraphicsGetImageFromCurrentImageContext()
//            UIGraphicsEndImageContext()
//            return UIImage(cgImage: image!.cgImage!)
//        }
//    }
//}
//
//

