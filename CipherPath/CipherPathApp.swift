import SwiftUI

@main
struct CipherPathApp: App {
  @AppStorage("VectorSec.language") private var storedLanguage = AppLanguage.system.rawValue

  var body: some Scene {
    WindowGroup {
      LanguageRootView(language: selectedLanguage)
    }
  }

  private var selectedLanguage: AppLanguage {
    AppLanguage.fromStoredValue(storedLanguage)
  }
}

private struct LanguageRootView: View {
  let language: AppLanguage
  @State private var settingsPresented = false

  var body: some View {
    Group {
      if let locale = language.localeOverride {
        appContent.environment(\.locale, locale)
      } else {
        appContent
      }
    }
  }

  private var appContent: some View {
    AppShellView()
      .overlay(alignment: .topTrailing) {
        Button {
          settingsPresented = true
        } label: {
          Image(systemName: "gearshape.fill")
            .font(.body.weight(.semibold))
            .frame(width: 36, height: 36)
            .background(.thinMaterial, in: Circle())
        }
        .accessibilityLabel("settings.language.accessibility_label")
        .padding(.top, 8)
        .padding(.trailing, 12)
      }
      .sheet(isPresented: $settingsPresented) {
        LanguageSettingsView()
      }
  }
}

private struct LanguageSettingsView: View {
  @Environment(\.dismiss) private var dismiss
  @AppStorage("VectorSec.language") private var storedLanguage = AppLanguage.system.rawValue

  var body: some View {
    NavigationStack {
      Form {
        Section {
          Picker("settings.language.title", selection: $storedLanguage) {
            Text("settings.language.system").tag(AppLanguage.system.rawValue)
            Text("settings.language.polish").tag(AppLanguage.polish.rawValue)
            Text("settings.language.english").tag(AppLanguage.english.rawValue)
          }
          .pickerStyle(.inline)
        } footer: {
          Text("settings.language.footer")
        }
      }
      .navigationTitle("settings.language.title")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("common.ok") { dismiss() }
        }
      }
    }
  }
}
