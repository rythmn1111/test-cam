//
//  HomeView.swift
//  test-cam
//
//  Main landing page
//

import SwiftUI

struct HomeView: View {
    @State private var showingCreateEvent = false
    @State private var showingJoinEvent = false
    @State private var showingSettings = false

    private let disposableYellow = Color(red: 1.0, green: 0.85, blue: 0.2)
    private let disposableOrange = Color(red: 1.0, green: 0.6, blue: 0.0)

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [disposableYellow, disposableOrange.opacity(0.6)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 30) {
                    Spacer()

                    // App Icon/Logo
                    VStack(spacing: 10) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                            .shadow(radius: 10)

                        Text("SnapParty")
                            .font(.system(size: 48, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(radius: 5)

                        Text("Disposable Camera for Events")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }

                    Spacer()

                    // Action Buttons
                    VStack(spacing: 20) {
                        Button(action: { showingCreateEvent = true }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                Text("Create Event")
                                    .font(.title3)
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(15)
                            .shadow(radius: 5)
                        }

                        Button(action: { showingJoinEvent = true }) {
                            HStack {
                                Image(systemName: "qrcode.viewfinder")
                                    .font(.title2)
                                Text("Join Event")
                                    .font(.title3)
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(15)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                        }
                    }
                    .padding(.horizontal, 40)

                    Spacer()

                    // Settings Button
                    Button(action: { showingSettings = true }) {
                        HStack {
                            Image(systemName: "gear")
                            Text("Server Settings")
                        }
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.bottom, 30)
                }
            }
            .sheet(isPresented: $showingCreateEvent) {
                CreateEventView()
            }
            .sheet(isPresented: $showingJoinEvent) {
                JoinEventView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
}

#Preview {
    HomeView()
}
