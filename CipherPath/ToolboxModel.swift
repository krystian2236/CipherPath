import Foundation

enum ToolboxStage: Int, CaseIterable, Identifiable, Sendable {
  case discover, inspect, verify

  var id: Self { self }

  var title: String {
    switch self {
    case .discover: "Discover"
    case .inspect: "Inspect"
    case .verify: "Verify"
    }
  }

  var subtitle: String {
    switch self {
    case .discover: "Znajdź własną sieć i aktywne urządzenia"
    case .inspect: "Sprawdź wybrany host, porty i usługi"
    case .verify: "Dobierz analizę do faktycznie wykrytej usługi"
    }
  }
}

enum ToolboxRunner: String, Sendable {
  case iphone = "iPhone"
  case agent = "Agent Mac/Kali"
}

enum ToolboxTool: String, CaseIterable, Identifiable, Sendable {
  case nativeDiscovery
  case nmapDiscovery
  case netdiscover
  case nmapCommonPorts
  case nmapServices
  case reverseDNS
  case traceroute
  case dig
  case curlHeaders
  case whatWeb
  case sslScan
  case nikto
  case enum4Linux

  var id: Self { self }

  var stage: ToolboxStage {
    switch self {
    case .nativeDiscovery, .nmapDiscovery, .netdiscover: .discover
    case .nmapCommonPorts, .nmapServices, .reverseDNS, .traceroute: .inspect
    case .dig, .curlHeaders, .whatWeb, .sslScan, .nikto, .enum4Linux: .verify
    }
  }

  var title: String {
    switch self {
    case .nativeDiscovery: "Skan Northbyte Lab"
    case .nmapDiscovery: "Nmap — urządzenia"
    case .netdiscover: "Netdiscover"
    case .nmapCommonPorts: "Nmap — porty"
    case .nmapServices: "Nmap — usługi"
    case .reverseDNS: "Reverse DNS"
    case .traceroute: "Traceroute"
    case .dig: "Dig"
    case .curlHeaders: "Curl — nagłówki"
    case .whatWeb: "WhatWeb"
    case .sslScan: "SSLScan"
    case .nikto: "Nikto — lekki audyt"
    case .enum4Linux: "Enum4linux-ng"
    }
  }

  var summary: String {
    switch self {
    case .nativeDiscovery: "Natywnie wykrywa urządzenia i typowe porty w prywatnej sieci."
    case .nmapDiscovery: "Potwierdza aktywne hosty bez skanowania portów."
    case .netdiscover: "Pokazuje urządzenia widoczne przez ARP w sieci lokalnej."
    case .nmapCommonPorts: "Sprawdza bezpieczny zestaw najczęstszych portów TCP."
    case .nmapServices: "Lekko rozpoznaje usługi na znalezionych portach."
    case .reverseDNS: "Szuka nazwy hosta dla wybranego prywatnego adresu."
    case .traceroute: "Pokazuje drogę pakietów do wybranego hosta."
    case .dig: "Sprawdza odpowiedzi DNS urządzenia oferującego usługę DNS."
    case .curlHeaders: "Pobiera wyłącznie nagłówki odpowiedzi HTTP lub HTTPS."
    case .whatWeb: "Rozpoznaje technologie udostępnionej strony WWW."
    case .sslScan: "Sprawdza konfigurację TLS wykrytej usługi szyfrowanej."
    case .nikto: "Wykonuje podstawowy audyt własnej usługi WWW."
    case .enum4Linux: "Odczytuje podstawowe informacje z wykrytej usługi SMB."
    }
  }

  var icon: String {
    switch self {
    case .nativeDiscovery: "dot.radiowaves.left.and.right"
    case .nmapDiscovery, .nmapCommonPorts, .nmapServices: "scope"
    case .netdiscover: "network"
    case .reverseDNS, .dig: "textformat.abc"
    case .traceroute: "point.topleft.down.to.point.bottomright.curvepath"
    case .curlHeaders, .whatWeb, .nikto: "globe"
    case .sslScan: "lock.shield"
    case .enum4Linux: "externaldrive.connected.to.line.below"
    }
  }

  var runner: ToolboxRunner {
    self == .nativeDiscovery ? .iphone : .agent
  }

  static func tools(for stage: ToolboxStage) -> [ToolboxTool] {
    allCases.filter { $0.stage == stage }
  }
}

enum ToolboxAvailability: Equatable, Sendable {
  case available
  case blocked(String)

  var isAvailable: Bool {
    if case .available = self { return true }
    return false
  }

