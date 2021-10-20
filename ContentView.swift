//
//  ContentView.swift
//  NavViewARStuff
//
//  Created by Jeremy Heritage on 15/8/20.
//  Copyright © 2020 Jeremy Heritage. All rights reserved.
//

import SwiftUI
import RealityKit

class EnvModel: ObservableObject  {
    
    func updateArchive() {
        print("get data")
    }
    
}

struct ContentView : View {
    
    @State private var currentViewName: String? = nil
    
    @EnvironmentObject var session: FirebaseSession
    
    init() {
        UINavigationBar.appearance().isTranslucent = true
        UINavigationBar.appearance().backgroundColor = .clear
    }
    
    func startUserSession() {
        session.listen()
    }
    
    var body: some View {
        NavigationView {
            VStack {
                AuthView()
                
                Color.yellow
                NavigationLink(
                    destination: ARView(),
                    tag: "ViewAR",
                    selection: $currentViewName
                    ) { EmptyView() }
                
                NavigationLink(
                    destination: ArchiveView(),
                    tag: "ViewArchive",
                    selection: $currentViewName
                    ) { EmptyView() }
                
                
                NavigationLink(
                    destination: NFCView(),
                    tag: "ViewNFC",
                    selection: $currentViewName
                    ) { EmptyView() }
                
                Button("AR Mode") {
                    self.currentViewName = "ViewAR"
                }
                
                Button("Archive") {
                    self.currentViewName = "ViewArchive"
                }
                
                
                Button("NFC") {
                    self.currentViewName = "ViewNFC"
                }
            }
            .navigationBarTitle("App")
        }
        .environmentObject(EnvModel())
        .environmentObject(session)
        .onAppear(perform: startUserSession)
    }
}

struct ARView: View {
    var body: some View {
        VStack {
            ARViewContainer()
            .edgesIgnoringSafeArea(.all)
        }
        .navigationBarTitle("AR")
    }
}

struct ARViewContainer: UIViewRepresentable {
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
}

struct ArchiveView: View {
    
    @EnvironmentObject var envModel: EnvModel
    
    var body: some View {
        VStack {
            Button("Update") {
                self.envModel.updateArchive()
            }
            List {
                Text("Archive")
                Text("Archive")
                Text("Archive")
                Text("Archive")
                Text("Archive")
                Text("Archive")
            }
        }
        .navigationBarTitle("Archive")
    }
}

struct AuthView: View {
    
    @State var inEmail: String = ""
    @State var inPassword: String = ""
    @State var inError: String = ""
    
    @EnvironmentObject var session: FirebaseSession
    
    func signIn() {
        session.signIn(email: inEmail, password: inPassword) {
            result, error in
            if let error = error {
                self.inError = error.localizedDescription
            } else {
                // reset
                self.inEmail = ""
                self.inPassword = ""
            }
        }
    }
    
    var body: some View {
        VStack {
            if (session.session != nil) {
                VStack {
                    Text("Sign in")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color.gray)
                    VStack(spacing: 18) {
                        TextField("Email", text: $inEmail)
                        .font(.system(size: 14))
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 5).strokeBorder(Color.gray, lineWidth: 1))
                        
                        SecureField("Password", text: $inPassword)
                        .font(.system(size: 14))
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 5).strokeBorder(Color.gray, lineWidth: 1))
                            
                    }
                    .padding(.vertical, 64)
                    Button(action: signIn) {
                        Text("Sign in")
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .frame(height: 50)
                            .foregroundColor(.white)
                            .font(.system(size: 14, weight: .bold))
                            .background(LinearGradient(gradient: Gradient(colors: [Color.gray, Color.yellow]), startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(5)
                    }
                }

                if (inError != "") {
                    Text(inError)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.red)
                    .padding()
                }
                
                Spacer()
            } else {
                SignUpView()
            }
        }
    }
}

struct SignUpView: View {
    
    @EnvironmentObject var session: FirebaseSession
    
    @State var email: String = ""
    @State var password: String = ""
    @State var error: String = ""
    
    func signUp() {
        session.signUp(email: email, password: password) {
            result, error in
            if let error = error {
                self.error = error.localizedDescription
            } else {
                self.email = ""
                self.password = ""
            }
        }
    }
    
    var body: some View {
        VStack {
            Text("Sign up")
            .font(.system(size: 32, weight: .heavy))
            .foregroundColor(Color.gray)
            
            Text("Sign up to get started")
            .font(.system(size: 18, weight: .medium))
            .foregroundColor(Color.gray)
            
            VStack(spacing: 18) {
                TextField("Email", text: $email)
                .font(.system(size: 14))
                .padding(22)
                .background(RoundedRectangle(cornerRadius: 5).strokeBorder(Color.gray, lineWidth: 1))
                
                SecureField("Password", text: $password)
                .font(.system(size: 14))
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 5).strokeBorder(Color.gray, lineWidth: 1))
            }
            .padding(.vertical, 64)

            Button(action: signUp) {
                Text("Sign up")
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .frame(height: 50)
                    .foregroundColor(.white)
                    .font(.system(size: 14, weight: .bold))
                    .background(LinearGradient(gradient: Gradient(colors: [Color.gray, Color.yellow]), startPoint: .leading, endPoint: .trailing))
        }
            if (error != "") {
                 Text(error)
                 .font(.system(size: 14, weight: .semibold))
                 .foregroundColor(.red)
                 .padding()
             }
             
             Spacer()
            // bring the feilds in from the side
        }.padding(.horizontal, 32)
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
