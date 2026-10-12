import SwiftUI
import FamilyControls

struct AppPickerHostView: View {
    @State private var selection: FamilyActivitySelection
    @State private var isPickerPresented = true
    /// Krijgt de gekozen selectie als `PropertyListEncoder`-data.
    var onDone: (FamilyActivitySelection) -> Void

    init(initial: FamilyActivitySelection = FamilyActivitySelection(),
         onDone: @escaping (FamilyActivitySelection) -> Void) {
        _selection = State(initialValue: initial)
        self.onDone = onDone
    }

    var body: some View {
        NavigationView {
            VStack {
                Text("Select apps to block")
                    .font(.headline)
                    .padding()
            }
            .familyActivityPicker(isPresented: $isPickerPresented, selection: $selection)
            .navigationBarItems(trailing: Button("Done") {
                onDone(selection)
            })
        }
    }
}
