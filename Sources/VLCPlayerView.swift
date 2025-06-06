import SwiftUI
import VLCKit

struct VLCPlayerView: NSViewRepresentable {
    let mediaURL: URL?
    @Binding var volume: Double

    class Coordinator {
        let mediaPlayer = VLCMediaPlayer()
        var currentMediaURL: URL?
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }

    func makeNSView(context: Context) -> VLCVideoView {
        let videoView = VLCVideoView()
        videoView.autoresizingMask = [.width, .height]
        videoView.fillScreen = true
        context.coordinator.mediaPlayer.drawable = videoView
        return videoView
    }

    func updateNSView(_ nsView: VLCVideoView, context: Context) {
        let coordinator = context.coordinator
        coordinator.mediaPlayer.audio?.volume = Int32(volume * 100)
        if coordinator.currentMediaURL != mediaURL {
            coordinator.currentMediaURL = mediaURL
            playVideo(mediaPlayer: coordinator.mediaPlayer)
        }
    }

    func playVideo(mediaPlayer: VLCMediaPlayer) {
        print("playVideo, \(String(describing: mediaURL))")
        if let mediaURL = mediaURL {
            let media = VLCMedia(url: mediaURL)
            mediaPlayer.media = media
            mediaPlayer.play()
        }
    }
}
