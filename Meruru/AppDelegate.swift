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
class AppDelegate: NSObject, NSApplicationDelegate, NSComboBoxDelegate {

    @IBOutlet weak var window: NSWindow!
    
    var mirakurun: MirakurunAPI!
    
    var servicesComboBox: NSComboBox!
    
    var player: VLCMediaPlayer!
    var services: [Service] = []

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        mirakurun = MirakurunAPI(baseURL: URL(string: "http://192.168.0.7:40772/api")!)
        
        servicesComboBox = NSComboBox(frame: NSRect(x: 0, y: 0, width: 200, height: 30))
        servicesComboBox.delegate = self
        window.contentView?.addSubview(servicesComboBox)
        
        mirakurun.fetchServices { result in
            switch result {
            case .success(let services):
                self.services = services
                DispatchQueue.main.async {
                    self.servicesComboBox.addItems(withObjectValues: services.map { $0.name })
                    self.servicesComboBox.selectItem(at: 0)
                }
            case .failure(let err):
                debugPrint(err)
            }
        }
        
        let videoView = VLCVideoView(frame: NSRect(x: 0, y: 30, width: window.frame.width, height: window.frame.height - 30))
        videoView.autoresizingMask = [.width, .height]
        videoView.fillScreen = true
        videoView.backColor = NSColor.red
        window.contentView?.addSubview(videoView)
        player = VLCMediaPlayer(videoView: videoView)
    }
    
    func comboBoxSelectionDidChange(_ notification: Notification) {
        let selectedService = services[servicesComboBox.indexOfSelectedItem]
        debugPrint(selectedService)
        player.stop()
        let media = VLCMedia(url: mirakurun.getStreamURL(service: selectedService))
        player.media = media
        player.play()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        player.stop()
    }
}

