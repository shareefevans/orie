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
import UIKit
#endif

struct FoodInputField: View {
    @Binding var text: String
    var isDark: Bool = false
    var onSubmit: (String) -> Void
    var onImageAnalyzed: ((APIService.ImageAnalysisResponse) -> Void)?
    @FocusState.Binding var isFocused: Bool
    var authManager: AuthManager? = nil

    #if os(iOS)
    @State private var isRecording = false
    @State private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State private var audioEngine = AVAudioEngine()
    @State private var showCameraPicker = false
    @State private var isAnalyzingImage = false

    // Autocomplete state
    @State private var autocompleteSuggestion: String? = nil
    @State private var autocompleteTask: Task<Void, Never>? = nil
    #endif

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Text("\(currentTime())")
                .font(.system(size: 14))
                .foregroundColor(Color.accessibleYellow(isDark))
                .frame(width: 90, alignment: .leading)

            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text("Tap to Enter...")
                        .font(.system(size: 15))
                        .foregroundColor(Color.placeholderText(isDark))
                        .offset(x: -8)
                }
                TextField("", text: $text, axis: .vertical)
                    .font(.system(size: 15))
                    .foregroundColor(Color.primaryText(isDark))
                    .lineLimit(1...5)
                    .focused($isFocused)
                    .offset(x: -8)
                    #if os(iOS)
                    .autocorrectionDisabled(false)
                    .textInputAutocapitalization(.never)
                    #endif
                    .onChange(of: text) { oldValue, newValue in
                        if newValue.contains("\n") {
                            let trimmed = newValue.replacingOccurrences(of: "\n", with: "")
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                            text = ""
                            #if os(iOS)
                            autocompleteSuggestion = nil
                            #endif
                            if !trimmed.isEmpty {
                                onSubmit(trimmed)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    isFocused = true
                                }
                            }
                        } else {
                            #if os(iOS)
                            fetchAutocompleteSuggestion(for: newValue)
                            #endif
                        }
                    }
                    #if os(iOS)
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            if let suggestion = autocompleteSuggestion {
                                Button {
                                    selectSuggestion(suggestion)
                                } label: {
                                    Text(suggestion)
                                        .font(.system(size: 14))
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .padding(.horizontal, 16)
                                }
                                .buttonStyle(.plain)
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    #endif
            }

            Spacer()

            #if os(iOS)
            if !isFocused || isRecording || isAnalyzingImage {
                HStack(spacing: 8) {
                    // MARK: 👉 Camera button
                    Button(action: {
                        showCameraPicker = true
                    }) {
                        ZStack {
                            Image(systemName: "camera.macro")
                                .font(.system(size: 14))
                                .foregroundColor(isAnalyzingImage ? .clear : Color.secondaryText(isDark))
                                .frame(width: 44, height: 44)
                                .background(isAnalyzingImage ? Color.yellow : (isDark ? Color(red: 0.2, green: 0.2, blue: 0.2) : Color(red: 0.933, green: 0.933, blue: 0.933)))
                                .clipShape(Circle())

                            if isAnalyzingImage {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: isDark ? .black : .white))
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .contentShape(Circle())
                    .disabled(isAnalyzingImage)

                    // MARK: 👉 Voice-to-text button
                    Button(action: {
                        if isRecording {
                            stopRecording()
                        } else {
                            startRecording()
                        }
                    }) {
                        Image(systemName: isRecording ? "waveform.circle.fill" : "waveform")
                            .font(.system(size: 14))
                            .foregroundColor(isRecording ? (isDark ? .black : .white) : Color.secondaryText(isDark))
                            .frame(width: 44, height: 44)
                            .background(isRecording ? Color.yellow : (isDark ? Color(red: 0.2, green: 0.2, blue: 0.2) : Color(red: 0.933, green: 0.933, blue: 0.933)))
                            .clipShape(Circle())
                            .scaleEffect(isRecording ? 1.1 : 1.0)
                            .animation(
                                isRecording ? Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true) : .default,
                                value: isRecording
                            )
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .contentShape(Circle())
                }
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
            #endif
        }
        .frame(minHeight: 44)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .padding(.vertical, 12)
        #if os(iOS)
        .sheet(isPresented: $showCameraPicker) {
            ImagePicker(sourceType: .camera) { image in
                handleCapturedImage(image)
            }
            .ignoresSafeArea()
        }
        #endif
    }

    // MARK: - ❇️ Functions
    #if os(iOS)
    private func handleCapturedImage(_ image: UIImage) {
        isAnalyzingImage = true

        Task {
            do {
                // Convert image to base64
                guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                    await MainActor.run { isAnalyzingImage = false }
                    return
                }
                let base64String = imageData.base64EncodedString()

                // Call the API
                let result = try await APIService.analyzeImageWithNutrition(imageBase64: base64String)

                await MainActor.run {
                    isAnalyzingImage = false
                    onImageAnalyzed?(result)
                }
            } catch {
                print("Error analyzing image: \(error)")
                await MainActor.run {
                    isAnalyzingImage = false
                }
            }
        }
    }
    #endif

    private func currentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mma"
        return formatter.string(from: Date()).lowercased()
    }

    #if os(iOS)
    private func fetchAutocompleteSuggestion(for input: String) {
        // Cancel any existing task
        autocompleteTask?.cancel()

        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

        // Clear suggestion if input is too short or no auth manager
        guard trimmed.count >= 2, let authManager = authManager else {
            autocompleteSuggestion = nil
            return
        }

        // Debounce: wait 300ms before fetching
        autocompleteTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)

            guard !Task.isCancelled else { return }

            do {
                let suggestions = try await authManager.withAuthRetry { accessToken in
                    try await FoodHistoryService.getAutocompleteSuggestions(
                        accessToken: accessToken,
                        partialName: trimmed,
                        limit: 1
                    )
                }

                guard !Task.isCancelled else { return }

                await MainActor.run {
                    autocompleteSuggestion = suggestions.first
                }
            } catch {
                // Silently fail - autocomplete is a nice-to-have
                await MainActor.run {
                    autocompleteSuggestion = nil
                }
            }
        }
    }

    private func selectSuggestion(_ suggestion: String) {
        // Cancel any pending autocomplete task first
        autocompleteTask?.cancel()
        autocompleteTask = nil

        // Clear state before submitting
        autocompleteSuggestion = nil
        let suggestionToSubmit = suggestion

        // Clear the text field
        text = ""

        // Submit the suggestion
        onSubmit(suggestionToSubmit)

        // Refocus for next entry
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isFocused = true
        }
    }
    #endif

    #if os(iOS)
    private func startRecording() {
        // MARK: 👉 Request authorization
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
        // MARK: 👉 Cancel any ongoing task
        recognitionTask?.cancel()
        recognitionTask = nil

        // MARK: 👉 Configure audio session
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
        // MARK: 👉 Stop the audio engine first
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)

        // MARK: 👉 Cancel the recognition task to prevent further text updates
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

#if os(iOS)
struct ImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onImageCaptured: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImageCaptured(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
#endif
