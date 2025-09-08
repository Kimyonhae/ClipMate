import SwiftUI

struct TutorialDetailView: View {
    let tutorial: Tutorial
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 15) {
                Image(systemName: tutorial.systemImage)
                    .font(.system(size: 40))
                    .foregroundColor(.accentColor)
                    .frame(width: 50)

                Text(tutorial.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }
            .padding(.vertical, 10)

            ScrollView {
                Text(tutorial.content)
                    .font(.body)
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                    .lineSpacing(7.5)
                    .tracking(-0.01)
            }

            Spacer()
        }
        .padding()
        .navigationTitle(tutorial.title)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
