import SwiftUI

/// The main navigation view.
struct PlayersNavigationView: View {
    @Environment(\.appDatabase) var appDatabase
    
    var body: some View {
        // This technique makes it possible to create an observable object
        // (PlayerListModel) from the SwiftUI environment.
        ContentView(appDatabase: appDatabase)
    }
}

private struct ContentView: View {
    @State var model: ProjectListModel

    init(appDatabase: AppDatabase) {
        _model = State(initialValue: ProjectListModel(appDatabase: appDatabase))
    }
    
    var body: some View {
        Text("Hello, World!")
    }
}
