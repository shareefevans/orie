//
//  FoodInputField.swift
//  orie
//
//  Created by Shareef Evans on 26/11/2025.
//

import SwiftUI
#if os(iOS)
import Speech
import AVFoundation
#endif

struct FoodInputField: View {
    @Binding var text: String
    var onSubmit: (String) -> Void
    @FocusState.Binding var isFocused: Bool

    #if os(iOS)
    @State private var isRecording = false
    @State private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State private var audioEngine = AVAudioEngine()
    #endif

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Text("\(currentTime())")
                .font(.system(size: 14))
                .foregroundColor(.yellow)
                .frame(width: 90, alignment: .leading)

            TextField("Tap to Enter...", text: $text, axis: .vertical)
                .font(.system(size: 15))
                .lineLimit(1...5)
                .focused($isFocused)
                .onChange(of: text) { oldValue, newValue in
                    if newValue.contains("\n") {
                        let trimmed = newValue.replacingOccurrences(of: "\n", with: "")
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        text = ""
                        if !trimmed.isEmpty {
                            onSubmit(trimmed)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isFocused = true
                            }
                        }
                    }
                }

            Spacer()

            #if os(iOS)
            // Voice-to-text button
            Button(action: {
                if isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            }) {
                Image(systemName: isRecording ? "waveform.circle.fill" : "waveform")
                    .font(.system(size: 14))
                    .foregroundColor(isRecording ? .white : .gray)
                    .frame(width: 32, height: 32)
                    .background(isRecording ? Color.yellow : Color(white: 0.9))
                    .clipShape(Circle())
                    .scaleEffect(isRecording ? 1.1 : 1.0)
                    .animation(
                        isRecording ? Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true) : .default,
                        value: isRecording
                    )
            }
            .buttonStyle(BorderlessButtonStyle())
            .contentShape(Circle())
            #endif
        }
        .padding(.vertical, 12)
    }

    private func currentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mma"
        return formatter.string(from: Date()).lowercased()
    }

    #if os(iOS)
    private func startRecording() {
        // Request authorization
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    self.beginRecordingSession()
                default:
                    print("Speech recognition not authorized")
                }
            }
        }
    }

    private func beginRecordingSession() {
        // Cancel any ongoing task
        recognitionTask?.cancel()
        recognitionTask = nil

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session setup failed: \(error)")
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        let inputNode = audioEngine.inputNode

        guard let recognitionRequest = recognitionRequest else {
            print("Unable to create recognition request")
            return
        }

        recognitionRequest.shouldReportPartialResults = true

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                DispatchQueue.main.async {
                    self.text = result.bestTranscription.formattedString
                }
            }

            if error != nil || (result?.isFinal ?? false) {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                DispatchQueue.main.async {
                    self.isRecording = false
                }
            }
        }

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
            isRecording = true
        } catch {
            print("Audio engine failed to start: \(error)")
        }
    }

    private func stopRecording() {
        // Stop the audio engine first
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)

        // Cancel the recognition task to prevent further text updates
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil

        isRecording = false

        // Submit the text if not empty
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            onSubmit(trimmed)
        }

        // Clear text after submission
        text = ""
    }
    #endif
}
