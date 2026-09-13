import SwiftUI

enum AppTab: Int, Hashable {
  case start = 0
  case paths = 1
  case missions = 2
  case practice = 3
  case achievements = 4

  static let navigationOrder: [AppTab] = [
    .start, .paths, .missions, .practice, .achievements,
  ]

  static func restored(from rawValue: Int) -> AppTab {
    AppTab(rawValue: rawValue) ?? .start
  }
}

enum ISHWorkspaceRoute: RawRepresentable, Hashable {
  case library
  case shortcut(SSHShortcutID)

  static let libraryRawValue = "library"

  init?(rawValue: String) {
    if rawValue == Self.libraryRawValue {
      self = .library
    } else if let shortcutID = SSHShortcutID(rawValue: rawValue) {
      self = .shortcut(shortcutID)
    } else {
      return nil
    }
  }

  var rawValue: String {
    switch self {
    case .library: Self.libraryRawValue
    case .shortcut(let shortcutID): shortcutID.rawValue
    }
  }

  var shortcutID: SSHShortcutID? {
    guard case .shortcut(let shortcutID) = self else { return nil }
    return shortcutID
  }
}

struct AppShellView: View {
  @StateObject private var knownDeviceStore: KnownDeviceStore
  @StateObject private var scanner: NetworkScanner
  @StateObject private var tools = NetworkToolsModel()
  @StateObject private var learningProgressStore: LearningProgressStore
  @SceneStorage("CipherPath.selectedTab") private var selectedTabRaw = AppTab.start.rawValue
  @SceneStorage("CipherPath.ishWorkspaceRoute") private var ishWorkspaceRouteRaw = ""

  init() {
    let store = KnownDeviceStore()
    _knownDeviceStore = StateObject(wrappedValue: store)
    _scanner = StateObject(wrappedValue: NetworkScanner(knownDeviceStore: store))
    _learningProgressStore = StateObject(wrappedValue: LearningProgressStore())
  }

  var body: some View {
    TabView(selection: selectedTab) {
      DashboardView(selectedTab: selectedTab, progressStore: learningProgressStore)
        .tabItem { Label("Start", systemImage: "house.fill") }.tag(AppTab.start)
      LearningPathListView(progressStore: learningProgressStore, accessPolicy: .current)
        .tabItem { Label("Ścieżki", systemImage: "safari.fill") }.tag(AppTab.paths)
      MissionsView(progressStore: learningProgressStore, accessPolicy: .current)
        .tabItem { Label("Misje", systemImage: "target") }.tag(AppTab.missions)
      PracticeHubView(
        scanner: scanner,
        tools: tools,
        knownDeviceStore: knownDeviceStore,
        learningProgressStore: learningProgressStore,
        selectedTab: selectedTab,
        ishWorkspaceRouteRaw: $ishWorkspaceRouteRaw
      )
        .tabItem { Label("Praktyka", systemImage: "chart.bar.fill") }.tag(AppTab.practice)
      AchievementsView(progressStore: learningProgressStore)
        .tabItem { Label("Osiągnięcia", systemImage: "medal.fill") }.tag(AppTab.achievements)
    }
    .tint(.cyan)
    .alert("Problem z zapamiętanymi urządzeniami", isPresented: storeErrorIsPresented) {
      Button("OK") { knownDeviceStore.clearError() }
    } message: {
      Text(knownDeviceStore.errorMessage ?? "Nieznany błąd zapisu.")
    }
    .task { scanner.refreshContext(); tools.refreshLocalContext() }
  }

  private var selectedTab: Binding<AppTab> {
    Binding(
      get: { AppTab.restored(from: selectedTabRaw) },
      set: { selectedTabRaw = $0.rawValue }
    )
  }

  private var storeErrorIsPresented: Binding<Bool> {
    Binding(get: { knownDeviceStore.errorMessage != nil }, set: { if !$0 { knownDeviceStore.clearError() } })
  }
}

private struct PracticeHubView: View {
  @ObservedObject var scanner: NetworkScanner
  @ObservedObject var tools: NetworkToolsModel
  @ObservedObject var knownDeviceStore: KnownDeviceStore
  @ObservedObject var learningProgressStore: LearningProgressStore
  @Binding var selectedTab: AppTab
  @Binding var ishWorkspaceRouteRaw: String

  var body: some View {
    NavigationStack {
      List {
        Section {
          DevLocationLabel(location: .practice)
        }
        Section {
          InfoBanner(
            icon: "lock.shield.fill",
            title: "Tylko własne środowisko",
            message: "Narzędzia służą wyłącznie do Twojej sieci albo systemów objętych zgodą właściciela."
          )
          .listRowInsets(EdgeInsets())
          .listRowBackground(Color.clear)
        }
        Section("Narzędzia CipherPath") {
          NavigationLink("Skan prywatnej sieci") {
            ScannerView(scanner: scanner, knownDeviceStore: knownDeviceStore, selectedTab: $selectedTab)
          }
          NavigationLink("Bezpieczny Toolbox") {
            ToolboxView(scanner: scanner, workspaceRouteRaw: $ishWorkspaceRouteRaw)
          }
          NavigationLink("Urządzenia") {
            DevicesView(scanner: scanner, knownDeviceStore: knownDeviceStore, selectedTab: $selectedTab)
          }
          NavigationLink("Usługi i diagnostyka") {
            ServicesHubView(scanner: scanner, tools: tools)
          }
        }
        Section("Informacje") {
          NavigationLink("Prywatność i bezpieczeństwo") {
            PrivacySecurityView(progressStore: learningProgressStore)
          }
        }
      }
      .navigationTitle("Praktyka")
    }
  }
}

