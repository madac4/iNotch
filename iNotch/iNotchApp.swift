import SwiftUI
import Defaults
import Sparkle

@main
struct iNotchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Default(.showMenuBarIcon) var showMenuBarIcon
    @Environment(\.openWindow) var openWindow
    
    // MARK: - Sparkle Updater Controller (NEW)
    let updaterController: SPUStandardUpdaterController
    
    // MARK: - Initializer with Sparkle (NEW)
    init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        
        SettingsWindowController.shared.setUpdaterController(updaterController)
    }
    
    var body: some Scene {
        MenuBarExtra("iNotch", systemImage: "sparkle", isInserted: $showMenuBarIcon){
            Button("Settings"){
                SettingsWindowController.shared.showWindow()
            }
            .keyboardShortcut(KeyEquivalent(","), modifiers: .command)
            
            // MARK: - Check for Updates Button (NEW)
            CheckForUpdatesView(updater: updaterController.updater)
            
            Divider()
            Button("Restart iNotch"){
                guard let bundleIdentitier = Bundle.main.bundleIdentifier else { return }
                
                let workspace = NSWorkspace.shared
                
                if let appURL = workspace.urlForApplication(withBundleIdentifier: bundleIdentitier){
                    let configuration = NSWorkspace.OpenConfiguration()
                    configuration.createsNewApplicationInstance = true
                    
                    workspace.openApplication(at: appURL, configuration: configuration)
                }
                
                NSApplication.shared.terminate(self)
            }
            
            
            Button("Quit", role: .destructive){
                NSApplication.shared.terminate(self)
            }
            .keyboardShortcut(KeyEquivalent("Q"), modifiers: .command)
        }
    }
}


class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?
    let vm: NotchViewModel = .init()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
		let showInDock = Defaults[.showInDock]

		NSApp.setActivationPolicy(showInDock ? .regular : .accessory)

        let viewModel = self.vm
        
        let window = createNotchWindow(for: NSScreen.main ?? NSScreen.screens.first!, with: viewModel)
        self.window = window
        
        adjustWindowPosition()
        
        _ = VolumeManager.shared
        
        if isNewVersion() {
            print("New version detected: \(Bundle.main.releaseVersionNumberPretty)")
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    private func createNotchWindow(for screen: NSScreen, with viewModel: NotchViewModel) -> NSWindow {
        let window = NotchWindow(
            contentRect: NSRect(
                x: 0, y: 0,
                width: openNotchSize.width,
                height: openNotchSize.height
            ),
            styleMask: [.borderless, .nonactivatingPanel, .utilityWindow, .hudWindow],
            backing: .buffered,
            defer: false
        )
        
        window.contentView = NSHostingView(rootView: ContentView().environmentObject(viewModel))
        
        window.orderFrontRegardless()
        NotchSpaceManager.shared.notchSpace.windows.insert(window)
        return window
    }


    func adjustWindowPosition(){
        if let window = window, let screen = NSScreen.main {
            positionWindow(window, on: screen)
            
            if vm.notchState == .closed {
                vm.close()
            }
        }
    }

    
    private func positionWindow(_ window: NSWindow, on screen: NSScreen, changeAlpha: Bool = false){
        if changeAlpha {
            window.alphaValue = 0
        }
        
        DispatchQueue.main.async { [weak window] in
            guard let window = window else { return }
            window.setFrameOrigin(NSPoint(
                x: screen.frame.origin.x + (screen.frame.width / 2) - window.frame.width / 2,
                y: screen.frame.origin.y + screen.frame.height - window.frame.height
            ))
            window.alphaValue = 1
        }
    }

}
