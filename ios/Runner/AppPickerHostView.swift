import SwiftUI
import FamilyControls

/// Hosts Apple's app picker. It is shown over the app with a clear
/// background, so only the system picker is visible. Dismissing the picker
/// (Done or Cancel) hands the selection to `onDone` and closes this view.
struct AppPickerHostView: View {
    @State private var selection: FamilyActivitySelection
    @State private var isPickerPresented = true
    /// Krijgt de gekozen selectie, ook als die leeg is.
    var onDone: (FamilyActivitySelection) -> Void

    /// Zonder `initial` begint de kiezer met de oude gedeelde selectie in
    /// `UserDefaults`. Een moment geeft zijn eigen selectie mee (of een lege).
    init(initial: FamilyActivitySelection? = nil,
         onDone: @escaping (FamilyActivitySelection) -> Void) {
        _selection = State(initialValue: initial ?? AppPickerHostView.sharedSelection())
        self.onDone = onDone
    }

    var body: some View {
        Color.clear
            .familyActivityPicker(isPresented: $isPickerPresented, selection: $selection)
            .onChange(of: isPickerPresented) { presented in
                if !presented { onDone(selection) }
            }
    }

    private static func sharedSelection() -> FamilyActivitySelection {
        if let data = UserDefaults.standard.data(forKey: "blockedSelection"),
           let saved = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data) {
            return saved
        }
        return FamilyActivitySelection()
    }
}
