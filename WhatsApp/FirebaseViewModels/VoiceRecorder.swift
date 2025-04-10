//
//  VoiceRecorder.swift
//  WhatsApp
//
//  Created by Abhinava Krishna on 10/04/25.
//
import SwiftUI
import AVFoundation
extension FireMessageViewModel {
    
    @Observable
    final class VoiceRecorder: NSObject, AVAudioRecorderDelegate {
        var audioRecorder: AVAudioRecorder?
        var isRecording = false
        var recordingURL: URL?
        var permissionGranted = false
        
        override init() {
            super.init()
            checkMicrophonePermission()
        }
        
        func checkMicrophonePermission() {
            switch AVAudioApplication.shared.recordPermission {
            case .granted:
                print("Microphone permission already granted")
                permissionGranted = true
            case .denied:
                print("Microphone permission denied")
                permissionGranted = false
            case .undetermined:
                AVAudioApplication.requestRecordPermission { [weak self] allowed in
                    DispatchQueue.main.async {
                        self?.permissionGranted = allowed
                        print("Microphone permission \(allowed ? "granted" : "denied")")
                    }
                }
            @unknown default:
                permissionGranted = false
            }
        }
        
        func startRecording() {
            let audioSession = AVAudioSession.sharedInstance()
            
            do {
                try audioSession.setCategory(.playAndRecord, mode: .default)
                try audioSession.setActive(true)
                
                // Create a temporary file URL for recording
                let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let audioFilename = documentPath.appendingPathComponent("\(UUID().uuidString).m4a")
                recordingURL = audioFilename
                
                // Recording settings
                let settings = [
                    AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                    AVSampleRateKey: 44100,
                    AVNumberOfChannelsKey: 2,
                    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                ]
                
                // Create and prepare the recorder
                audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
                audioRecorder?.delegate = self
                audioRecorder?.prepareToRecord()
                audioRecorder?.record()
                
                isRecording = true
                print("Voice recording started ----------- ✅ ----------")
            } catch {
                print("Failed to set up recording session ----------- ❌ ----------: \(error.localizedDescription)")
            }
        }
        
        func stopRecording() -> URL? {
            audioRecorder?.stop()
            isRecording = false
            print("Voice recording stopped ----------- ✅ ----------")
            return recordingURL
        }
        
        func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
            if !flag {
                print("Recording failed ----------- ❌ ----------")
                recordingURL = nil
            }
        }
    }
}
