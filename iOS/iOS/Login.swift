//
//  Login.swift
//  iOS
//
//  Created by Nathan Tornquist on 2/15/21.
//  Copyright © 2021 nathantornquist. All rights reserved.
//

import SwiftUI
import TimeSDK

struct Login: View {
    @State var email: String = ""
    @State var password: String = ""
    @State var errors: [String] = []
    
    @Binding var authenticated: Bool
    
    @EnvironmentObject var warehouse: Warehouse
    
    var formComplete: Bool {
        return self.email.count > 0 && self.password.count > 0
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Email", text: $email)
                        .textContentType(.username)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .autocapitalization(.none)
                                                            
                    if errors.count > 0 {
                        ForEach(errors.indices) { (i) -> Text in
                            (
                                Text(Image(systemName: "exclamationmark.triangle")) + Text(" ") + Text(errors[i])
                            ).foregroundColor(Color(.systemRed))
                        }
                    }
                }

                HStack {
                    Button("Sign up") {
                        self.handleButton(isSignup: true)
                    }.buttonStyle(BorderlessButtonStyle())
                    .disabled(!self.formComplete)
                    
                    Spacer()
                    
                    Button("Log In") {
                        self.handleButton(isSignup: false)
                    }.buttonStyle(BorderlessButtonStyle())
                    .disabled(!self.formComplete)
                }

            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Time")
        }
    }
    
    func handleButton(isSignup signUp: Bool) {
        let (email, emailErrors) = Time.validate(email: self.email, validateContents: signUp)
        let (password, passwordErrors) = Time.validate(password: self.password, validateContents: signUp)
        
        guard emailErrors.count == 0 && passwordErrors.count == 0 else {
            let errors = (emailErrors + passwordErrors).map({ $0.description })
            self.errors = errors
            return
        }
        
        guard let safeEmail = email, let safePassword = password else {
            self.errors = [NSLocalizedString("An unknown error has occurred.", comment: "")]
            return
        }
        
        let complete = { (allowDuplicate: Bool) in
            return { (error: Error?) in
                guard error == nil else {
                    let timeError = error as? TimeError
                    let is409 = timeError == TimeError.httpFailure("409")
                    let duplicateError = allowDuplicate && is409
                    let message = duplicateError
                        ? NSLocalizedString("Email already associated with an account.", comment: "")
                        : NSLocalizedString("An unknown error has occurred.", comment: "")
                    
                    DispatchQueue.main.async {
                        self.errors = [message]
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    self.authenticated = true
                    self.warehouse.loadData(refresh: true)
                }
            }
        }
        
        if signUp {
            self.warehouse.time?.register(email: safeEmail, password: safePassword, completionHandler: complete(true))
        } else {
            self.warehouse.time?.authenticate(email: safeEmail, password: safePassword, completionHandler: complete(false))
        }
    }
}

#if DEBUG
struct Login_Previews: PreviewProvider {
    struct PreviewWrapper: View {
        var warehouse = Warehouse.getPreviewWarehouse()
        
        @State var authenticated: Bool = false
        
        var body: some View {
            Login(authenticated: $authenticated)
                .environmentObject(warehouse)
//                .environment(\.colorScheme, .dark)
        }
    }
    
    static var previews: some View {
        PreviewWrapper()
    }
}
#endif
