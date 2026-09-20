import SwiftUI
import AVFoundation
import Speech
import Translation

struct VideoTranslatorView: View {
    @State private var transcribedText: String = ""
    @State private var translatedText: String = ""
    @State private var isProcessing: Bool = false
    @State private var translationSession: TranslationSession?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Traductor Local")
                .font(.title)
                .bold()
            
            if isProcessing {
                ProgressView("Procesando en el dispositivo...")
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Texto Original (Inglés):").font(.headline)
                    Text(transcribedText.isEmpty ? "Esperando..." : transcribedText)
                        .foregroundColor(.gray)
                    
                    Divider()
                    
                    Text("Traducción (Español):").font(.headline)
                    Text(translatedText.isEmpty ? "Esperando..." : translatedText)
                        .foregroundColor(.blue)
                }
                .padding()
            }
            
            Button("Traducir Video de Ejemplo") {
                if let videoURL = Bundle.main.url(forResource: "video_ejemplo", withExtension: "mp4") {
                    startTranslationPipeline(videoURL: videoURL)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isProcessing)
        }
        .padding()
        .translationTask(source: Locale.Language(identifier: "en-US"), 
                         target: Locale.Language(identifier: "es-ES")) { session in
            self.translationSession = session
        }
    }
    
    func startTranslationPipeline(videoURL: URL) {
        isProcessing = true
        transcribedText = ""
        translatedText = ""
        
        transcribeAudio(from: videoURL) { resultText in
            DispatchQueue.main.async {
                self.transcribedText = resultText
                Task { await translateToSpanish(text: resultText) }
            }
        }
    }
    
    func transcribeAudio(from url: URL, completion: @escaping (String) -> Void) {
        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.requiresOnDeviceRecognition = true 
        
        recognizer?.recognitionTask(with: request) { result, error in
            guard let result = result else {
                isProcessing = false
                return
            }
            if result.isFinal {
                completion(result.bestTranscription.formattedString)
            }
        }
    }
    
    func translateToSpanish(text: String) async {
        guard let session = translationSession else {
            isProcessing = false
            return
        }
        do {
            let response = try await session.translate(text)
            DispatchQueue.main.async {
                self.translatedText = response.targetText
                self.isProcessing = false
            }
        } catch {
            DispatchQueue.main.async { self.isProcessing = false }
        }
    }
}
