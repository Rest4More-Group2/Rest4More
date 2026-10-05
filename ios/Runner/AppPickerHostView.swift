import SwiftUI
import FamilyControls

struct AppPickerHostView: View {
    @State private var selection = FamilyActivitySelection()
    @State private var isPickerPresented = true
    var onDone: () -> Void

    var body: some View {
        NavigationView {
            VStack {
                Text("Select apps to block")
                    .font(.headline)
                    .padding()
            }
            .familyActivityPicker(isPresented: $isPickerPresented, selection: $selection)
            .navigationBarItems(trailing: Button("Done") {
                saveAndFinish()
            })
        }
    }

    private func saveAndFinish() {
        if let data = try? PropertyListEncoder().encode(selection) {
            UserDefaults.standard.set(data, forKey: "blockedSelection")
        }
        onDone()
    }
}
