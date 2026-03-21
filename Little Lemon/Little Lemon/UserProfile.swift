//
//  UserProfile.swift
//  Little Lemon
//
//  Created by  Artem Mazheykin on 20.03.2026.
//

import SwiftUI

struct UserProfile: View {
    @Environment(\.presentationMode) var presentation

    let firstName = UserDefaults.standard.string(forKey: kFirstName)
    let lastName = UserDefaults.standard.string(forKey: kLastName)
    let email = UserDefaults.standard.string(forKey: kEmail)

    var body: some View {
        VStack(spacing: 20) {
            Text("Personal information")
                .font(.title)

            Image("profile-image-placeholder")
                .resizable()
                .frame(width: 120, height: 120)

            Text(firstName ?? "")
            Text(lastName ?? "")
            Text(email ?? "")

            Button("Logout") {
                UserDefaults.standard.set(false, forKey: kIsLoggedIn)
                self.presentation.wrappedValue.dismiss()
            }

            Spacer()
        }
        .padding()
    }
}

#Preview {
    UserProfile()
}
