import SwiftUI

struct FutureFeaturePreview: Identifiable, Equatable, Sendable {
  let id: String
  let title: String
  let subtitle: String
  let icon: String
  let isEnabled: Bool
}

enum FutureFeatureCatalog {
  static let previews = [
    FutureFeaturePreview(
      id: "points",
      title: "Punkty",
      subtitle: "Zdobywaj w misjach i wykorzystuj na podpowiedzi",
      icon: "sparkles",
      isEnabled: true
    ),
    FutureFeaturePreview(
      id: "store",
      title: "Sklep",
      subtitle: "Pro i subskrypcja",
      icon: "cart.fill",
      isEnabled: false
    ),
  ]
}

struct DashboardView: View {
  @Binding var selectedTab: AppTab
  @ObservedObject var progressStore: LearningProgressStore
  @ObservedObject var entitlementStore: StoreEntitlementStore

  private let featuredLesson = StarterCurriculum.lessons.first {
    $0.id == "blue-team-suspicious-login"
  } ?? StarterCurriculum.lessons[0]

  var body: some View {
    NavigationStack {
      ScrollView {
        LazyVStack(alignment: .leading, spacing: 22) {
          DevLocationLabel(location: .dashboard)
          header
          missionCard
          missionStages
          achievementSection
          futureFeaturesSection
          footer
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 20)
      }
      .background(Color(red: 0.025, green: 0.045, blue: 0.075).ignoresSafeArea())
      .toolbar(.hidden, for: .navigationBar)
    }
    .preferredColorScheme(.dark)
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack(alignment: .firstTextBaseline) {
        Text("Cipher") + Text("Path").foregroundStyle(.indigo)
        Spacer()
        Text("Małe kroki.\nWiększe możliwości.")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      .font(.largeTitle.bold())
      Text("PRAWO  •  BEZPIECZEŃSTWO  •  PRAKTYKA")
        .font(.caption2.weight(.semibold))
        .tracking(2)
        .foregroundStyle(.secondary)
    }
  }

  private var missionCard: some View {
    VStack(alignment: .leading, spacing: 14) {
      DevLocationLabel(location: .dashboardMission)
      Text("Dzisiejsza misja").font(.largeTitle.bold())
      Text("Realna wiedza. Bezpieczniejszy świat.").foregroundStyle(.secondary)
      VStack(alignment: .leading, spacing: 12) {
        Label("BLUE TEAM • SYMULACJA OFFLINE", systemImage: "lock.shield.fill")
          .font(.caption2.bold())
          .foregroundStyle(.indigo)
        Text(featuredLesson.title).font(.title2.bold())
        Text(featuredLesson.summary).font(.subheadline).foregroundStyle(.secondary)
        Label("8 min", systemImage: "clock")
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(.secondary)
        NavigationLink {
          MissionBriefingView(lesson: featuredLesson, progressStore: progressStore)
        } label: {
          HStack {
            Spacer()
            Text("Zobacz odprawę").fontWeight(.semibold)
            Image(systemName: "chevron.right")
            Spacer()
          }
          .padding(.vertical, 13)
        }
        .buttonStyle(.borderedProminent)
        .tint(.indigo)
      }
      .padding(18)
      .background(
        LinearGradient(
          colors: [.indigo.opacity(0.2), .cyan.opacity(0.08), .black.opacity(0.35)],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        ),
        in: RoundedRectangle(cornerRadius: 22)
      )
      .overlay(RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(0.12)))
    }
  }

  private var missionStages: some View {
    HStack(alignment: .top, spacing: 4) {
      ForEach(Array(LessonStage.allCases.enumerated()), id: \.element) { index, stage in
        VStack(spacing: 7) {
          Image(systemName: ["doc.text.fill", "magnifyingglass", "flag.fill", "lightbulb.fill"][index])
            .font(.headline)
            .foregroundStyle(index == 0 ? .white : .secondary)
            .frame(width: 46, height: 46)
            .background(index == 0 ? Color.indigo : Color.clear, in: Circle())
            .overlay(Circle().stroke(index == 0 ? Color.indigo : Color.secondary.opacity(0.45), lineWidth: 2))
          Text(stage.title).font(.caption2.bold()).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
      }
    }
  }

  private var achievementSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      sectionHeader("Osiągnięcia", destination: .achievements)
      HStack(spacing: 10) {
        ForEach(AchievementCatalog.evaluateAll(progressStore.progress), id: \.id) { achievement in
          achievementCard(
            achievement.title,
            icon: achievement.isUnlocked ? "medal.fill" : "lock.fill",
            color: achievementColor(achievement.rarity),
            unlocked: achievement.isUnlocked
          )
        }
      }
    }
  }

  private var futureFeaturesSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("CipherPath Pro").font(.title3.bold())
      HStack(spacing: 10) {
        ForEach(FutureFeatureCatalog.previews) { feature in
          if feature.id == "points" {
            NavigationLink {
              PointsView(progressStore: progressStore)
            } label: {
              futureFeatureCard(feature)
            }
            .buttonStyle(.plain)
          } else if feature.id == "store", storeIsAvailable {
            NavigationLink {
              StoreView(entitlementStore: entitlementStore)
            } label: {
              futureFeatureCard(feature, enabledOverride: true)
            }
            .buttonStyle(.plain)
          } else {
            futureFeatureCard(feature)
          }
        }
      }
    }
  }

  private var storeIsAvailable: Bool {
    AppDistributionMode.currentBuild == .developer || entitlementStore.isConfigured
  }

  private var storeAccessBadge: String {
    switch entitlementStore.accessPolicy.tier {
    case .free: "FREE"
    case .testFlightDemo: "DEMO"
    case .pro: "PRO"
    case .subscription: "SUB"
    }
  }

  private func futureFeatureCard(
    _ feature: FutureFeaturePreview,
    enabledOverride: Bool? = nil
  ) -> some View {
    let isEnabled = enabledOverride ?? feature.isEnabled

    return VStack(alignment: .leading, spacing: 9) {
      HStack {
        Image(systemName: feature.icon)
          .font(.title2)
          .foregroundStyle(isEnabled ? .cyan : .secondary)
        Spacer()
        if isEnabled, feature.id == "points" {
          Text(AppDistributionMode.currentBuild == .developer ? "∞" : "\(progressStore.pointsBalance)")
            .font(.caption.bold())
            .foregroundStyle(.cyan)
        } else if isEnabled, feature.id == "store" {
          Text(storeAccessBadge)
            .font(.caption2.bold())
            .foregroundStyle(.cyan)
        } else {
          Label("Wkrótce", systemImage: "lock.fill")
            .font(.caption2.bold())
            .foregroundStyle(.secondary)
        }
      }
      Text(feature.title).font(.headline)
      Text(feature.subtitle)
        .font(.caption)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }
    .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
    .padding(14)
    .background(.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 16))
    .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.08)))
    .accessibilityElement(children: .combine)
    .accessibilityHint(isEnabled ? "Otwiera funkcję" : "Funkcja jeszcze niedostępna")
  }

  private func achievementCard(
    _ title: String,
    icon: String,
    color: Color,
    unlocked: Bool
  ) -> some View {
    VStack(spacing: 8) {
      Image(systemName: icon).font(.title2).foregroundStyle(unlocked ? color : .secondary)
      Text(title).font(.caption2.bold()).multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity, minHeight: 84)
    .padding(8)
    .background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 14))
    .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.1)))
  }

  private func achievementColor(_ rarity: AchievementRarity) -> Color {
    switch rarity {
    case .bronze: .orange
    case .silver: .gray
    case .gold: .yellow
    }
  }

  private func sectionHeader(_ title: String, destination: AppTab) -> some View {
    HStack {
      Text(title).font(.title3.bold())
      Spacer()
      Button("Zobacz wszystkie") { selectedTab = destination }
        .font(.caption.bold())
        .foregroundStyle(.indigo)
    }
  }

  private var footer: some View {
    Label("Systematyczna nauka dziś, większe możliwości jutro.", systemImage: "leaf.fill")
      .font(.footnote)
      .foregroundStyle(.secondary)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(16)
      .background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 16))
  }
}

