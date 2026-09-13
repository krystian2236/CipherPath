# CipherPath Pro Points Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Dodać lokalny portfel punktów, nagrody za pierwsze ukończenie misji i płatne podpowiedzi, zachowując nielimitowany tryb CipherPath Dev.

**Architecture:** Reguły ekonomii znajdują się w niezależnym modelu `PointsWallet`, a `LearningProgressStore` jest jedynym punktem zapisu oraz integracji z misjami. Widoki korzystają z wyników domenowych i modeli prezentacyjnych, dzięki czemu nie obliczają salda ani nie decydują o obciążeniu.

**Tech Stack:** Swift 5, SwiftUI, ObservableObject, Codable/UserDefaults, Swift Testing, Xcode 27, iOS 17+

**Spec:** `docs/superpowers/specs/2026-09-13-pro-points-design.md`

## Global Constraints

- Release rozpoczyna z saldem 100 punktów.
- Pierwsze ukończenie misji przyznaje 100 punktów, niezależnie od trybu.
- Podpowiedź kosztuje 20 punktów, a rozwiązanie 50 punktów.
- Saldo Release nigdy nie spada poniżej zera.
- Raz kupiona pomoc dla tej samej misji i trybu nie jest ponownie obciążana.
- CipherPath Dev pozostaje bez blokad i ma nielimitowane punkty.
- Nie dodawać StoreKit, kont, synchronizacji ani nowych misji.
- Każde zadanie kończy się małym commitem Conventional Commits.

---

### Task 1: Model portfela i idempotentna księga

**Files:**
- Create: `CipherPath/PointsModels.swift`
- Create: `CipherPathTests/PointsWalletTests.swift`
- Modify: `CipherPath.xcodeproj/project.pbxproj`

**Interfaces:**
- Produces: `PointsPurchase`, `PointsTransactionKind`, `PointsTransaction`, `PointsPurchaseResult`, `PointsWallet.balance`, `PointsWallet.purchase(_:lessonID:mode:date:)`, `PointsWallet.rewardMission(lessonID:date:)`.
- Consumes: `LabMode` z `CipherPath/LabModels.swift`.

- [ ] **Step 1: Dodać testy salda i zakupów**

Utworzyć `PointsWalletTests` z przypadkami: saldo początkowe 100, hint zmienia saldo na 80, solution zmienia saldo na 50, brak środków zwraca `.insufficient(missing:)`, drugi identyczny zakup zwraca `.alreadyUnlocked`, a nagroda tej samej misji jest przyznana tylko raz również po zmianie trybu.

- [ ] **Step 2: Uruchomić testy i potwierdzić RED**

```bash
xcodebuild test -quiet -project CipherPath.xcodeproj -scheme CipherPath \
  -destination 'platform=iOS Simulator,name=CipherPath iPhone 17e' \
  -only-testing:CipherPathTests/PointsWalletTests \
  -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO
```

Oczekiwany wynik: błąd kompilacji, ponieważ typy portfela jeszcze nie istnieją.

- [ ] **Step 3: Zaimplementować minimalny model**

W `PointsModels.swift` zdefiniować koszty przy `PointsPurchase`, transakcje Codable/Equatable/Identifiable/Sendable i `PointsWallet`. Identyfikatory: `initial`, `reward:<lessonID>` i `purchase:<kind>:<lessonID>:<mode>`. `balance` sumuje `amount`, a każda metoda najpierw sprawdza obecność identyfikatora operacji.

- [ ] **Step 4: Uruchomić testy i potwierdzić GREEN**

Uruchomić polecenie z kroku 2. Oczekiwany wynik: exit 0 i brak nieudanych testów.

- [ ] **Step 5: Sprawdzić diff i utworzyć commit**

```bash
git diff --check
git add CipherPath/PointsModels.swift CipherPathTests/PointsWalletTests.swift CipherPath.xcodeproj/project.pbxproj
git commit -m "feat: add points wallet ledger"
```

---

### Task 2: Trwałość portfela i nagrody za misje

**Files:**
- Modify: `CipherPath/LearningProgressStore.swift`
- Modify: `CipherPathTests/AchievementTests.swift`

