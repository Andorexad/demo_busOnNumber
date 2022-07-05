//
//  StringUtils.swift
//  BreakfastFinder
//
//  Created by Andi Xu on 7/1/22.
//  Copyright © 2022 Apple. All rights reserved.
//

import Foundation
import UIKit
import Vision
import AVFoundation

// announceType: lastAnnouncedFrame
struct AudioTracker {
    var disappeared:Int64
    var noOnScreen:Int64
    var willDisappear:Int64
    var fiveOther:Int64
    var detectedStr:Int64
}

@available(iOS 13.0, *)
class StringTracker {
    var frameIndex: Int64 = 0
    typealias StringObservation = (lastSeen: Int64, count: Int64)
    
    // Dictionary of seen strings. Used to get stable recognition before displaying anything.
    var seenStrings = [String: StringObservation]()
    var bestCount = Int64(0)
    var bestString = ""
    var bestStringFrame = Int64(0)
    
    var lastSpeakFrame = Int64(0)
    var lastSpeakString = ""
    
    var audiotracker=AudioTracker(disappeared: -1,noOnScreen: -1,willDisappear: -1,fiveOther: -1,detectedStr: -1)
    

    func logFrame(results: [String]) {
        for result in results {
            var removedString = result
            removedString.unicodeScalars.removeAll(where: { NSCharacterSet.punctuationCharacters.contains($0) })
            
            if seenStrings[removedString] == nil {
                seenStrings[removedString] = (lastSeen: Int64(0), count: Int64(-1))
            }
            seenStrings[removedString]?.lastSeen = frameIndex
            seenStrings[removedString]?.count += 1
        }
    
        var obsoleteStrings = [String]()

        for (string, obs) in seenStrings {
            if obs.lastSeen < frameIndex - 60 {
                obsoleteStrings.append(string)
            }
            
            let count = obs.count
            if !obsoleteStrings.contains(string) && count > bestCount {
                bestCount = Int64(count)
                bestString = string
                bestStringFrame = frameIndex
            }
        }
        for string in obsoleteStrings {
            seenStrings.removeValue(forKey: string)
        }
        frameIndex += 1
    }
    
    func getStableString() -> String? {
        if bestCount >= 8 {
            return bestString
        } else {
            return nil
        }
    }
    
    func reset(string: String) {
        seenStrings.removeValue(forKey: string)
        bestCount = 0
        bestString = ""
        bestStringFrame = 0
    }
    
    func recognizeTextFinish(results:[String]) {
        print(results)
        logFrame(results: results)
        
        if let stable = getStableString() {
            if (stable == lastSpeakString && lastSpeakFrame < bestStringFrame-(30*5)) || (stable != lastSpeakString && lastSpeakFrame < bestStringFrame-(30*3))  || lastSpeakFrame==0 {
                speakAndReset(stableString: stable)
            }
            
        }

    }
    
    func speakAndReset(stableString: String){
        playSound(str: stableString)
        lastSpeakString=stableString
        lastSpeakFrame=bestStringFrame
        reset(string: stableString)
        print("speak",stableString)
    }
    
    func playSound( str: String ){
        let utterance = AVSpeechUtterance(string: str)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
    }
}
