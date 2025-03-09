import SwiftUI
import VLCKit

struct VLCPlayerView: NSViewRepresentable {
    let mediaURL: URL?

    class Coordinator {
        let mediaPlayer = VLCMediaPlayer()
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
        playVideo(mediaPlayer: context.coordinator.mediaPlayer)
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
