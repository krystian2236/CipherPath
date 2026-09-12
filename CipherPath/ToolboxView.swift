import SwiftUI
import UIKit

struct ToolboxView: View {
  @Environment(\.openURL) private var openURL
  @ObservedObject var scanner: NetworkScanner
  @Binding var workspaceRouteRaw: String
  @SceneStorage("CipherPath.toolboxTarget") private var selectedAddress = ""
  @SceneStorage("CipherPath.toolboxExpandedTool") private var expandedToolRaw = ""
  @State private var presentedCommand: ToolboxTool?

  private var selectedDevice: NetworkDevice? {
    scanner.devices.first { $0.address == selectedAddress }
  }

  private var hasNetwork: Bool {
    scanner.context?.isPrivateOrLinkLocal == true
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        LazyVStack(spacing: 12) {
          InfoBanner(
            icon: "arrow.up.circle.fill",
            title: "CipherPath Toolbox",
            message: "Discover → Inspect → Verify. Każdy krok używa wyłącznie danych z bieżącej sieci i wybranego urządzenia."
          )

          targetCard

          ForEach(ToolboxStage.allCases) { stage in
            stageSection(stage)
          }

          InfoBanner(
            icon: "hand.raised.fill",
            title: "Tryb defensywny",
            message: "Uruchamiaj narzędzia tylko we własnej sieci lub za zgodą właściciela. CipherPath nie udostępnia modułów eksploatacji ani łamania haseł."
          )
        }
        .padding(12)
      }
      .background(Color(.systemGroupedBackground))
      .navigationTitle("Toolbox")
      .navigationBarTitleDisplayMode(.inline)
      .navigationDestination(item: $presentedCommand) { tool in
        ToolboxCommandView(
          tool: tool,
          resolution: ToolboxCommandBuilder.resolve(
            tool: tool,
            device: selectedDevice,
            network: scanner.context
          )
        )
      }
      .navigationDestination(isPresented: sshWorkspaceIsPresented) {
        SSHShortcutLibraryView(
          context: scanner.context,
          devices: scanner.devices,
          preferredShortcut: ISHWorkspaceRoute(rawValue: workspaceRouteRaw)?.shortcutID
        )
      }
      .onChange(of: scanner.devices.map(\.address)) { _, addresses in
        if !addresses.contains(selectedAddress) {
          selectedAddress = addresses.first ?? ""
        }
      }
    }
  }

  private var sshWorkspaceIsPresented: Binding<Bool> {
    Binding(
      get: { ISHWorkspaceRoute(rawValue: workspaceRouteRaw) != nil },
      set: { if !$0 { workspaceRouteRaw = "" } }
    )
  }

  private var targetCard: some View {
    ToolCard(
      icon: "scope",
      title: "Bieżący cel",
      subtitle: "Dalsze narzędzia korzystają tylko z tego urządzenia"
    ) {
      if scanner.devices.isEmpty {
        Label("Najpierw uruchom Skan CipherPath.", systemImage: "lock.fill")
          .font(.caption)
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity, alignment: .leading)
      } else {
        Picker("Urządzenie", selection: $selectedAddress) {
          Text("Wybierz urządzenie").tag("")
          ForEach(scanner.devices) { device in
            Text("\(device.primaryName) — \(device.address)").tag(device.address)
          }
        }
        .pickerStyle(.menu)

        if let selectedDevice {
          HStack {
            Label(selectedDevice.address, systemImage: selectedDevice.kind.icon)
            Spacer()
            Text("\(selectedDevice.openPorts.count) usług")
          }
          .font(.caption)
          .foregroundStyle(.secondary)
        }
      }
    }
  }

  private func stageSection(_ stage: ToolboxStage) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      VStack(alignment: .leading, spacing: 2) {
        Text(stage.title).font(.headline)
        Text(stage.subtitle).font(.caption).foregroundStyle(.secondary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 2)

      ForEach(ToolboxTool.tools(for: stage)) { tool in
        toolCard(tool)
      }
    }
  }

  private func toolCard(_ tool: ToolboxTool) -> some View {
    let availability = ToolboxAvailability.evaluate(
      tool: tool,
      device: selectedDevice,
      hasNetwork: hasNetwork
    )
    let expanded = Binding(
      get: { expandedToolRaw == tool.rawValue },
      set: { expandedToolRaw = $0 ? tool.rawValue : "" }
    )

    return DisclosureGroup(isExpanded: expanded) {
      VStack(alignment: .leading, spacing: 9) {
        Text(tool.summary)
          .font(.caption)
          .foregroundStyle(.secondary)

        switch availability {
        case .available:
          Button {
            run(tool)
          } label: {
            Label(actionTitle(for: tool), systemImage: tool == .nativeDiscovery ? "play.fill" : "chevron.right")
              .frame(maxWidth: .infinity)
          }
          .buttonStyle(.borderedProminent)
          .tint(.cyan)
        case .blocked(let reason):
          Label(reason, systemImage: "lock.fill")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
      .padding(.top, 9)
    } label: {
      HStack(spacing: 10) {
        Image(systemName: tool.icon)
          .foregroundStyle(availability.isAvailable ? .cyan : .secondary)
          .frame(width: 34, height: 34)
          .background(
            (availability.isAvailable ? Color.cyan : Color.secondary).opacity(0.1),
            in: RoundedRectangle(cornerRadius: 9)
          )
        VStack(alignment: .leading, spacing: 2) {
          Text(tool.title).font(.subheadline.weight(.semibold))
          Text(tool.runner.rawValue).font(.caption2).foregroundStyle(.secondary)
        }
        Spacer()
        if !availability.isAvailable {
          Image(systemName: "lock.fill").font(.caption2).foregroundStyle(.tertiary)
        }
      }
    }
    .padding(12)
    .background(.background, in: RoundedRectangle(cornerRadius: 14))
    .opacity(availability.isAvailable ? 1 : 0.62)
  }

  private func actionTitle(for tool: ToolboxTool) -> String {
    tool == .nativeDiscovery ? "Rozpocznij skan" : "Przygotuj na agencie"
  }

  private func run(_ tool: ToolboxTool) {
    if tool == .nativeDiscovery {
      Task { await scanner.scan() }
    } else {
      presentedCommand = tool
    }
  }
}

private struct ToolboxCommandView: View {
  @Environment(\.openURL) private var openURL
  let tool: ToolboxTool
  let resolution: ToolboxCommandResolution
  @AppStorage("CipherPath.sshUsername") private var username = ""
  @AppStorage("CipherPath.sshHost") private var host = ""
  @State private var copied = false
  @State private var sshClientUnavailable = false

  var body: some View {
    ScrollView {
      LazyVStack(spacing: 12) {
        InfoBanner(
          icon: tool.icon,
          title: tool.title,
          message: tool.summary
        )

        ToolCard(
          icon: "desktopcomputer",
          title: "Wykonanie",
          subtitle: tool.runner.rawValue
        ) {
          switch resolution {
          case .command(let command):
            Text(command)
              .font(.caption.monospaced())
              .textSelection(.enabled)
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(10)
              .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))

            Button {
              UIPasteboard.general.string = command
              copied = true
            } label: {
              Label(copied ? "Skopiowano" : "Kopiuj polecenie", systemImage: copied ? "checkmark" : "doc.on.doc")
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.cyan)

            Button {
              openAgent()
            } label: {
              Label("Połącz z agentem", systemImage: "rectangle.connected.to.line.below")
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
          case .blocked(let reason):
            Label(reason, systemImage: "lock.fill")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }

        InfoBanner(
          icon: "checkmark.shield",
          title: "Przed uruchomieniem",
          message: "Sprawdź cel i wykonuj polecenie wyłącznie na własnym urządzeniu lub za zgodą właściciela. Polecenia wymagające sudo poproszą o zgodę na agencie."
        )
      }
      .padding(12)
    }
    .background(Color(.systemGroupedBackground))
    .navigationTitle(tool.title)
    .navigationBarTitleDisplayMode(.inline)
    .alert("Brak klienta SSH", isPresented: $sshClientUnavailable) {
      Button("OK", role: .cancel) {}
    } message: {
      Text("Skonfiguruj host i użytkownika w bibliotece SSH, a następnie zainstaluj klienta SSH, np. Termius.")
    }
  }

  private func openAgent() {
    let context = SSHShortcutContext(username: username, host: host, target: nil)
    guard let url = SSHShortcutLibrary.connectionURL(context: context) else {
      sshClientUnavailable = true
      return
    }
    openURL(url) { accepted in
      sshClientUnavailable = !accepted
    }
  }
}
