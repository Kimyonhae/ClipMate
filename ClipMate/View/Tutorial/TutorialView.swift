import SwiftUI

struct TutorialView: View {
    var body: some View {
        NavigationStack {
            List {
                ForEach(data, id: \.self) { tutorial in
                    NavigationLink(value: tutorial) {
                        HStack {
                            Image(systemName: tutorial.systemImage)
                                .frame(width: 25)
                            Text(tutorial.title)
                        }
                    }
                }
            }
            .navigationTitle(Text("이용 가이드"))
            .navigationDestination(for: Tutorial.self) { tutorial in
                TutorialDetailView(tutorial: tutorial)
            }
        }
    }
}

extension TutorialView {
    var data: [Tutorial] {
        [
            Tutorial(title: "Copy to Clipboard", content: "ClipMate automatically saves all text and images you copy. Just use the `Command + C` shortcut as usual to copy your desired content, and it will be added to your clipboard history.", systemImage: "doc.on.doc"),
            Tutorial(title: "Paste from ClipMate", content: "Select an item in the clipboard and press `Enter`. This makes it the active item to be pasted. You can then use `Command + V` to paste it anywhere.", systemImage: "keyboard"),
            Tutorial(title: "Toggle Clipboard Window", content: "Press `Command + M` to show or hide the ClipMate window. This allows you to quickly access your clipboard history.", systemImage: "macwindow.on.rectangle"),
            Tutorial(title: "Screenshot Mode", content: "Press `Command + 1` to activate Screenshot Mode. This mode allows you to copy the screenshot to your clipboard, save it as an image, and extract text from it.", systemImage: "camera"),
            Tutorial(title: "Managing Folders", content: "You can organize your clips using folders.\n\n**Creating a Folder:** Click the button on the far right of the folder list to add a new folder.\n\n**Renaming a Folder:** Double-click on any folder to change its name.\n\n**Deleting a Folder:** Hover your mouse over a folder, and a delete button will appear. Deleting a folder will also permanently remove all the clips stored inside it.", systemImage: "folder"),
            Tutorial(title: "Quit the App", content: "To close the application, click the 'Exit' button located in the sidebar.", systemImage: "power")
        ]
    }
}
