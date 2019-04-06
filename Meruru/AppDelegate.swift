//
//  AppDelegate.swift
//  Meruru
//
//  Created by castaneai on 2019/04/06.
//  Copyright © 2019 castaneai. All rights reserved.
//

import Cocoa
import VLCKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    
    var player: VLCMediaPlayer!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let videoView = VLCVideoView(frame: window!.frame)
        window.contentView?.addSubview(videoView)
        player = VLCMediaPlayer(videoView: videoView)
        player.media = VLCMedia(path: "/Users/castaneai/Desktop/honey.mp4")
        player.play()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        player.stop()
    }


}

