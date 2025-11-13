//
//  SettingsView.swift
//  test-cam
//
//  Configure PocketBase server URL
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var serverURL: String = ""
    @State private var showingSaved = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("http://192.168.1.100:8090", text: $serverURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                } header: {
                    Text("PocketBase Server URL")
                } footer: {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Enter the URL of your PocketBase server")
                        Text("Example: http://192.168.1.100:8090")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Current: \(UserDefaults.standard.string(forKey: "pocketbase_url") ?? "Not set")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Section {
                    Button(action: saveSettings) {
                        HStack {
                            Spacer()
                            Text("Save")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(serverURL.isEmpty)
                }

                if showingSaved {
                    Section {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Settings saved!")
                        }
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Setup Instructions")
                            .font(.headline)

                        Text("1. Install PocketBase on your Ubuntu server")
                        Text("2. Create collections: events, participants, photos")
                        Text("3. Configure CORS to allow your app")
                        Text("4. Enter your server URL above")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                } header: {
                    Text("Help")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                serverURL = UserDefaults.standard.string(forKey: "pocketbase_url") ?? ""
            }
        }
    }

    private func saveSettings() {
        PocketBaseService.shared.setServerURL(serverURL)
        showingSaved = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showingSaved = false
        }
    }
}

#Preview {
    SettingsView()
}
