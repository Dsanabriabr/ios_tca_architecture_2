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
        var contact: Contact
        @Presents var destination: Destination.State?
    }
    enum Action {
        case destination(PresentationAction<Destination.Action>)
        case delegate(Delegate)
        case deleteButtonTapped
        case editButtonTapped
        enum Alert {
            case confirmDeletion
        }
        enum Delegate {
            case confirmDeletion
            case editContact(Contact)
        }
    }
    @Dependency(\.dismiss) var dismiss
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .destination(.presented(.editContact(.delegate(.saveContact(let contact))))):
                return .run { send in
                    await send(.delegate(.editContact(contact)))
                    await self.dismiss()
                }
            case .destination(.presented(.alert(.confirmDeletion))):
                return .run { send in
                    await send(.delegate(.confirmDeletion))
                    await self.dismiss()
                }
            case .destination(.dismiss):
                return .none
            case .destination(.presented(.editContact(.cancelButtonTapped))):
                return .none
            case .destination(.presented(.editContact(.saveButtonTapped))):
                return .none
            case .destination(.presented(.editContact(.setName(_)))):
                return .none
            case .destination(_):
                return .none
            case .delegate(_):
                return .none
            case .deleteButtonTapped:
                state.destination = .alert(.confirmDeletion)
                return .none
            case .editButtonTapped:
                state.destination = .editContact(AddContactFeature.State(contact: state.contact))
                return .none
            }
        }.ifLet(\.$destination, action: \.destination) {
            Destination.body
        }
    }
}

// MARK: - View
struct ContactDetailView: View {
    @Bindable var  store: StoreOf<ContactDetailFeature>
    var editContactStore: Binding<StoreOf<AddContactFeature>?> {
        $store.scope(state: \.$destination, action: \.destination).editContact
    }
    var body: some View {
        Form {
            Button("Delete", systemImage: "trash") {
                store.send(.deleteButtonTapped)
            }.foregroundStyle(.red)
        }
        .navigationTitle(Text(store.contact.name))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Editar") {
                    store.send(.editButtonTapped)
                }
            }
        }.sheet(item: editContactStore) { editContactStore in
            NavigationStack {
                AddContactView(store: editContactStore)
            }
        }.alert($store.scope(state: \.$destination, action: \.destination).alert
        ) { action in
            guard let action = action else {return}
            store.send(.destination(.presented(.alert(action))))
        }
    
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

// MARK: - Destination
extension ContactDetailFeature {
    @Reducer
    enum Destination {
        case editContact(AddContactFeature)
        case alert(AlertState<ContactDetailFeature.Action.Alert>)
    }
}
extension ContactDetailFeature.Destination.State: Equatable {}
