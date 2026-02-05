import SwiftUI
import SilenceKit
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var processor = AudioProcessor()
    @State private var showFilePicker = false
    @State private var fileName: String?
    
    var body: some View {
        NavigationStack {
            Form {
                // File Selection
                Section {
                    Button {
                        showFilePicker = true
                    } label: {
                        HStack {
                            Image(systemName: "doc.badge.plus")
                            Text(fileName ?? "Select Audio File")
                                .foregroundStyle(fileName == nil ? .secondary : .primary)
                        }
                    }
                } header: {
                    Text("Audio File")
                }
                
                // Playback Controls
                if fileName != nil {
                    Section {
                        // Progress
                        VStack(alignment: .leading, spacing: 8) {
                            ProgressView(value: processor.duration > 0 ? processor.currentTime / processor.duration : 0)
                                .tint(.blue)
                            
                            HStack {
                                Text(formatTime(processor.currentTime))
                                    .monospacedDigit()
                                Spacer()
                                Text(formatTime(processor.duration))
                                    .monospacedDigit()
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        
                        // Controls
                        HStack(spacing: 24) {
                            Spacer()
                            
                            Button {
                                processor.seek(to: max(0, processor.currentTime - 15))
                            } label: {
                                Image(systemName: "gobackward.15")
                                    .font(.title2)
                            }
                            
                            Button {
                                if processor.isPlaying {
                                    processor.pause()
                                } else {
                                    processor.play()
                                }
                            } label: {
                                Image(systemName: processor.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.system(size: 48))
                            }
                            
                            Button {
                                processor.seek(to: min(processor.duration, processor.currentTime + 30))
                            } label: {
                                Image(systemName: "goforward.30")
                                    .font(.title2)
                            }
                            
                            Spacer()
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.blue)
                    } header: {
                        Text("Playback")
                    }
                    
                    // Trim Silence
                    Section {
                        Picker("Level", selection: $processor.trimSilenceLevel) {
                            ForEach(TrimSilenceLevel.allCases, id: \.self) { level in
                                Text(level.displayName).tag(level)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        if processor.timeSavedByTrimming > 0 {
                            HStack {
                                Image(systemName: "clock.badge.checkmark")
                                    .foregroundStyle(.green)
                                Text("Time saved: \(formatTime(processor.timeSavedByTrimming))")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } header: {
                        Text("Trim Silence")
                    } footer: {
                        Text("Removes silent portions to speed up listening")
                    }
                    
                    // Speed
                    Section {
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Speed")
                                Spacer()
                                Text("\(processor.playbackSpeed, specifier: "%.1f")x")
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                            }
                            
                            Slider(value: $processor.playbackSpeed, in: 0.5...3.0, step: 0.1)
                        }
                        
                        HStack {
                            ForEach([0.5, 1.0, 1.5, 2.0], id: \.self) { speed in
                                Button("\(speed, specifier: "%.1f")x") {
                                    processor.playbackSpeed = Float(speed)
                                }
                                .buttonStyle(.bordered)
                                .tint(processor.playbackSpeed == Float(speed) ? .blue : .gray)
                                
                                if speed != 2.0 { Spacer() }
                            }
                        }
                    } header: {
                        Text("Playback Speed")
                    }
                    
                    // Volume
                    Section {
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Volume Boost")
                                Spacer()
                                Text("\(processor.volumeBoost, specifier: "%.1f")x")
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                            }
                            
                            Slider(value: $processor.volumeBoost, in: 0.5...3.0, step: 0.1)
                        }
                    } header: {
                        Text("Volume")
                    } footer: {
                        Text("Amplify quiet audio without distortion")
                    }
                }
            }
            .navigationTitle("SilenceKit Demo")
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.audio, .mp3, .mpeg4Audio, .wav, .aiff],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        loadFile(url)
                    }
                case .failure(let error):
                    print("File picker error: \(error)")
                }
            }
        }
    }
    
    private func loadFile(_ url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            try processor.loadFile(url: url)
            fileName = url.lastPathComponent
        } catch {
            print("Failed to load file: \(error)")
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    ContentView()
}
