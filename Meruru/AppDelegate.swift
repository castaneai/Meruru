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
        var mirakurunPath = AppConfig.shared.currentData?.mirakurunPath
        if mirakurunPath == nil {
            mirakurunPath = promptMirakurunPath()
            if mirakurunPath == nil {
                let alert = NSAlert()
                alert.messageText = "invalid mirakurun path"
                alert.runModal()
                NSApplication.shared.terminate(self)
            }
        }
        mirakurun = MirakurunAPI(baseURL: URL(string: (mirakurunPath ?? "") + "/api")!)
        
        AppConfig.shared.currentData?.mirakurunPath = mirakurunPath
        
        servicesComboBox = NSComboBox(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
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
        
        let videoView = VLCVideoView(frame: NSRect(x: 0, y: 24, width: window.frame.width, height: window.frame.height - 24))
        videoView.autoresizingMask = [.width, .height]
        videoView.fillScreen = true
        videoView.backColor = NSColor.red
        window.contentView?.addSubview(videoView)
        player = VLCMediaPlayer(videoView: videoView)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func promptMirakurunPath() -> Optional<String> {
        let alert = NSAlert()
        alert.messageText = "Please input path of Mirakurun (e.g, http://192.168.x.x:40772)"
        alert.alertStyle = .informational
        let tf = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        alert.accessoryView = tf
        alert.addButton(withTitle: "OK")
        let res = alert.runModal()
        if res == .alertFirstButtonReturn {
            return tf.stringValue
        }
        return nil
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
        player?.stop()
        do {
            try AppConfig.shared.save()
        } catch let err {
            let alert = NSAlert(error: err)
            alert.runModal()
        }
    }
}

