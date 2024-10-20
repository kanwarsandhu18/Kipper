//
//  SpeechRec.swift
//  Kipper
//
//  Created by Kanwar Sandhu on 2024-10-13.
//

import Foundation
import AVFoundation
import Speech

class SpeechRecognizer {
    let audioEngine = AVAudioEngine()
    let speechRecognizer = SFSpeechRecognizer()
    let request = SFSpeechAudioBufferRecognitionRequest()
    var recognitionTask: SFSpeechRecognitionTask?

    func startRecognition(completion: @escaping (String) -> Void) {
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session properties weren't set due to an error.")
        }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.request.append(buffer)
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
        } catch {
            print("AudioEngine couldn't start because of an error.")
        }

        recognitionTask = speechRecognizer?.recognitionTask(with: request, resultHandler: { result, error in
            if let result = result {
                // Send the recognized text back via the completion handler
                completion(result.bestTranscription.formattedString)
            } else if let error = error {
                print("Speech recognition error: \(error.localizedDescription)")
                completion("Error recognizing speech")
            }
        })
    }

    func stopRecognition() {
        recognitionTask?.finish()
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
    }
}
