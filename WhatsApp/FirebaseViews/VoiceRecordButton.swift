import SwiftUI

struct VoiceRecordButton: View {
    @State private var isRecording = false
    @State private var recordingStartTime: Date?
    @State private var showConfirmation = false
    @State private var recordingDuration: TimeInterval = 0
    @State private var pulseAnimation = false // Animation state

    let voiceRecorder = FireMessageViewModel.VoiceRecorder()
    var onVoiceRecorded: (URL, TimeInterval) -> Void

    var body: some View {
        ZStack {
            // Pulsating Circle Animation
            Circle()
                .fill(isRecording ? Color.red.opacity(0.5) : Color.clear)
                .frame(width: pulseAnimation ? 70 : 50, height: pulseAnimation ? 70 : 50)
                .animation(isRecording ? .easeInOut(duration: 0.8).repeatForever() : .default, value: pulseAnimation)

            // Main Button Circle
            Circle()
                .fill(isRecording ? Color.red : Color.blue)
                .frame(width: 30, height: 30)

            // Button Icon
            Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                .foregroundColor(.white)
                .font(.system(size: 12))
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isRecording {
                        startRecording()
                    }
                }
                .onEnded { _ in
                    if isRecording {
                        stopRecording()
                    }
                }
        )
        .alert("Send Voice Message?", isPresented: $showConfirmation) {
            Button("Send") {
                if let url = voiceRecorder.recordingURL {
                    onVoiceRecorded(url, recordingDuration)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Voice message recorded (\(Int(recordingDuration)) seconds)")
        }
    }

    private func startRecording() {
        voiceRecorder.startRecording()
        isRecording = true
        recordingStartTime = Date()
        pulseAnimation = true 
    }

    private func stopRecording() {
        if let _ = voiceRecorder.stopRecording(),
           let startTime = recordingStartTime {
            recordingDuration = Date().timeIntervalSince(startTime)
            isRecording = false
            pulseAnimation = false
            showConfirmation = true
        }
    }
}
