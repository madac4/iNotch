 import SwiftUI
 import Sparkle

 struct SettingsView: View {
 	@State private var selectedTab = "General"

 	let updaterController: SPUStandardUpdaterController?
		
 	init(updaterController: SPUStandardUpdaterController? = nil) {
 		self.updaterController = updaterController
 	}

	var body: some View {
        NavigationSplitView{
			List(selection: $selectedTab) {
                SettingsNavigationItem.withLinearGradient(
                    value: "General",
                    icon: "gearshape.fill",
                    title: "General",
                    gradientColors: [
                        Color(red: 0.46, green: 0.44, blue: 0.41),
                        Color(red: 0.64, green: 0.63, blue: 0.59)
                    ]
                )
                
				Section("Notifications") {
                    SettingsNavigationItem.withLinearGradient(
                        value: "Battery",
                        icon: "bolt.fill",
                        title: "Battery",
                        gradientColors: [
                            Color(red: 0.97, green: 0.55, blue: 0.4),
                            Color(red: 1, green: 0.71, blue: 0.53)
                        ]
                    )
                    
                    SettingsNavigationItem.withLinearGradient(
                        value: "Connectivity",
                        icon: "airpodsmax",
                        title: "Connectivity",
                        gradientColors: [
                            Color(red: 0.97, green: 0.55, blue: 0.4),
                            Color(red: 1, green: 0.71, blue: 0.53)
                        ]
                    )
					
                    SettingsNavigationItem.withLinearGradient(
                        value: "Sound",
                        icon: "speaker.wave.3.fill",
                        title: "Sound",
                        gradientColors: [
                            Color(red: 0.88, green: 0.29, blue: 0.89),
                            Color(red: 0.98, green: 0.5, blue: 0.95)
                        ]
                    )
				}
				
				Section("Live Activities") {
                    SettingsNavigationItem.withLinearGradient(
                        value: "Now Playing",
                        icon: "play.fill",
                        title: "Now Playing",
                        gradientColors: [
                            Color(red: 0.92, green: 0.25, blue: 0.35),
                            Color(red: 1, green: 0.45, blue: 0.57)
                        ]
                    )
				}
			}
			.listStyle(.sidebar)
			.navigationSplitViewColumnWidth(200)
 		} detail: {
 			Group {
 				switch selectedTab {
 				case "General":
 					GeneralSettingsView()
 				case "Battery":
 					BatterySettingsView()
 				case "Sound":
 					SoundSettingsView()
 				case "Now Playing":
 					NowPlayingSettingsView()
                case "Connectivity":
                    ConnectivitySettingsView()
 				default:
 					GeneralSettingsView()
 				}
 			}
 			.frame(maxWidth: .infinity, maxHeight: .infinity)
 		}
 		.navigationSplitViewStyle(.balanced)
 		.formStyle(.grouped)
 		.frame(width: 700)
 		.background(Color(NSColor.windowBackgroundColor))
 	}
 }

#Preview {
    SettingsView()
}
