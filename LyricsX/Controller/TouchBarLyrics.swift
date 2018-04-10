//
//  TouchBarLyrics.swift
//  LyricsX
//
//  Created by noctis on 2018/4/10.
//  Copyright © 2018年 ddddxxx. All rights reserved.
//

import Cocoa
import LyricsProvider

@available(OSX 10.12.2, *)
class TouchBarLyrics: NSObject, NSTouchBarDelegate {
    
    let touchBar = NSTouchBar()
    let systemTrayItem = NSCustomTouchBarItem(identifier: .systemTrayItem)
    
    var lyricsTextField = NSTextField(labelWithString: "")
    
    var screenLyrics = ""
    
    override init() {
        super.init()
        touchBar.delegate = self
        touchBar.defaultItemIdentifiers = [.lyrics]
        
        systemTrayItem.view = NSButton(image: #imageLiteral(resourceName: "status_bar_icon"), target: self, action: #selector(presentTouchBar))
        NSTouchBarItem.addSystemTrayItem(systemTrayItem)
        DFRElementSetControlStripPresenceForIdentifier(.systemTrayItem, true)
        DFRSystemModalShowsCloseBoxWhenFrontMost(true)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleLyricsDisplay), name: .lyricsShouldDisplay, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleLyricsDisplay), name: .currentLyricsChange, object: nil)
    }
    
    deinit {
        NSTouchBarItem.removeSystemTrayItem(systemTrayItem)
    }
    
    @objc private func presentTouchBar() {
        NSTouchBar.presentSystemModalFunctionBar(touchBar, systemTrayItemIdentifier: .systemTrayItem)
    }
    
    @objc func handleLyricsDisplay() {
        guard let lyrics = AppController.shared.currentLyrics,
            let index = AppController.shared.currentLineIndex else {
                DispatchQueue.main.async {
                    self.lyricsTextField.stringValue = ""
                    self.lyricsTextField.removeProgressAnimation()
                }
                return
        }
        DispatchQueue.main.async {
            let line = lyrics.lines[index]
            self.lyricsTextField.stringValue = line.content
            if let timetag = line.attachments.timetag,
                let position = AppController.shared.playerManager.player?.playerPosition {
                let timeDelay = AppController.shared.currentLyrics?.timeDelay ?? 0
                let progress = timetag.tags.map { ($0.timeTag + line.position - timeDelay - position, $0.index) }
                self.lyricsTextField.addProgressAnimation(color: #colorLiteral(red: 0, green: 1, blue: 0.8333333333, alpha: 1), progress: progress)
            }
        }
    }
    
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        if identifier == .lyrics {
            let item = NSCustomTouchBarItem(identifier: identifier)
            item.view = lyricsTextField
            return item
        } else {
            return nil
        }
    }
}

@available(OSX 10.12.2, *)
extension NSTouchBarItem.Identifier {
    
    static let lyrics = NSTouchBarItem.Identifier("ddddxxx.LyricsX.touchBar.lyrics")
    
    static let systemTrayItem = NSTouchBarItem.Identifier("ddddxxx.LyricsX.touchBar.systemTrayItem")
}