  static func evaluate(
    tool: ToolboxTool,
    device: NetworkDevice?,
    hasNetwork: Bool
  ) -> ToolboxAvailability {
    guard hasNetwork else {
      return .blocked("Połącz iPhone’a z prywatną siecią Wi‑Fi.")
    }

    switch tool {
    case .nativeDiscovery, .nmapDiscovery, .netdiscover:
      return .available
    case .nmapCommonPorts, .reverseDNS, .traceroute:
      return device == nil ? .blocked("Najpierw wykryj i wybierz urządzenie.") : .available
    case .nmapServices:
      guard let device else { return .blocked("Najpierw wykryj i wybierz urządzenie.") }
      return device.openPorts.isEmpty
        ? .blocked("Najpierw wykryj otwarte porty tego urządzenia.")
        : .available
    case .dig:
      return requiring(device: device, ports: [53], label: "DNS na porcie 53")
    case .curlHeaders, .whatWeb, .nikto:
      return requiring(device: device, ports: [80, 443, 8080, 8443], label: "HTTP lub HTTPS")
    case .sslScan:
      return requiring(device: device, ports: [443, 8443], label: "TLS na porcie 443 lub 8443")
    case .enum4Linux:
      return requiring(device: device, ports: [139, 445], label: "SMB na porcie 139 lub 445")
    }
  }

  private static func requiring(
    device: NetworkDevice?,
    ports: Set<UInt16>,
    label: String
  ) -> ToolboxAvailability {
    guard let device else {
      return .blocked("Najpierw wykryj i wybierz urządzenie.")
    }
    return Set(device.openPorts).isDisjoint(with: ports)
      ? .blocked("Wymagane: \(label) na wybranym urządzeniu.")
      : .available
  }
}

enum ToolboxCommandResolution: Equatable, Sendable {
  case command(String)
  case blocked(String)
}

enum ToolboxCommandBuilder {
  static func resolve(
    tool: ToolboxTool,
    device: NetworkDevice?,
    network: NetworkContext?
  ) -> ToolboxCommandResolution {
    let availability = ToolboxAvailability.evaluate(
      tool: tool,
      device: device,
      hasNetwork: network?.isPrivateOrLinkLocal == true
    )
    guard availability.isAvailable else {
      if case .blocked(let reason) = availability { return .blocked(reason) }
      return .blocked("Narzędzie jest niedostępne.")
    }

    if tool == .nativeDiscovery {
      return .blocked("To narzędzie działa bezpośrednio w Northbyte Lab.")
    }
    if tool == .nmapDiscovery, let network {
      return .command("nmap -sn \(quoted(network.scanRangeDescription))")
    }
    if tool == .netdiscover, let network {
      return .command("sudo netdiscover -r \(quoted(network.scanRangeDescription))")
    }
    guard let device, ISHTargetValidator.isPrivateHost(device.address) else {
      return .blocked("Wybierz pojedynczy prywatny adres urządzenia.")
    }

    let host = quoted(device.address)
    switch tool {
    case .nmapCommonPorts:
      return .command("nmap --unprivileged -sT -Pn --open -p '22,53,80,139,443,445,548,631,8080,8443,9100' \(host)")
    case .nmapServices:
      let ports = device.openPorts.sorted().map(String.init).joined(separator: ",")
      return .command("nmap --unprivileged -sT -Pn -sV --version-light --open -p '\(ports)' \(host)")
    case .reverseDNS:
      return .command("dig -x \(host) +short")
    case .traceroute:
      return .command("traceroute \(host)")
    case .dig:
      return .command("dig @\(host) version.bind chaos txt")
    case .curlHeaders:
      let scheme = preferredWebPort(for: device) == 443 || preferredWebPort(for: device) == 8443 ? "https" : "http"
      return .command("curl --head --connect-timeout 5 \(quoted("\(scheme)://\(device.address):\(preferredWebPort(for: device))"))")
    case .whatWeb:
      return .command("whatweb --no-errors \(host)")
    case .sslScan:
      let port: UInt16 = device.openPorts.contains(443) ? 443 : 8443
      return .command("sslscan --no-colour \(quoted("\(device.address):\(port)"))")
    case .nikto:
      return .command("nikto -ask no -host \(host)")
    case .enum4Linux:
      return .command("enum4linux-ng -A \(host)")
    case .nativeDiscovery, .nmapDiscovery, .netdiscover:
      return .blocked("Brak polecenia dla wybranego narzędzia.")
    }
  }

  private static func preferredWebPort(for device: NetworkDevice) -> UInt16 {
    [443, 8443, 80, 8080].first(where: device.openPorts.contains) ?? 80
  }

  private static func quoted(_ value: String) -> String {
    "'\(value.replacingOccurrences(of: "'", with: "'\"'\"'"))'"
  }
}
