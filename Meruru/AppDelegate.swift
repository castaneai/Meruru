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
    @IBOutlet weak var statusTextField: NSTextField!
    @IBOutlet weak var servicesComboBox: NSComboBox!
    @IBOutlet weak var videoWrapView: NSView!
    
    var mirakurun: MirakurunAPI!
    
    var player: VLCMediaPlayer!
    var services: [Service] = []
    var currentService: Service?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        initUI()
        
        guard let mirakurunPath = AppConfig.shared.currentData?.mirakurunPath ?? promptMirakurunPath() else {
            showErrorAndQuit(error: NSError(domain: "invalid mirakurun path", code: 0))
            return
        }

        mirakurun = MirakurunAPI(baseURL: URL(string: mirakurunPath + "/api")!)
        mirakurun.fetchStatus { result in
            switch result {
            case .success(let status):
                AppConfig.shared.currentData?.mirakurunPath = mirakurunPath
                DispatchQueue.main.async {
                    self.statusTextField.stringValue = "Mirakurun: v" + (status.version ?? " unknown")
                }
                self.mirakurun.fetchServices { result in
                    switch result {
                    case .success(let services):
                        self.services = services
                        DispatchQueue.main.async {
                            self.servicesComboBox.addItems(withObjectValues: services.map { $0.name })
                            self.servicesComboBox.selectItem(at: 0)
                        }
                    case .failure(let error):
                        self.showErrorAndQuit(error: error)
                    }
                }
            case .failure(let error):
                debugPrint(error)
                self.showErrorAndQuit(error: NSError(domain: "failed to get Mirakurun's status (mirakurunPath: \(mirakurunPath))", code: 0))
            }
        }
    }
    
    func showErrorAndQuit(error: Error) {
        let alert = NSAlert(error: error)
        alert.runModal()
        NSApplication.shared.terminate(self)
    }
    
    func initUI() {
        servicesComboBox.delegate = self

        let videoView = VLCVideoView(frame: NSRect(x: 0, y: 0, width: videoWrapView.frame.width, height: videoWrapView.frame.height))
        videoView.autoresizingMask = [.width, .height]
        videoView.fillScreen = true
        videoView.backColor = NSColor.red
        videoWrapView.addSubview(videoView)

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
        currentService = selectedService
        mirakurun.fetchPrograms(service: selectedService) { result in
            switch result {
            case .success(let programs):
                guard let program = self.getNowProgram(programs: programs) else {
                    return
                }
                DispatchQueue.main.async {
                    self.window?.title = "Meruru - \(program.name) - \(selectedService.name)"
                }
            case .failure(_):
                return
            }
        }
        player.stop()
        let media = VLCMedia(url: mirakurun.getStreamURL(service: selectedService))
        player.media = media
        player.play()
    }
    
    func getNowProgram(programs: [Program]) -> Program? {
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        return programs.first { $0.startAt...($0.startAt + $0.duration) ~= now }
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

