import SwiftUI

struct SideBarView: View {
    @EnvironmentObject var cv: ContentView.ViewModel
    
    var body: some View {
        VStack {
            sideMenu(icon: "camera", command: "1") {
                cv.activeMenuBarExtraWindow()
                cv.isShowScreenShot.toggle()
            }
            sideMenu(icon: "magnifyingglass", command: "2") {}
            sideMenu(icon: "camera.metering.unknown", command: "3") {}
            sideMenu(icon: "bolt.ring.closed") {
                NSApp.terminate(nil) // App 종료
            }
            Spacer()
        }
        .padding(.trailing)
        .padding(.vertical)
        .overlay {
            if cv.isShowScreenShot {
                ScreenShotView() {
                    cv.isShowScreenShot = false
                }
            }
        }
    }
    
    // TODO: Menu Button for SiderBar
    private func sideMenu(icon iconName: String, command: String? = nil ,action: @escaping () -> Void) -> some View {
        Button(action: action, label: {
            VStack {
                Image(systemName: iconName)
                    .font(.largeTitle)
                Spacer()
                HStack {
                    if let command = command {
                        Image(systemName: "command")
                        Text("+")
                        Text(command)
                    }else {
                        Text("종료")
                    }
                }
                .font(.caption)
                .frame(maxWidth: 50)
            }
            .padding(8)
        })
        .buttonStyle(.bordered)
        .padding(.bottom)
    }
}
//
//#Preview {
//    SideBarView()
//}
