//
//  ContactsFeature.swift
//  TCA_Architecture_2
//
//  Created by Daniel Sanabria on 24/04/26.
//

import ComposableArchitecture
import Foundation
import SwiftUI

struct Contact: Equatable, Identifiable {
  let id: UUID
  var name: String
}


@Reducer
struct ContactsFeature {
  @ObservableState
  struct State: Equatable {
    @Presents var destination: Destination.State?
    var contacts: IdentifiedArrayOf<Contact> = []
  }
    enum Action {
        case addButtonTapped
        case destination(PresentationAction<Destination.Action>)
        case deleteButtonTapped(id: Contact.ID)
        @CasePathable
        enum Alert: Equatable {
            case confirmDeletion(id: Contact.ID )
        }
    }
    @Dependency(\.uuid) var uuid
  var body: some ReducerOf<Self> {
    Reduce { state, action in
        switch action {
        case .addButtonTapped:
            state.destination = .addContact(AddContactFeature.State(contact: Contact(id: uuid(), name: "")))
            return .none
        case .destination(.presented(.addContact(.delegate(.saveContact(let contact))))):
            state.contacts.append(contact)
            return .none
        case .deleteButtonTapped(id: let id):
            state.destination = .alert(.deleteConfirmation(id: id)
          )
          return .none
      case .destination(.presented(.alert(.confirmDeletion(id: let id)))):
          state.contacts.remove(id: id)
          return .none
      case .destination(.dismiss):
          return .none
      case .destination(.presented(.addContact(.cancelButtonTapped))):
          return .none
      case .destination(.presented(.addContact(.saveButtonTapped))):
          return .none
      case .destination(.presented(.addContact(.setName(_)))):
          return .none
      }
    }.ifLet(\.$destination, action: \.destination) {
        Destination.body
    }
  }
}
extension ContactsFeature {
  @Reducer
  enum Destination {
    case addContact(AddContactFeature)
    case alert(AlertState<ContactsFeature.Action.Alert>)
  }
}
extension ContactsFeature.Destination.State: Equatable {}

struct ContactsView: View {
  @Bindable var store: StoreOf<ContactsFeature>
    var addContactStore: Binding<StoreOf<AddContactFeature>?> {
        $store.scope(state: \.$destination, action: \.destination).addContact
    }
  var body: some View {
    NavigationStack {
      List {
        ForEach(store.contacts) { contact in
            HStack {
               Text(contact.name)
               Spacer()
               Button {
                 store.send(.deleteButtonTapped(id: contact.id))
               } label: {
                 Image(systemName: "trash")
                   .foregroundColor(.red)
               }
            }
        }
      }
      .navigationTitle("Contacts")
      .toolbar {
        ToolbarItem {
          Button {
            store.send(.addButtonTapped)
          } label: {
            Image(systemName: "plus")
          }
        }
      }
    }
    .sheet(
      item: addContactStore) { addContactStore in
      NavigationStack {
        AddContactView(store: addContactStore)
      }
      }.alert(
        $store.scope(state: \.$destination, action: \.destination).alert
      ) { action in
          guard let action = action else {return}
          store.send(.destination(.presented(.alert(action))))
      }
  }
}

#Preview {
  ContactsView(
    store: Store(
      initialState: ContactsFeature.State(
        contacts: [
          Contact(id: UUID(), name: "Blob"),
          Contact(id: UUID(), name: "Blob Jr"),
          Contact(id: UUID(), name: "Blob Sr"),
        ]
      )
    ) {
      ContactsFeature()
    }
  )
}
extension AlertState where Action == ContactsFeature.Action.Alert {
  static func deleteConfirmation(id: UUID) -> Self {
    Self {
      TextState("Are you sure?")
    } actions: {
      ButtonState(role: .destructive, action: .confirmDeletion(id: id)) {
        TextState("Delete")
      }
    }
  }
}
