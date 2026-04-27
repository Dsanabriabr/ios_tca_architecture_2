//
//  TCA_Architecture_2App.swift
//  TCA_Architecture_2
//
//  Created by Daniel Sanabria on 24/04/26.
//

import SwiftUI
import ComposableArchitecture

@main
struct TCA_Architecture_2App: App {
    static let store = Store(initialState: ContactsFeature.State()) {
        ContactsFeature()
            ._printChanges()
    }
    var body: some Scene {
        WindowGroup {
            ContactsView(store: TCA_Architecture_2App.store)
        }
    }
}
