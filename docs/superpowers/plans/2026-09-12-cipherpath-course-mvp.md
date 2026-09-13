# CipherPath Course MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Zbudować natywny kurs cyberbezpieczeństwa na iPhone z pięcioma ścieżkami, dziesięcioma dostępnymi lekcjami, piętnastoma zapowiedziami, lokalnym postępem i medalami za umiejętności.

**Architecture:** Aplikacja pozostaje natywnym projektem SwiftUI bez zewnętrznych zależności. Niezmienne definicje kursu są oddzielone od lokalnego stanu użytkownika; widoki odczytują oba źródła i prowadzą przez jeden typowany przebieg lekcji. Dotychczasowe narzędzia NetScope pozostają dostępne w zakładce Praktyka, ale nie są uruchamiane automatycznie przez lekcje.

**Tech Stack:** Swift 6, SwiftUI, Observation/Combine, Foundation, UserDefaults, Swift Testing, XCTest, Xcode iOS target.

**Spec:** `docs/superpowers/specs/2026-09-12-cipherpath-course-design.md`

## Global Constraints

- Główna platforma: iPhone na Apple Silicon; aplikacja natywna SwiftUI.
- Tylko legalne symulacje offline, własne urządzenia i środowiska z udzieloną zgodą.
- Brak publicznych celów, phishingu, persistence, eksfiltracji, brute force i automatycznej eksploatacji.
- Każda ścieżka pokazuje dokładnie 5 lekcji; lekcje 1–2 są dostępne, a 3–5 wyszarzone.
- Każda dostępna lekcja prowadzi: Poznaj → Sprawdź → Znajdź flagę → Wyjaśnienie.
- MVP przechowuje postęp wyłącznie lokalnie i nie dodaje konta, chmury, rankingu, płatności ani mentora AI.
- Nie inicjalizować Git, nie commitować, nie publikować i nie instalować bez osobnego polecenia użytkownika.

---

### Task 1 (25%): Course Domain and Catalog

**Files:**
- Modify: `CipherPath/LearningModels.swift`
- Modify: `CipherPathTests/CipherPathTests.swift`

**Interfaces:**
- Produces: `LearningPath`, `LessonAvailability`, `LessonStage`, `LearningLesson`, `StarterCurriculum.paths`, `StarterCurriculum.lessons`, `StarterCurriculum.lessons(in:)`.
- Consumes: wyłącznie `Foundation`.

- [x] **Step 1: Write failing catalog tests**

  Dodać osobne testy zachowania: katalog zawiera 5 ścieżek i 25 lekcji; każda ścieżka ma 2 dostępne i 3 zapowiedziane lekcje; identyfikatory są unikalne; dostępne lekcje mają cztery wymagane etapy; wszystkie lekcje korzystają tylko z `offlineSimulation` lub `ownedLab`.

- [x] **Step 2: Run the focused test target and verify RED**

  Run:

  ```zsh
  xcodebuild test -project CipherPath.xcodeproj -scheme CipherPath -destination 'platform=iOS Simulator,name=iPhone 18 Pro' -only-testing:CipherPathTests/StarterCurriculumTests
  ```

  Expected: kompilacja testów kończy się błędem, ponieważ nowe typy i właściwości nie istnieją.

- [x] **Step 3: Implement the minimal typed catalog**

  Zastąpić cztery moduły pięcioma wartościami `LearningPath`: `fundamentals`, `blueTeam`, `redTeam`, `webSecurity`, `mobileSecurity`. Dodać `LessonAvailability` z wartościami `available` i `comingSoon`, `LessonStage` z czterema wymaganymi etapami oraz 25 jawnych rekordów kursu. Każdy rekord ma stabilne ID, tytuł, krótkie streszczenie, środowisko, kolejność 1–5, dostępność i etapy.

- [x] **Step 4: Run focused tests and verify GREEN**

  Uruchomić to samo polecenie. Expected: wszystkie testy `StarterCurriculumTests` przechodzą w uruchomionym symulatorze. Jeżeli symulator jest niedostępny, wykonać `build-for-testing` i opisać wynik wyłącznie jako kompilację, nie jako zaliczone testy.

- [x] **Step 5: Check whitespace and file scope**

  Run:

  ```zsh
  git diff --check
  ```

  Jeżeli repozytorium nadal nie istnieje, użyć `xcrun swift-format lint` tylko dla dwóch zmienionych plików i jawnie odnotować brak możliwości wykonania `git diff --check`.

### Task 2 (50%): Course Navigation and Approved Home Screen

**Files:**
- Modify: `CipherPath/AppShellView.swift`
- Modify: `CipherPath/DashboardView.swift`
- Create: `CipherPath/LearningPathListView.swift`
- Create: `CipherPath/LearningPathDetailView.swift`
- Create: `CipherPath/MissionsView.swift`
- Create: `CipherPath/AchievementsView.swift`
- Modify: `CipherPathTests/CipherPathTests.swift`

**Interfaces:**
- Consumes: `StarterCurriculum.paths`, `StarterCurriculum.lessons(in:)`.
- Produces: pięć zakładek `start`, `paths`, `missions`, `practice`, `achievements` oraz nawigację Start → Ścieżka.

- [x] **Step 1: Write failing navigation tests**

  Sprawdzić kolejność i tytuły pięciu zakładek oraz przywracanie nieznanej zakładki do Start.

