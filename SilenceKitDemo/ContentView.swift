import SwiftUI
import SilenceKit
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var processor = AudioProcessor()
    @State private var showFilePicker = false
    @State private var fileName: String?
    @State private var trimEnabled = true
    @State private var volumeBoostEnabled = false
    @State private var speedEnabled = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // File Selection Card
                    fileSelectionCard
                    
                    if fileName != nil {
                        // Playback Card
                        playbackCard
                        
                        // Trim Silence Card
                        trimSilenceCard
                        
                        // Playback Speed Card
                        playbackSpeedCard
                        
                        // Volume Boost Card
                        volumeBoostCard
                        
                        // Statistics Card
                        statisticsCard
                        
                        // Reset Button
                        resetButton
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("SilenceKit Demo")
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.audio, .mp3, .mpeg4Audio, .wav, .aiff],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    loadFile(url)
                }
            }
        }
    }
    
    // MARK: - File Selection Card
    
    private var fileSelectionCard: some View {
        VStack(spacing: 12) {
            Image(systemName: fileName == nil ? "waveform.circle" : "waveform.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(fileName == nil ? Color.secondary : Color.blue)
            
            if let fileName = fileName {
                Text(fileName)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(formatTime(processor.duration))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Button {
                showFilePicker = true
            } label: {
                Label(fileName == nil ? "Select Audio File" : "Change File", 
                      systemImage: "folder.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Playback Card
    
    private var playbackCard: some View {
        VStack(spacing: 16) {
            // Progress Bar
            VStack(spacing: 4) {
                ProgressView(value: processor.duration > 0 ? processor.currentTime / processor.duration : 0)
                    .tint(.blue)
                
                HStack {
                    Text(formatTime(processor.currentTime))
                    Spacer()
                    Text("-\(formatTime(processor.duration - processor.currentTime))")
                }
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(.secondary)
            }
            
            // Playback Controls
            HStack(spacing: 32) {
                Button {
                    processor.seek(to: max(0, processor.currentTime - 15))
                } label: {
                    Image(systemName: "gobackward.15")
                        .font(.title)
                }
                
                Button {
                    if processor.isPlaying {
                        processor.pause()
                    } else {
                        processor.play()
                    }
                } label: {
                    Image(systemName: processor.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 64))
                }
                
                Button {
                    processor.seek(to: min(processor.duration, processor.currentTime + 30))
                } label: {
                    Image(systemName: "goforward.30")
                        .font(.title)
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(.blue)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Trim Silence Card
    
    private var trimSilenceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "waveform.path")
                    .foregroundStyle(.orange)
                Text("Trim Silence")
                    .font(.headline)
                Spacer()
                Toggle("", isOn: $trimEnabled)
                    .labelsHidden()
                    .onChange(of: trimEnabled) { _, newValue in
                        processor.trimSilenceLevel = newValue ? .medium : .off
                    }
            }
            
            if trimEnabled {
                // Level Picker
                Picker("Level", selection: $processor.trimSilenceLevel) {
                    ForEach(TrimSilenceLevel.allCases.filter { $0 != .off }, id: \.self) { level in
                        Text(level.displayName).tag(level)
                    }
                }
                .pickerStyle(.segmented)
                
                // Level Description
                Text(trimLevelDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                // Technical Details
                VStack(alignment: .leading, spacing: 4) {
                    DetailRow(label: "RMS Threshold", value: String(format: "%.4f", processor.trimSilenceLevel.minRMS))
                    DetailRow(label: "Min Gap Size", value: "\(processor.trimSilenceLevel.minGapSizeInFrames) frames")
                }
                .font(.caption2)
                .foregroundStyle(.tertiary)
                
                // Time Saved
                if processor.timeSavedByTrimming > 0 {
                    HStack {
                        Image(systemName: "clock.badge.checkmark")
                            .foregroundStyle(.green)
                        Text("Saved \(formatTime(processor.timeSavedByTrimming))")
                            .foregroundStyle(.green)
                    }
                    .font(.subheadline.bold())
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private var trimLevelDescription: String {
        switch processor.trimSilenceLevel {
        case .off:
            return "Silence trimming disabled"
        case .mild:
            return "Conservative: Only removes obvious long pauses"
        case .medium:
            return "Balanced: Good for most podcasts and audiobooks"
        case .aggressive:
            return "Maximum: Removes all detectable silence"
        }
    }
    
    // MARK: - Playback Speed Card
    
    private var playbackSpeedCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "gauge.with.needle")
                    .foregroundStyle(.purple)
                Text("Playback Speed")
                    .font(.headline)
                Spacer()
                Toggle("", isOn: $speedEnabled)
                    .labelsHidden()
                    .onChange(of: speedEnabled) { _, newValue in
                        processor.playbackSpeed = newValue ? 1.5 : 1.0
                    }
            }
            
            // Speed Display
            HStack {
                Text("\(processor.playbackSpeed, specifier: "%.1f")x")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .monospacedDigit()
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(speedDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Speed Slider
            Slider(value: $processor.playbackSpeed, in: 0.5...3.0, step: 0.1) {
                Text("Speed")
            } minimumValueLabel: {
                Text("0.5x").font(.caption2)
            } maximumValueLabel: {
                Text("3.0x").font(.caption2)
            }
            .onChange(of: processor.playbackSpeed) { _, newValue in
                speedEnabled = newValue != 1.0
            }
            
            // Quick Speed Buttons
            HStack(spacing: 8) {
                ForEach([0.75, 1.0, 1.25, 1.5, 2.0], id: \.self) { speed in
                    Button {
                        processor.playbackSpeed = Float(speed)
                    } label: {
                        Text("\(speed, specifier: speed == 1.0 ? "%.0f" : "%.2g")x")
                            .font(.caption.bold())
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(processor.playbackSpeed == Float(speed) ? .purple : .secondary)
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private var speedDescription: String {
        let speed = processor.playbackSpeed
        if speed < 0.8 { return "Slow motion" }
        if speed < 1.0 { return "Slightly slower" }
        if speed == 1.0 { return "Normal speed" }
        if speed <= 1.25 { return "Slightly faster" }
        if speed <= 1.5 { return "Fast" }
        if speed <= 2.0 { return "Very fast" }
        return "Maximum speed"
    }
    
    // MARK: - Volume Boost Card
    
    private var volumeBoostCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "speaker.wave.3")
                    .foregroundStyle(.green)
                Text("Volume Boost")
                    .font(.headline)
                Spacer()
                Toggle("", isOn: $volumeBoostEnabled)
                    .labelsHidden()
                    .onChange(of: volumeBoostEnabled) { _, newValue in
                        processor.volumeBoost = newValue ? 1.5 : 1.0
                    }
            }
            
            // Volume Display
            HStack {
                Text("\(processor.volumeBoost, specifier: "%.1f")x")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .monospacedDigit()
                
                Spacer()
                
                // Volume Level Indicator
                HStack(spacing: 2) {
                    ForEach(0..<5) { i in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(i < volumeLevel ? Color.green : Color.secondary.opacity(0.3))
                            .frame(width: 6, height: CGFloat(8 + i * 4))
                    }
                }
            }
            
            // Volume Slider
            Slider(value: $processor.volumeBoost, in: 0.5...3.0, step: 0.1) {
                Text("Volume")
            } minimumValueLabel: {
                Image(systemName: "speaker.fill").font(.caption2)
            } maximumValueLabel: {
                Image(systemName: "speaker.wave.3.fill").font(.caption2)
            }
            .tint(.green)
            .onChange(of: processor.volumeBoost) { _, newValue in
                volumeBoostEnabled = newValue != 1.0
            }
            
            Text("Amplifies quiet audio. Use with caution at high levels.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private var volumeLevel: Int {
        Int((processor.volumeBoost - 0.5) / 0.5)
    }
    
    // MARK: - Statistics Card
    
    private var statisticsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar")
                    .foregroundStyle(.blue)
                Text("Current Settings")
                    .font(.headline)
            }
            
            VStack(spacing: 8) {
                StatRow(icon: "waveform.path", label: "Trim Silence", 
                        value: processor.trimSilenceLevel.displayName,
                        color: .orange)
                
                StatRow(icon: "gauge.with.needle", label: "Speed", 
                        value: String(format: "%.1fx", processor.playbackSpeed),
                        color: .purple)
                
                StatRow(icon: "speaker.wave.3", label: "Volume", 
                        value: String(format: "%.1fx", processor.volumeBoost),
                        color: .green)
                
                if processor.timeSavedByTrimming > 0 {
                    StatRow(icon: "clock", label: "Time Saved", 
                            value: formatTime(processor.timeSavedByTrimming),
                            color: .mint)
                }
                
                // Effective Speed
                let effectiveSpeed = Double(processor.playbackSpeed) * (1 + processor.timeSavedByTrimming / max(processor.duration, 1))
                StatRow(icon: "speedometer", label: "Effective Speed", 
                        value: String(format: "%.2fx", effectiveSpeed),
                        color: .indigo)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Reset Button
    
    private var resetButton: some View {
        Button {
            withAnimation {
                processor.trimSilenceLevel = .off
                processor.playbackSpeed = 1.0
                processor.volumeBoost = 1.0
                trimEnabled = false
                speedEnabled = false
                volumeBoostEnabled = false
            }
        } label: {
            Label("Reset All Settings", systemImage: "arrow.counterclockwise")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(.red)
    }
    
    // MARK: - Helper Methods
    
    private func loadFile(_ url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            try processor.loadFile(url: url)
            fileName = url.lastPathComponent
            // Reset settings for new file
            trimEnabled = true
            processor.trimSilenceLevel = .medium
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

// MARK: - Helper Views

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .monospacedDigit()
        }
    }
}

struct StatRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
                .monospacedDigit()
        }
    }
}

#Preview {
    ContentView()
}
