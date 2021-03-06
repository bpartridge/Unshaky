//
//  AppDelegate.swift
//  Unshaky
//
//  Created by Xinhong LIU on 2018-06-21.
//  Copyright © 2018 Nested Error. All rights reserved.
//

import Cocoa
import ServiceManagement

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    let defaults = UserDefaults.standard
    @IBOutlet weak var menu: NSMenu!
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    @IBOutlet weak var window: NSWindow!
    private var shakyPressPreventer : ShakyPressPreventer
    @IBOutlet weak var dismissShakyPressCountMenuItem: NSMenuItem!
    @IBOutlet weak var preferenceMenuItem: NSMenuItem!
    @IBOutlet weak var versionMenuItem: NSMenuItem!
    
    private var dismissCount = 0
    
    override init() {
        shakyPressPreventer = ShakyPressPreventer.sharedInstance()
        super.init()
    }
    
    @IBAction func quitClicked(_ sender: Any) {
        NSApplication.shared.terminate(self)
    }
    
    func updateDismissCountLabel() {
        dismissShakyPressCountMenuItem.title = String(format: NSLocalizedString("Overall Statistic", comment: ""), dismissCount)
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let icon = NSImage(named: NSImage.Name(rawValue: "UnshakyTemplate"))
        statusItem.image = icon
        
        statusItem.menu = menu
        statusItem.behavior = .removalAllowed
        
        dismissCount = defaults.integer(forKey: "DISMISS_COUNT")
        updateDismissCountLabel()

        // show version number
        let version = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        versionMenuItem.title = String(format: NSLocalizedString("Version", comment: ""), version)

        // this following lines will add Unshaky.app to privacy->accessibility panel, unchecked
        let checkOptPrompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
        let accessEnabled = AXIsProcessTrustedWithOptions([checkOptPrompt: false] as CFDictionary?)

        if (!shakyPressPreventer.setupInputDeviceListener() || !accessEnabled) {
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("Accessibility Help", comment: "")
            alert.runModal()
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
            NSApplication.shared.terminate(self)
        }
        shakyPressPreventer.shakyPressDismissed {
            self.dismissCount += 1
            OperationQueue.main.addOperation {
                self.updateDismissCountLabel()
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        defaults.set(dismissCount, forKey: "DISMISS_COUNT")
        defaults.synchronize()
    }

    // applicationDidBecomeActive is only called if Unshaky is opened
    // again when it is already running. So I can make the status bar item
    // show up again here.
    func applicationDidBecomeActive(_ notification: Notification) {
        statusItem.isVisible = true
    }
    
    //
    // DEBUG Function
    //
    var debugWindowController: NSWindowController!
    @IBAction func debugClicked(_ sender: Any) {
        // we use shakyPressPreventer.debugViewController == nil to track
        // whether a debug window is already open
        // so when the window is closed, we will
        // update shakyPressPreventer.debugViewController to nil
        if (shakyPressPreventer.debugViewController != nil) {
            return;
        }

        let windowStyleMaskRawValue = NSWindow.StyleMask.closable.rawValue | NSWindow.StyleMask.titled.rawValue | NSWindow.StyleMask.resizable.rawValue
        let windowFrame = NSMakeRect(100, 100, 600, 400)
        let window = NSWindow(contentRect: windowFrame, styleMask: .init(rawValue: windowStyleMaskRawValue), backing: .buffered, defer: false)
        debugWindowController = NSWindowController(window: window)
        window.delegate = self

        let debugPanelStoryboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Debug"), bundle: nil)
        let debugViewController = (debugPanelStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "Debug")) as! DebugViewController)

        window.contentView = debugViewController.view
        window.orderFrontRegardless()
        shakyPressPreventer.debugViewController = debugViewController
    }
    
    //
    // Preference
    //
    var preferenceWindowController: NSWindowController!
    @IBAction func preferenceClicked(_ sender: Any) {
        // prevent multiple preference windows
        for window in NSApplication.shared.windows {
            if window.title == NSLocalizedString("Configuration Window Title", comment: "") && window.isVisible {
                NSApp.activate(ignoringOtherApps: true)
                return
            }
        }
        
        let preferencePanelStoryboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Preference"), bundle: nil)
        preferenceWindowController = preferencePanelStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "Preference")) as! NSWindowController
        preferenceWindowController.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
    }
    
}

extension AppDelegate: NSWindowDelegate {
    // update shakyPressPreventer.debugViewController to nil
    // when debug window is closed
    func windowWillClose(_ notification: Notification) {
        shakyPressPreventer.debugViewController = nil
    }
}
