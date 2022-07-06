//
//  AudioUtils.swift
//  BreakfastFinder
//
//  Created by Andi Xu on 7/5/22.
//  Copyright © 2022 Apple. All rights reserved.
//

import Foundation
import AVFoundation

struct lastAnnouncedTime{
    var notOnScreen:Int64 = -1
    var willDisappear:Int64 = -1
    var disappeared:Int64 = -1
    var fiveOther:Int64 = -1
    var detectedStr:Int64 = -1
}

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
    
    var sound: AVAudioPlayer?
    var announcedTime=lastAnnouncedTime()
    
    var foundObject=Set<String>()
    
    func findNewThings(findings: Set<String>){
        let newThings = findings.subtracting(foundObject)
        speak(str: "no bus on screen. instead, find")
        newThings.forEach(speak(str:))
        foundObject=findings
    }
    
    func speak(str: String){
        let utterance = AVSpeechUtterance(string: str)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
    }
    
    func announceStatus(){
        switch status{
            case Status.disappearing:
                objectWillDisappear()
            case Status.notFound:
                playMusic_NoObject()
            case Status.disappeared:
                objectDisappear()
            case Status.onScreen:
                objectOnScreen()
        }
    }
    
    func objectOnScreen(){
        stopPlayMusic()
        speak(str: "Found on screen")
    }
    func objectWillDisappear(){
        speak(str: "Will disappear")
    }
    
    func playMusic_NoObject(){
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
        playMusic_NoObject()
    }
    
    func speakContext(str:String?){
        if str == nil {return}
        sound?.pause()
        speak(str: "i can see \(str!) on screen")
        sound?.play()
    }
    
    
    
    
    func stopPlayMusic(){
        if let isplaying=sound?.isPlaying {
            if isplaying {
                sound?.pause()
            }
        }
    }
    
}