**Interfaces:**
- Consumes: `PointsWallet` i `PointsPurchaseResult` z Task 1.
- Produces: `LearningProgress.pointsWallet`, `LearningProgressStore.pointsBalance`, `purchaseAssistance(lessonID:mode:purchase:distribution:)` oraz rozszerzone `completeLab(lessonID:mode:distribution:)`.

- [ ] **Step 1: Dodać testy migracji, zapisu i nagrody**

Dodać testy potwierdzające: starszy JSON bez `pointsWallet` otrzymuje saldo 100; zakup i saldo odtwarzają się po ponownym utworzeniu store; Guided daje 100 punktów; późniejsze Adventure tej samej misji nie daje kolejnych punktów; istniejące XP i medale nie zmieniają zachowania.

- [ ] **Step 2: Uruchomić testy i potwierdzić RED**

```bash
xcodebuild test -quiet -project CipherPath.xcodeproj -scheme CipherPath \
  -destination 'platform=iOS Simulator,name=CipherPath iPhone 17e' \
  -only-testing:CipherPathTests/AchievementTests \
  -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO
```

- [ ] **Step 3: Włączyć portfel do postępu**

Dodać `pointsWallet` do Codable z wartością domyślną `.initial`. Metody store przekazują operacje do portfela i wywołują `save()` tylko po zmianie księgi. `completeLab` przyjmuje jawny `distribution`; App Store przyznaje punkty, Dev nie zapisuje transakcji punktowej.

- [ ] **Step 4: Rozdzielić reset**

`reset()` nadal usuwa cały postęp. `resetPointsForDevelopment()` tworzy świeży portfel bez zmiany misji; wejście UI będzie kompilowane tylko w Debug.

- [ ] **Step 5: Testy i commit**

```bash
xcodebuild test -quiet -project CipherPath.xcodeproj -scheme CipherPath \
  -destination 'platform=iOS Simulator,name=CipherPath iPhone 17e' \
  -only-testing:CipherPathTests/AchievementTests \
  -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO
git diff --check
git add CipherPath/LearningProgressStore.swift CipherPathTests/AchievementTests.swift
git commit -m "feat: persist mission point rewards"
```

---

### Task 3: Zakup pomocy w terminalu i wynik misji

**Files:**
- Modify: `CipherPath/LabTerminalView.swift`
- Modify: `CipherPath/LabModels.swift`
- Modify: `CipherPathTests/LabEngineTests.swift`

**Interfaces:**
- Consumes: `LearningProgressStore.purchaseAssistance` i `PointsPurchaseResult`.
- Produces: `AssistancePurchaseMessage` oraz `LabCompletionSummary` z `pointsReward`, `pointsSpent` i `pointsNet`.

- [ ] **Step 1: Napisać testy modeli prezentacyjnych**

Sprawdzić komunikaty dla zakupu, ponownego odblokowania i brakujących punktów oraz podsumowanie `100 − 20 = 80 pkt`. Potwierdzić, że Dev odblokowuje pomoc bez kosztu.

- [ ] **Step 2: Uruchomić test i potwierdzić RED**

```bash
xcodebuild test -quiet -project CipherPath.xcodeproj -scheme CipherPath \
  -destination 'platform=iOS Simulator,name=CipherPath iPhone 17e' \
  -only-testing:CipherPathTests/LabEngineTests \
  -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO
```

- [ ] **Step 3: Zastąpić bezpośrednie ujawnianie zakupem**

„Podpowiedź” potwierdza koszt 20, a „Pokaż polecenia” koszt 50. Dopiero `.purchased` lub `.alreadyUnlocked` ujawnia treść. `.insufficient(missing:)` pokazuje dokładny brak. Dev zachowuje automatyczne polecenia i odpowiedzi bez kosztów.

- [ ] **Step 4: Rozszerzyć wynik ukończenia**

Po pierwszym ukończeniu pokazać nagrodę, wydatki bieżącej misji i zmianę netto. Kolejne ukończenie nie tworzy ani nie prezentuje nowej nagrody.

- [ ] **Step 5: Testy i commit**

```bash
xcodebuild test -quiet -project CipherPath.xcodeproj -scheme CipherPath \
  -destination 'platform=iOS Simulator,name=CipherPath iPhone 17e' \
  -only-testing:CipherPathTests/LabEngineTests \
  -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO
git diff --check
git add CipherPath/LabTerminalView.swift CipherPath/LabModels.swift CipherPathTests/LabEngineTests.swift
git commit -m "feat: charge points for mission assistance"
```

