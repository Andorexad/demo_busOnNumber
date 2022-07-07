//
//  AudioUtils.swift
//  BreakfastFinder
//
//  Created by Andi Xu on 7/5/22.
//  Copyright © 2022 Apple. All rights reserved.
//

import Foundation
import AVFoundation
//
//struct lastAnnouncedTime{
//    var notOnScreen:Int64 = -1
//    var willDisappear:Int64 = -1
//    var disappeared:Int64 = -1
//    var fiveOther:Int64 = -1
//    var detectedStr:Int64 = -1
//}

enum Status{
    case notFound
    case disappeared
    case onScreen
    case disappearing
}

class AudioTracker{
    
    // initial state: not found
    var status=Status.notFound {
        didSet{
            announceStatus()
        }
    }
   
    
    let synthesizer = AVSpeechSynthesizer()
    let audioSession = AVAudioSession.sharedInstance()
    
    init() {
        try! audioSession.setCategory(
            AVAudioSession.Category.playback,
            options: AVAudioSession.CategoryOptions.mixWithOthers
        )
        playMusic_NoObject()
//        resetContext()
    }
    
    var sound: AVAudioPlayer?
    
    var foundObject=Set<String>()
    
//    func speakContext_onlyNewThings(findings: Set<String>){
//        let newThings = findings.subtracting(foundObject)
//        if newThings.isEmpty {
//            return
//        }
//        speak(str: "i see")
//        newThings.forEach(speak(str:))
//        speak(str: "on screen")
//        foundObject=findings
//    }
    func setStatus(newstatus:Status){
        if self.status != newstatus{
            self.status = newstatus
        }
    }
    func resetContext(){
        if foundObject.isEmpty{return}
        speak(str: "i see")
        foundObject.forEach(speak(str:))
        foundObject.removeAll()
    }
    
    func speak(str: String){
        
        let utterance = AVSpeechUtterance(string: str)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
//        utterance.volume = 1
        
        synthesizer.speak(utterance)
    }
    
    func announceStatus(){
        switch status{
            case Status.disappearing:
                return
            case Status.notFound:
                playMusic_NoObject()
            case Status.disappeared:
                objectDisappear()
            case Status.onScreen:
                objectOnScreen()
        }
    }
    
    func objectOnScreen(){
        sound?.pause()
        synthesizer.stopSpeaking(at: .immediate)
        foundObject.removeAll()
        speak(str: "Found on screen")
    }
    
    func playMusic_NoObject(){
        if status != Status.notFound && status != Status.disappeared{
            return
        }
        if sound != nil {
            if !(sound!.isPlaying){
                sound?.play()
            }
            return
        }
        
        let path = Bundle.main.path(forResource: "noBusFound.mp3", ofType:nil)!
        let url = URL(fileURLWithPath: path)
        
        do {
            sound = try AVAudioPlayer(contentsOf: url)
            
            sound?.play()
        } catch {
            print("can't play music", error.localizedDescription)
        }
    }
    
    func objectDisappear(){
        speak(str:"bus disappeared")
        sound?.play()
    }
    
    func stopAllSound(){
        synthesizer.stopSpeaking(at: .immediate)
        sound?.stop()
    }
    
//    func speakContext(str:String?){
//        if str == nil {return}
//        sound?.pause()
//        speak(str: "i can see \(str!) on screen")
//        sound?.play()
//    }
    
}