private struct StoreView: View {
  @ObservedObject var entitlementStore: StoreEntitlementStore

  var body: some View {
    List {
      Section("Dostęp") {
        LabeledContent("Aktualny poziom", value: accessTitle)
        if entitlementStore.snapshot.hasLifetimePro {
          Label("Pro — zakup bezterminowy aktywny", systemImage: "checkmark.seal.fill")
        }
        if entitlementStore.snapshot.hasActiveSubscription {
          Label("Subskrypcja aktywna", systemImage: "checkmark.circle.fill")
        }
      }

      Section("Produkty") {
        if !entitlementStore.isConfigured {
          Text("Product ID nie są jeszcze skonfigurowane. W buildzie Store sklep pozostaje nieaktywny.")
            .foregroundStyle(.secondary)
        } else if entitlementStore.isLoadingProducts {
          ProgressView("Pobieranie produktów…")
        } else if entitlementStore.products.isEmpty {
          Text(entitlementStore.lastError ?? "Brak produktów zwróconych przez StoreKit.")
            .foregroundStyle(.secondary)
        } else {
          ForEach(entitlementStore.products, id: \.id) { product in
            HStack {
              VStack(alignment: .leading, spacing: 3) {
                Text(product.displayName).font(.headline)
                Text(product.description).font(.caption).foregroundStyle(.secondary)
              }
              Spacer()
              Button(product.displayPrice) {
                Task { _ = await entitlementStore.purchase(productID: product.id) }
              }
              .disabled(entitlementStore.isPurchasing)
            }
          }
        }
      }

      Section {
        Button("Odśwież produkty i dostęp") {
          Task {
            await entitlementStore.loadProducts()
            await entitlementStore.refresh()
          }
        }
        .disabled(entitlementStore.isLoadingProducts || entitlementStore.isPurchasing)

        Button("Przywróć zakupy") {
          Task { _ = await entitlementStore.restorePurchases() }
        }
        .disabled(entitlementStore.isPurchasing)
      } footer: {
        Text("Ceny i nazwy pochodzą bezpośrednio ze StoreKit. Przywracanie zakupów jest uruchamiane tylko po Twoim poleceniu.")
      }
    }
    .navigationTitle("CipherPath Pro")
    .navigationBarTitleDisplayMode(.inline)
  }

  private var accessTitle: String {
    switch entitlementStore.accessPolicy.tier {
    case .free: "Free"
    case .testFlightDemo: "TestFlight Demo"
    case .pro: "Pro"
    case .subscription: "Subskrypcja"
    }
  }
}

extension LearningPath {
  var shortTitle: String {
    switch self {
    case .webSecurity: "Web"
    case .mobileSecurity: "Mobile"
    default: title
    }
  }

  var iconName: String {
    switch self {
    case .fundamentals: "book.fill"
    case .blueTeam: "shield.fill"
    case .redTeam: "xmark.shield.fill"
    case .webSecurity: "globe"
    case .mobileSecurity: "iphone"
    }
  }

  var tint: Color {
    switch self {
    case .fundamentals: .mint
    case .blueTeam: .blue
    case .redTeam: .red
    case .webSecurity: .purple
    case .mobileSecurity: .cyan
    }
  }
}
