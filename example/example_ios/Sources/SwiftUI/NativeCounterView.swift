import SwiftUI

@available(iOS 16.0, *)
struct NativeCounterView: View {
    @StateObject private var storage = Add2AppStorageObserver()
    @State private var count = 0
    @State private var updatedBy = "flutter"

    private var store: CounterStore {
        CounterStore(storage: storage.scope)
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("Native SwiftUI Counter")
                .font(.headline)
            Text("Count: \(count)")
                .font(.title2)
            Text("Last updated by: \(updatedBy)")
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Button("+") {
                    writeCounter(count + 1)
                }
                .buttonStyle(.borderedProminent)

                Button("-") {
                    writeCounter(count - 1)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .navigationTitle("Native Counter")
        .onAppear {
            storage.startObserving { _ in
                refresh()
            }
            refresh()
        }
        .onDisappear {
            storage.stopObserving()
        }
    }

    private func writeCounter(_ newValue: Int) {
        var s = store
        s.count = newValue
        s.lastUpdatedBy = "ios-swiftui"
        refresh()
    }

    private func refresh() {
        count = store.count
        updatedBy = store.lastUpdatedBy
    }
}
