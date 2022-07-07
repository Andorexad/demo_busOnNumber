//
//  GoogleCloudVisionOCR.swift
//  photoTextRecognition
//
//  Created by 郑晨浩 on 6/29/22.
//

import Foundation
import Alamofire




class GoogleCloudOCR {
  private let apiKey = "AIzaSyCjkRfC_6vRvH-BTbv2OkzVBCLbOXHwQ8E"
  private var apiURL: URL {
    return URL(string: "https://vision.googleapis.com/v1/images:annotate?key=\(apiKey)")!
  }

  func detect(from image: UIImage, completion: @escaping (OCRResult?) -> Void) {
    guard let base64Image = base64EncodeImage(image) else {
      print("Error while base64 encoding image")
      return
    }
    callGoogleVisionAPI(with: base64Image, completion: completion)
  }

    
    
  private func callGoogleVisionAPI(
    with base64EncodedImage: String) {
    let parameters: Parameters = [
      "requests": [
        [
          "image": [
            "content": base64EncodedImage
          ],
          "features": [
            [
              "type": "TEXT_DETECTION"
            ]
          ]
        ]
      ]
    ]
    let headers: HTTPHeaders = [
      "X-Ios-Bundle-Identifier": Bundle.main.bundleIdentifier ?? "",
      ]
    Alamofire.request(
      apiURL,
      method: .post,
      parameters: parameters,
      encoding: JSONEncoding.default,
      headers: headers)
      .responseData { response in // .responseData instead of .responseJSON
        if response.result.isFailure {
          completion(nil)
          return
        }
        guard let data = response.result.value else {
          completion(nil)
          return
        }
        // Decode the JSON data into a `GoogleCloudOCRResponse` object.
        let ocrResponse = try? JSONDecoder().decode(GoogleCloudOCRResponse.self, from: data)
        completion(ocrResponse?.responses[0])
    }
  }
    
    
    private func callSceneRecog(
      with base64EncodedImage: String) {
      let parameters: Parameters = [
        "requests": [
          [
            "image": [
              "content": base64EncodedImage
            ],
            "features": [
                    [
                      "maxResults": 50,
                      "type": "LANDMARK_DETECTION"
                    ],
                    [
                      "maxResults": 50,
                      "type": "FACE_DETECTION"
                    ],
                    [
                      "maxResults": 50,
                      "type": "OBJECT_LOCALIZATION"
                    ],
                    [
                      "maxResults": 50,
                      "type": "LOGO_DETECTION"
                    ],
                    [
                      "maxResults": 50,
                      "type": "LABEL_DETECTION"
                    ],
                    [
                      "maxResults": 50,
                      "model": "builtin/latest",
                      "type": "DOCUMENT_TEXT_DETECTION"
                    ],
                    [
                      "maxResults": 50,
                      "type": "SAFE_SEARCH_DETECTION"
                    ],
                    [
                      "maxResults": 50,
                      "type": "IMAGE_PROPERTIES"
                    ],
                    [
                      "maxResults": 50,
                      "type": "CROP_HINTS"
                    ]
            ]
          ]
        ]
      ]
      let headers: HTTPHeaders = [
        "X-Ios-Bundle-Identifier": Bundle.main.bundleIdentifier ?? "",
        ]
      Alamofire.request(
        apiURL,
        method: .post,
        parameters: parameters,
        encoding: JSONEncoding.default,
        headers: headers)
        .responseData { response in // .responseData instead of .responseJSON
          if response.result.isFailure {
            return
          }
          guard let data = response.result.value else {
            return
          }
        let str = String(decoding: data, as: UTF8.self)
        print(str)
          
      }
    }
    
    
    
    
    
    

  private func base64EncodeImage(_ image: UIImage) -> String? {
    return image.pngData()?.base64EncodedString(options: .endLineWithCarriageReturn)
  }
}
