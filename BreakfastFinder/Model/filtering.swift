//
//  filtering.swift
//  photoTextRecognition
//
//  Created by 郑晨浩 on 6/29/22.
//

import Foundation
import MLKit


func filtering(recognizedStrings: [String], type: String, isReg: Bool = false) -> [String]{
    var processedString:[String] = []
    if (isReg){
        
    }
    else if (type == "Find Expiration Date"){
        processedString = filterStringByDate(originalStrings: recognizedStrings)
    }
    else if (type == "Find address"){
        processedString = filterStringByAddress(originalStrings: recognizedStrings)
    }
    else if (type == "Find email"){
        processedString = filterStringByEmail(originalStrings: recognizedStrings)
    }
    else{
        processedString = filterStringByKeyword(originalStrings: recognizedStrings, keyword: type)
    }
    return processedString
}


func filterStringByReg(originalStrings: [String], regString: String) -> [String]{
    var processedStrings: [String] = []
    for str in originalStrings{
        if (str.range(of: regString,
                      options: .regularExpression) != nil){
            processedStrings.append(str)
        }
    }
    return processedStrings
}



func filterStringByKeyword(originalStrings: [String], keyword: String) -> [String]{
    var processedStrings: [String] = []
    let low_keyword = keyword.lowercased()
    for str in originalStrings{
        let low_str = str.lowercased()
        if low_str.contains(low_keyword){
            processedStrings.append(str)
        }
    }
    return processedStrings
}


func filterStringByDate(originalStrings: [String]) -> [String] {
    var processedStrings: [String] = []
    
    let regString = #"\d{4}(-|.)(0[1-9]|1[0-2])(-|.)(0[1-9]|[12][0-9]|3[01])"#
    
    for str in originalStrings{
        if (str.range(of: regString,
                      options: .regularExpression) != nil){
            processedStrings.append(str)
        }
        else if (usingDataDetector(input: str, type: [.date])){
            processedStrings.append(str)
        }
//        else if (usingMLkit(input: str, expectType: "date")){
//            processedStrings.append(str)
//        }
    }
    return processedStrings
}

func filterStringByAddress(originalStrings: [String]) -> [String] {
    var processedStrings: [String] = []
    
    for str in originalStrings{
        if (usingDataDetector(input: str, type: [.address])){
            processedStrings.append(str)
        }
    }
    return processedStrings
}

func filterStringByEmail(originalStrings: [String]) -> [String] {
    var processedStrings: [String] = []
    
    for str in originalStrings{
        if (usingMLkit(input: str, expectType: "email")){
            processedStrings.append(str)
        }
    }
    return processedStrings
}




func usingDataDetector(input: String, type: NSTextCheckingResult.CheckingType) -> Bool {
    let types: NSTextCheckingResult.CheckingType = type
    let detector = try? NSDataDetector(types:types.rawValue)
    
    let range = NSMakeRange(0, input.utf16.count)
    let matches = detector?.matches(in: input, options: NSRegularExpression.MatchingOptions(rawValue: 0), range:range)
    if let matches = matches {
        if (matches.count != 0){
            return true
        }
        return false
    }
    return false
}


let options = EntityExtractorOptions(modelIdentifier:
                                    EntityExtractionModelIdentifier.english)
let entityExtractor = EntityExtractor.entityExtractor(options: options)


func usingMLkit(input:String, expectType:String) -> Bool {
    var actualType = ""
    entityExtractor.downloadModelIfNeeded(completion: { _ in
        return
    })
    var params = EntityExtractionParams()
    // The params object contains the following properties which can be customized on
    // each annotateText: call. Please see the class's documentation for a more
    // detailed description of what each property represents.
    params.referenceTime = Date();
    params.referenceTimeZone = TimeZone(identifier: "GMT");
    params.preferredLocale = Locale(identifier: "en-US");
    params.typesFilter = Set([EntityType.address, EntityType.dateTime])
    

    entityExtractor.annotateText(
        input,
        params: params,
        completion: {
        
          result, error in
            guard let result = result else {
              return
            }
          // If the error is nil, the annotation completed successfully and any results
          // will be contained in the `result` array.
            
            for annotation in result {
                let entities = annotation.entities
                  for entity in entities {
                    switch entity.entityType {
                      case EntityType.dateTime:
                        actualType = "date"
                      case EntityType.flightNumber:
                        actualType = "flight"
                      case EntityType.URL:
                        actualType = "url"
                      case EntityType.phone:
                        actualType = "phone"
                      case EntityType.email:
                        actualType = "email"
                      default:
                        print("Entity: %@", entity);
                    }
                  }
            }
        }
    )
    
    if (expectType == actualType){
        return true
    }
    else{
        return false
    }
}