private struct PrivacySecurityView: View {
  @ObservedObject var progressStore: LearningProgressStore
  @Environment(\.openURL) private var openURL

  var body: some View {
    List {
      Section("Twoje dane") {
        Label("Brak konta, reklam, analityki i śledzenia", systemImage: "hand.raised.fill")
        Label("Postęp, historia skanów i urządzenia pozostają lokalnie", systemImage: "iphone")
        Label("CipherPath nie przechowuje haseł ani kluczy prywatnych", systemImage: "key.slash")
      }
      Section("Sieć") {
        Text("Dostęp do sieci lokalnej jest używany dopiero po uruchomieniu narzędzia przez użytkownika.")
        Text("Publiczny adres IP jest pobierany z api64.ipify.org tylko po naciśnięciu odpowiedniego przycisku.")
        Button("Otwórz ustawienia prywatności iOS") {
          if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
          }
        }
      }
      Section("Kontrola użytkownika") {
        Button("Usuń postęp nauki", role: .destructive) {
          progressStore.reset()
        }
        Text("Historię i pozostałe dane lokalne można całkowicie usunąć przez odinstalowanie aplikacji.")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
    }
    .navigationTitle("Prywatność")
    .navigationBarTitleDisplayMode(.inline)
  }
}

private struct DevicesView: View {
  @ObservedObject var scanner: NetworkScanner
  @ObservedObject var knownDeviceStore: KnownDeviceStore
  @Binding var selectedTab: AppTab

  var body: some View {
    NavigationStack {
      Group {
        if scanner.devices.isEmpty {
          ContentUnavailableView {
            Label("Brak urządzeń", systemImage: "desktopcomputer")
          } description: {
            Text("Najpierw wykonaj skan prywatnej sieci lokalnej.")
          } actions: {
            Button("Przejdź do praktyki") { selectedTab = .practice }
              .buttonStyle(.borderedProminent).tint(.cyan)
          }
        } else {
          List(scanner.devices) { device in
            NavigationLink {
              DeviceDetailView(device: device, key: key(for: device), knownDeviceStore: knownDeviceStore)
            } label: {
              DeviceRow(device: device, record: record(for: device), registryStatus: status(for: device))
            }
            .listRowInsets(EdgeInsets(top: 5, leading: 12, bottom: 5, trailing: 12))
            .listRowSeparator(.hidden)
          }
          .listStyle(.plain)
        }
      }
      .navigationTitle("Urządzenia")
      .navigationBarTitleDisplayMode(.inline)
    }
  }

  private func key(for device: NetworkDevice) -> KnownDeviceKey? {
    scanner.networkID.map { KnownDeviceKey(networkID: $0, address: device.address) }
  }

  private func record(for device: NetworkDevice) -> KnownDeviceRecord? {
    key(for: device).flatMap(knownDeviceStore.record)
  }

  private func status(for device: NetworkDevice) -> DeviceRegistryStatus {
    guard let key = key(for: device) else { return .unknown }
    return DeviceRegistryStatus(record: knownDeviceStore.record(for: key), isNew: scanner.newDeviceKeys.contains(key))
  }
}

private struct ServicesHubView: View {
  @ObservedObject var scanner: NetworkScanner
  @ObservedObject var tools: NetworkToolsModel

  var body: some View {
    NavigationStack {
      List {
        Section {
          InfoBanner(icon: "wrench.and.screwdriver.fill", title: "Narzędzia sieciowe", message: "Wszystkie dotychczasowe funkcje są tutaj, w jednym uporządkowanym miejscu.")
            .listRowInsets(EdgeInsets()).listRowBackground(Color.clear)
        }
        Section("Sprawdzanie") {
          serviceLink(title: "Porty", subtitle: "Sprawdź dostępność wybranych usług TCP", icon: "shield.lefthalf.filled") {
            PortScannerView(model: tools)
          }
          serviceLink(title: "Ping i adresy", subtitle: "DNS, lokalny i publiczny IP oraz TCP Ping", icon: "waveform.path.ecg") {
            DiagnosticsView(model: tools)
          }
        }
        Section("Wykrywanie automatyczne") {
          serviceLink(title: "Bonjour", subtitle: "Usługi ogłaszane przez urządzenia w sieci", icon: "bonjour") {
            ServicesView(discovery: scanner.bonjourDiscovery)
          }
        }
      }
      .navigationTitle("Usługi")
      .navigationBarTitleDisplayMode(.inline)
    }
  }

  private func serviceLink<Destination: View>(title: String, subtitle: String, icon: String, @ViewBuilder destination: () -> Destination) -> some View {
    NavigationLink(destination: destination()) {
      HStack(spacing: 11) {
        Image(systemName: icon).foregroundStyle(.cyan).frame(width: 34, height: 34)
          .background(.cyan.opacity(0.1), in: RoundedRectangle(cornerRadius: 9))
        VStack(alignment: .leading, spacing: 2) {
          Text(title).font(.subheadline.weight(.semibold))
          Text(subtitle).font(.caption2).foregroundStyle(.secondary)
        }
      }.padding(.vertical, 3)
    }
  }
}
