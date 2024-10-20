import SwiftUI
import RealityKit
import RealityKitContent
import Speech // For speech recognition
import AVFoundation

struct ContentView: View {

    @State private var showImmersiveSpace = false
    @State private var immersiveSpaceIsShown = false
    @State private var recognizedText = "What can I help with?"
    @State private var chatbotResponse = ""
    
    @State private var isAuthorized = false // Track if permissions are granted
    @State private var isListening = false // Track if listening is active

    @State private var displayedWords: [String] = [] // Store the words to be displayed
    @State private var wordsToAnimate: [String] = [] // Store the OpenAI response words for animation

    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace

    let speechRecognizer = SpeechRecognizer()

    var body: some View {
        VStack {
            Image("appTop")
                .resizable()
                .frame(width: 200, height: 200)
                .clipShape(Circle())
                .padding(.vertical, 50)
            VStack{
                Text(recognizedText)
                    .font(.system(size: 30))
                    .padding()
                Text(displayedWords.joined(separator: " "))
                    .font(.system(size: 36))
                // Align the text to the left
                    .padding()
                    .onChange(of: wordsToAnimate) { newWords in
                        fadeInWords(newWords)
                    }
            }
            .frame(maxHeight: .infinity)

            if !isListening {
                Button(action: {
                    // Request permissions and start listening if authorized
                    requestPermissions {
                        if isAuthorized {
                            startListening()
                        } else {
                            recognizedText = "Permissions not granted"
                        }
                    }
                }) {
                    Image(systemName: "mic.fill")  // SF Symbols microphone icon
                        .font(.system(size: 40))  // Adjust the size of the icon
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(Circle())  // Make the button circular like a mic button
                }
                
            } else {
                Button(action: {
                    stopListening()
                }) {
                    Text("Stop Listening")
                        .font(.title)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }

            Toggle("Show ImmersiveSpace", isOn: $showImmersiveSpace)
                .font(.title)
                .frame(width: 360)
                .padding(24)
                .glassBackgroundEffect()
        }
        .padding()
        .onChange(of: showImmersiveSpace) { _, newValue in
            Task {
                if newValue {
                    switch await openImmersiveSpace(id: "ImmersiveSpace") {
                    case .opened:
                        immersiveSpaceIsShown = true
                    case .error, .userCancelled:
                        immersiveSpaceIsShown = false
                        showImmersiveSpace = false
                    @unknown default:
                        immersiveSpaceIsShown = false
                        showImmersiveSpace = false
                    }
                } else if immersiveSpaceIsShown {
                    await dismissImmersiveSpace()
                    immersiveSpaceIsShown = false
                }
            }
        }
    }

    // Request permissions for speech and microphone
    func requestPermissions(completion: @escaping () -> Void) {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    print("Speech recognition authorized.")
                    checkMicrophonePermission {
                        completion()
                    }
                case .denied, .restricted, .notDetermined:
                    print("Speech recognition permission denied.")
                    isAuthorized = false
                    completion()
                @unknown default:
                    isAuthorized = false
                    completion()
                }
            }
        }
    }

    // Check microphone permission
    func checkMicrophonePermission(completion: @escaping () -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if granted {
                    print("Microphone access granted.")
                    isAuthorized = true
                } else {
                    print("Microphone access denied.")
                    isAuthorized = false
                }
                completion()
            }
        }
    }

    // Start listening for speech input
    func startListening() {
        isListening = true
        recognizedText = "Listening..."
        speechRecognizer.startRecognition { text in
            recognizedText = text
        }
    }

    // Stop listening and send the recognized text to OpenAI
    func stopListening() {
        speechRecognizer.stopRecognition()
        isListening = false
        sendToOpenAI(prompt: recognizedText) { response in
            chatbotResponse = response ?? "No response"
            if let response = response {
                self.wordsToAnimate = response.split(separator: " ").map { String($0) }
                self.displayedWords = []
                speakResponse(response)
            }
        }
    }

    func sendToOpenAI(prompt: String, completion: @escaping (String?) -> Void) {
        let apiKey = "Your openai api key here"

        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [["role": "user", "content": prompt]]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                completion(nil)
                return
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let message = choices.first?["message"] as? [String: Any],
               let content = message["content"] as? String {
                completion(content)
            } else {
                completion(nil)
            }
        }
        
        task.resume()
    }

    // Animate words with delay
    func fadeInWords(_ words: [String]) {
        DispatchQueue.main.async {
            for (index, word) in words.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.2) {
                    withAnimation {
                        self.displayedWords.append(word)
                    }
                }
            }
        }
    }
    let synthesizer = AVSpeechSynthesizer()
    // Text-to-Speech function
    func speakResponse(_ response: String) {
        let utterance = AVSpeechUtterance(string: response)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        
        // Setup the audio session
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session category: \(error)")
        }

        // Stop current speech and speak the new response
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        synthesizer.speak(utterance)
    }

}

#Preview(windowStyle: .automatic) {
    ContentView()
}






