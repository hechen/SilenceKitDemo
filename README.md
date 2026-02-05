# SilenceKitDemo

Demo iOS app showcasing [SilenceKit](https://github.com/hechen/SilenceKit) audio processing capabilities.

![iOS 17+](https://img.shields.io/badge/iOS-17%2B-blue.svg)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange.svg)

## Features

- **File Import** - Pick audio files (MP3, M4A, WAV, CAF) from Files app
- **Playback Controls** - Play, pause, seek forward/back
- **Trim Silence** - 4 levels (Off, Mild, Medium, Aggressive)
- **Speed Control** - 0.5x to 3.0x playback speed
- **Volume Boost** - 0.5x to 3.0x amplification
- **Statistics** - Real-time display of time saved by silence trimming

## Requirements

- iOS 17.0+
- Xcode 16+

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/hechen/SilenceKitDemo.git
   cd SilenceKitDemo
   ```

2. Generate Xcode project:
   ```bash
   brew install xcodegen  # if needed
   xcodegen generate
   ```

3. Open and run:
   ```bash
   open SilenceKitDemo.xcodeproj
   ```

## Usage

1. Launch the app
2. Tap "Select Audio File" to pick an audio file
3. Use playback controls to play/pause
4. Adjust effects:
   - **Trim Silence**: Removes silent portions (great for podcasts)
   - **Speed**: Adjust playback rate
   - **Volume Boost**: Amplify quiet audio

## Code Example

```swift
import SilenceKit

struct ContentView: View {
    @StateObject private var processor = AudioProcessor()
    
    var body: some View {
        VStack {
            // Trim Silence Picker
            Picker("Trim", selection: $processor.trimSilenceLevel) {
                ForEach(TrimSilenceLevel.allCases, id: \.self) { level in
                    Text(level.displayName).tag(level)
                }
            }
            
            // Speed Slider
            Slider(value: $processor.playbackSpeed, in: 0.5...3.0)
            
            // Play Button
            Button(processor.isPlaying ? "Pause" : "Play") {
                processor.isPlaying ? processor.pause() : processor.play()
            }
        }
    }
}
```

## License

MIT

---

See [SilenceKit](https://github.com/hechen/SilenceKit) for the underlying audio processing library.
