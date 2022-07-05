/*
Contains all functions of vision request (text recognition, object recognition, and object tracking)
 */

import UIKit
import AVFoundation
import Vision

@available(iOS 13.0, *)
class VisionObjectRecognitionViewController: ViewController {
    
    private var detectionRequests: [VNCoreMLRequest]?
    private var trackingRequests: [VNTrackObjectRequest]?
    lazy var sequenceRequestHandler = VNSequenceRequestHandler()
    
    @IBOutlet weak var boxesView: DrawingBoundingBoxView!
    var predictions: [VNRecognizedObjectObservation] = []
    
    var command: [String:String]=[:]
    
    var numberTracker=StringTracker()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.bringSubviewToFront(boxesView)
        prepareObjectTrackingRequest()
    }
    
   
        
    func prepareObjectTrackingRequest() {
        var requests = [VNTrackObjectRequest]()
        
        let yoloModel = YOLOv3()
        var visionModel: VNCoreMLModel?
        do {
            visionModel = try VNCoreMLModel(for: yoloModel.model)
        } catch {
            print("ObjectDetection error: \(String(describing: error)).")
            return
        }
        let objectRecognitionRequest = VNCoreMLRequest(model: visionModel!, completionHandler: { (request, error) in
            
            if error != nil {
                print("ObjectDetection error: \(String(describing: error)).")
            }
            
            guard let objectRecognitionRequest = request as? VNCoreMLRequest,
                let results = objectRecognitionRequest.results as? [VNRecognizedObjectObservation] else {
                    return
            }
            
            
            
            
            //guard let target=self.command["type"] else {return}
            
            let target="bus"
            
            
            for result in results { //
                if result.label == target {
                    // find bus
                    DispatchQueue.main.async {
                        print("find bus")
                        // Add this bus observation to the tracking list
                        let objectTrackingRequest = VNTrackObjectRequest(detectedObjectObservation: result)
                        requests.append(objectTrackingRequest)
                    }
                }
            }
            
            
            if requests.count==0 && results.count>0 {
                // not find bus, speak other 5 things
                let tempLen=((5<results.count) ? 5:results.count)-1
                // TODO: add audio output
                print("no bus found. found ")
                for result in results[0...tempLen]{
                    print(result.labels.first!)
                }
                return // no need to add any trackingRequest
            }
            self.trackingRequests = requests
            
            
        })
        // Start with detection.  Find object, then track it.
        self.detectionRequests = [objectRecognitionRequest]
        self.sequenceRequestHandler = VNSequenceRequestHandler()
    }
    
    func convertBufferToUIImage(pixelBuffer: CVPixelBuffer, boundingBox: CGRect?) -> UIImage? {
        var ciimage: CIImage = CIImage(cvImageBuffer: pixelBuffer)
        if let bounds = boundingBox {
            ciimage=ciimage.cropped(to:bounds)
        }
        let ciContext = CIContext()
        guard let cgImage: CGImage = ciContext.createCGImage(ciimage, from: ciimage.extent) else {
            return nil
        }
        let uiImage: UIImage = UIImage(cgImage: cgImage)
        return uiImage
    }
    
    
    func speak(string: String){
        self.numberTracker.playSound(str: string)
    }
    
    // when can the app speak?
//    func speakObjectDetectionStatus(string: String){
//        if now-lastSpeak <= 3 && status_no_change {return}
//        speak(string)
//    }
    
    override func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        var requestHandlerOptions: [VNImageOption: AnyObject] = [:]
        let cameraIntrinsicData = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil)
        if cameraIntrinsicData != nil {
            requestHandlerOptions[VNImageOption.cameraIntrinsics] = cameraIntrinsicData
        }
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let exifOrientation = exifOrientationFromDeviceOrientation()
        
        guard let requests = self.trackingRequests, !requests.isEmpty else {
            // No tracking object detected, so perform initial detection
//            speakObjectDetectionStatus(string:"No bus on screen")
//            print("no bus on screen")
            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                                            orientation: exifOrientation,
                                                            options: requestHandlerOptions)
            
            do {
                guard let detectRequests = self.detectionRequests else {
                    return
                }
                try imageRequestHandler.perform(detectRequests)
            } catch let error as NSError {
                NSLog("Failed to perform ObjectDetectionRequest: %@", error)
            }
            return
        }
        
        do {
            try self.sequenceRequestHandler.perform(requests,
                                                     on: pixelBuffer,
                                                     orientation: exifOrientation)
        } catch let error as NSError {
            NSLog("Failed to perform SequenceRequest: %@", error)
        }
        
        // Setup the next round of tracking.
        var newTrackingRequests = [VNTrackObjectRequest]()
        for trackingRequest in requests {
            
            guard let results = trackingRequest.results else {
                return
            }
            
            guard let observation = results[0] as? VNDetectedObjectObservation else {
                return
            }
            
            if !trackingRequest.isLastFrame {
                if observation.confidence > 0.3 {
                    trackingRequest.inputObservation = observation
                } else {
                    trackingRequest.isLastFrame = true
                    //speakObjectDetectionStatus(string:"Bus is going to disappear")
                    print("Bus is going to disappear")
                }
                newTrackingRequests.append(trackingRequest)
            }
        }
        
        self.trackingRequests = newTrackingRequests
        if newTrackingRequests.isEmpty {
            // Nothing to track, so abort.
            //speakObjectDetectionStatus(string:"Bus disappeared on screen")
            print("Bus disappeared on screen")
            return
        }
        
        
        // Perform text detection and recognition on tracked objects.
        for trackingRequest in newTrackingRequests {
            
            guard let trackingResults = trackingRequest.results else {
                return
            }
            
            
            
            guard let observation = trackingResults[0] as? VNDetectedObjectObservation else {
                return
            }
            // draw bounding box around bus
            DispatchQueue.main.async {
//                let res=observation as! VNRecognizedObjectObservation
                self.boxesView.predictedObjects = [observation]
            }
            
            if let cropped_object_image=convertBufferToUIImage(pixelBuffer: pixelBuffer, boundingBox: observation.boundingBox){
                // define text recognition requests and perform requests
                OCR(image: cropped_object_image, useGCV: false)
                // TODO: do ocr here and log detected text. only output stable text
                
            }
        }
    }
    
    override func setupAVCapture() {
        super.setupAVCapture()
        startCaptureSession()
    }
    
    
    
//    func OCR(image: UIImage, useGCV: Bool ) -> [String]{
//        return []
//    }
//
    func filtering(strings:[String], command: [String]) -> [String]{
        return strings
    }
    
    func OCR(image: UIImage, useGCV: Bool ){
        print("start ocr")
        // Get the CGImage on which to perform requests.
        guard let cgImage = image.cgImage else{ return}
        let requestHandler = VNImageRequestHandler(cgImage: cgImage)


        // Create a new request to recognize text.
        let request = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)


        do {
            // Perform the text-recognition request.
            try requestHandler.perform([request])
        } catch {
            print("Unable to perform the requests: \(error).")
        }
    }
                
    func recognizeTextHandler(request: VNRequest, error: Error?) {
        guard let observations =
                request.results as? [VNRecognizedTextObservation] else {
            return
        }
        let recognizedStrings = observations.compactMap { observation in
            // Return the string of the top VNRecognizedText instance.
            return observation.topCandidates(1).first?.string
        }
        numberTracker.recognizeTextFinish(results:recognizedStrings)
        
        // Process the recognized strings.
//        processResults(recognizedStrings)
    }
   
    
}
