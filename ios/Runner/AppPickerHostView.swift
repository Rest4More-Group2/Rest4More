import SwiftUI
import FamilyControls

/// Hosts Apple's app picker. It is shown over the app with a clear
/// background, so only the system picker is visible. Dismissing the picker
/// (Done or Cancel) saves the selection and closes this view.
struct AppPickerHostView: View {
    @State private var selection: FamilyActivitySelection = {
        if let data = UserDefaults.standard.data(forKey: "blockedSelection"),
           let saved = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data) {
            return saved
        }
        return FamilyActivitySelection()
    }()
    @State private var isPickerPresented = true
    var onDone: () -> Void

    var body: some View {
        Color.clear
            .familyActivityPicker(isPresented: $isPickerPresented, selection: $selection)
            .onChange(of: isPickerPresented) { presented in
                if !presented { saveAndFinish() }
            }
    }

    private func saveAndFinish() {
        if let data = try? PropertyListEncoder().encode(selection) {
            UserDefaults.standard.set(data, forKey: "blockedSelection")
        }
        onDone()
    }
}
