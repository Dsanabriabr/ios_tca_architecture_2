//
//  ContactDetailFeature.swift
//  TCA_Architecture_2
//
//  Created by Daniel Sanabria on 27/04/26.
//

import ComposableArchitecture
import SwiftUI

// MARK: - Feature
@Reducer
struct ContactDetailFeature {
    @ObservableState
    struct State: Equatable {
        let contact: Contact
        @Presents var alert: AlertState<Action.Alert>?
    }
    enum Action {
        case alert(PresentationAction<Alert>)
        case delegate(Delegate)
        case deleteButtonTapped
        case editButtonTapped
        enum Alert {
            case confirmDeletion
        }
        enum Delegate {
            case confirmDeletion
        }
    }
    @Dependency(\.dismiss) var dismiss
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .alert(.presented(.confirmDeletion)):
                return .run { send in
                    await send(.delegate(.confirmDeletion))
                    await self.dismiss()
                }
            case .alert:
                return .none
            case .delegate:
                return .none
            case .deleteButtonTapped:
                state.alert = .confirmDeletion
                return .none
            case .editButtonTapped:
                
                return .none
            }
        }.ifLet(\.$alert, action: \.alert)
    }
}

// MARK: - View
struct ContactDetailView: View {
    @Bindable var  store: StoreOf<ContactDetailFeature>
    
    var body: some View {
        Form {
            Button("Delete") {
                store.send(.deleteButtonTapped)
            }
        }
        .navigationTitle(Text(store.contact.name))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Editar") {
                    store.send(.deleteButtonTapped)
                }
            }
        }
        .alert($store.scope(state: \.alert, action: \.alert))
    }
}

// MARK: - Preview
#Preview {
  NavigationStack {
    ContactDetailView(
      store: Store(
        initialState: ContactDetailFeature.State(
          contact: Contact(id: UUID(), name: "Blob")
        )
      ) {
        ContactDetailFeature()
      }
    )
  }
}

// MARK: - AlertState
extension AlertState where Action == ContactDetailFeature.Action.Alert {
    static let confirmDeletion = Self {
        TextState("Are you sure?")
    } actions: {
        ButtonState(role: .destructive, action: .confirmDeletion) {
            TextState("Delete")
        }
    }
}

struct AlertEditNameView: View {
    @State private var presentAlert = false
    @State private var name: String = ""
    
    var body: some View {
        Button("Show Alert") {
            presentAlert = true
        }
        .alert("Username", isPresented: $presentAlert, actions: {
            TextField("Username", text: $name)

            
            Button("Edit", action: {})
            Button("Cancel", role: .cancel, action: {})
        }, message: {
            Text("Please update the username.")
        })
    }
}