---

### Task 4: Ekran Punktów i kontrolki Dev

**Files:**
- Create: `CipherPath/PointsView.swift`
- Modify: `CipherPath/DashboardView.swift`
- Modify: `CipherPath.xcodeproj/project.pbxproj`
- Modify: `CipherPathTests/CipherPathTests.swift`

**Interfaces:**
- Consumes: `LearningProgressStore.progress.pointsWallet`.
- Produces: `PointsView`, `PointsHistoryRowModel` i aktywny link karty `points`.

- [ ] **Step 1: Dodać testy konfiguracji i historii**

Potwierdzić, że `points` jest aktywne, `store` pozostaje nieaktywne, historia jest sortowana malejąco po dacie, a kwoty mają format `+100 pkt` i `−20 pkt`.

- [ ] **Step 2: Uruchomić test i potwierdzić RED**

```bash
xcodebuild test -quiet -project CipherPath.xcodeproj -scheme CipherPath \
  -destination 'platform=iOS Simulator,name=CipherPath iPhone 17e' \
  -only-testing:CipherPathTests/ContentAccessTests \
  -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO
```

- [ ] **Step 3: Zbudować widok punktów**

Widok pokazuje saldo lub `∞` w Dev, krótkie objaśnienie i operacje od najnowszej. Pusty stan objaśnia zdobywanie punktów. Wiersz pokazuje rodzaj, nazwę misji, datę i kwotę.

- [ ] **Step 4: Dodać kontrolki tylko dla Debug**

W `#if DEBUG` dodać „Dodaj 100 pkt” i „Wyzeruj portfel testowy”, oba z potwierdzeniem. Release nie może zawierać wejścia do tych akcji.

- [ ] **Step 5: Podłączyć ekran Start**

Karta punktów staje się `NavigationLink`, pokazuje saldo i właściwą etykietę dostępności. Sklep pozostaje statyczny, wyszarzony i oznaczony „Wkrótce”.

- [ ] **Step 6: Testy i commit**

```bash
xcodebuild test -quiet -project CipherPath.xcodeproj -scheme CipherPath \
  -destination 'platform=iOS Simulator,name=CipherPath iPhone 17e' \
  -only-testing:CipherPathTests/ContentAccessTests \
  -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO
git diff --check
git add CipherPath/PointsView.swift CipherPath/DashboardView.swift CipherPath.xcodeproj/project.pbxproj CipherPathTests/CipherPathTests.swift
git commit -m "feat: add points dashboard and history"
```

---

### Task 5: Pełna weryfikacja Pro 25%

**Files:**
- Modify only if verification exposes a defect; keep fixes scoped and test-first.

**Interfaces:**
- Consumes: wszystkie elementy z Tasks 1–4.
- Produces: zweryfikowany etap Pro 25%, bez publikacji.

- [ ] **Step 1: Uruchomić pełne testy**

```bash
xcodebuild test -quiet -project CipherPath.xcodeproj -scheme CipherPath \
  -destination 'platform=iOS Simulator,name=CipherPath iPhone 17e' \
  -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO
```

- [ ] **Step 2: Uruchomić kontrolę przed pushem**

```bash
git diff --check
./scripts/pre-push-check.sh
```

- [ ] **Step 3: Sprawdzić ręcznie Dev**

Na fizycznym iPhonie uruchomić CipherPath Dev, otworzyć Punkty, wejść w jedną misję, ujawnić pomoc, ukończyć misję i potwierdzić brak blokad oraz oznaczenie `∞`.

- [ ] **Step 4: Sprawdzić Release bez publikacji**

W symulatorze potwierdzić saldo 100, koszt 20/50, odmowę bez środków i brak kontrolek Dev. Nie instalować Release na fizycznym iPhonie ani nie wysyłać do TestFlight.

- [ ] **Step 5: Sprawdzić stan Git**

```bash
git status --short --branch
git log --oneline -5
```

Oczekiwany wynik: wszystkie commity funkcjonalne istnieją, testy są zielone, a pozostały diff obejmuje wyłącznie zatwierdzone dokumenty albo worktree jest czysty.