- [x] **Step 2: Verify RED with focused tests**

  Uruchomić tylko `SessionRestorationTests`; oczekiwany błąd dotyczy starego zestawu zakładek.

- [x] **Step 3: Implement five-tab shell and course screens**

  Dopasować ekran Start do `docs/design/cipherpath-approved-home.png`: ciemne tło, karta „Dzisiejsza misja”, postęp, skróty ścieżek i ostatni medal. Użyć SF Symbols dla ikon. Przenieść istniejące bezpieczne narzędzia do zakładki Praktyka bez usuwania ich kodu.

- [x] **Step 4: Verify GREEN and build**

  Uruchomić testy nawigacji, a następnie unsigned Debug build dla symulatora.

- [ ] **Step 5: Capture and compare Start screen**

  Uruchomić aplikację w tym samym rozmiarze iPhone co makieta, zapisać zrzut i porównać go z referencją. Zapisać `design-qa.md`; nie uznawać etapu za zakończony przy błędach P0–P2.

### Task 3 (75%): Lesson Mission Flow and Local Progress

**Files:**
- Create: `CipherPath/LessonFlowView.swift`
- Create: `CipherPath/LearningProgressStore.swift`
- Modify: `CipherPath/LearningPathDetailView.swift`
- Modify: `CipherPath/MissionsView.swift`
- Modify: `CipherPathTests/CipherPathTests.swift`

**Interfaces:**
- Consumes: `LearningLesson.id`, `LearningLesson.stages`.
- Produces: `LearningProgress`, `LearningProgressStore.complete(stage:lessonID:)`, `LearningProgressStore.reset()`, przepływ Ścieżka → Lekcja → Misja → Wynik.

- [x] **Step 1: Write failing progress tests**

  Sprawdzić kolejność etapów, brak pomijania etapów, idempotentne ukończenie, zapis i odtworzenie postępu oraz brak możliwości rozpoczęcia `comingSoon`.

- [x] **Step 2: Verify RED**

  Uruchomić tylko nową suitę `LearningProgressTests`; oczekiwany błąd: brak `LearningProgressStore`.

- [x] **Step 3: Implement minimal local progress**

  Kodować stan jako `Codable`, zapisywać do osobnego klucza UserDefaults, wstrzykiwać `UserDefaults` w testach i nigdy nie przechowywać celów sieciowych, danych logowania ani kluczy.

- [x] **Step 4: Implement the four-stage lesson UI**

  Każdy ekran pokazuje jeden etap, jawny kontekst prawny, przygotowane dane offline, pole flagi tylko dla wbudowanej odpowiedzi oraz defensywne wyjaśnienie po zaliczeniu.

- [ ] **Step 5: Verify focused tests and end-to-end flow**

  Uruchomić testy postępu, build oraz ręcznie przejść jedną lekcję od Start do Wyniku.

### Task 4 (100%): Skill Achievements, Final QA, and Release Readiness

**Files:**
- Create: `CipherPath/AchievementModels.swift`
- Create: `CipherPath/AchievementStore.swift`
- Modify: `CipherPath/AchievementsView.swift`
- Modify: `CipherPath/DashboardView.swift`
- Modify: `CipherPathTests/CipherPathTests.swift`
- Create: `design-qa.md`

**Interfaces:**
- Consumes: ukończone lekcje, użyte podpowiedzi, ukończone ścieżki.
- Produces: brązowe, srebrne i złote medale z liczbowym postępem oraz ostatnie osiągnięcie na ekranie Start.

- [ ] **Step 1: Write failing achievement tests**

  Sprawdzić „Pierwszą flagę” po pierwszej misji, „Bez podpowiedzi” po ukończeniu bez pomocy, złoty medal po wymaganej serii oraz brak medalu przed spełnieniem warunku.

- [ ] **Step 2: Verify RED**

  Uruchomić wyłącznie `AchievementTests`; oczekiwany błąd: brak modeli i ewaluatora osiągnięć.

- [ ] **Step 3: Implement deterministic achievement evaluation**

  Medale wynikają wyłącznie z lokalnego postępu; nie występuje losowość, zakup ani publiczny ranking. Zablokowany medal pokazuje nazwę warunku i liczbowy postęp.

- [ ] **Step 4: Complete visual and accessibility QA**

  Sprawdzić Dynamic Type, VoiceOver labels, kontrast, stany wyszarzone i komplet głównej ścieżki. Porównać ekran Start z makietą i doprowadzić `design-qa.md` do `final result: passed` albo uczciwie zapisać `blocked`.

- [ ] **Step 5: Run final verification without publishing**

  Uruchomić najwęższy pełny zestaw testów, unsigned Release build i kontrolę integralności. `./scripts/pre-push-check.sh` wolno uruchomić dopiero po utworzeniu repozytorium Git; commit i push wymagają osobnej zgody.

## Self-review

- Spec coverage: pięć zakładek, pięć ścieżek, 10 lekcji, 15 zapowiedzi, cztery etapy, lokalny postęp, trzy poziomy medali i bezpieczne środowiska mają przypisane zadania.
- Placeholder scan: plan nie zawiera kroków `TBD`, `TODO` ani nieokreślonych implementacji.
- Type consistency: katalog jest źródłem danych dla nawigacji; postęp używa stabilnych `lessonID`; medale konsumują wyłącznie ukończenia i użycie podpowiedzi.
