# Interactive Labs Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Dodać do CipherPath bezpieczne, różnorodne laboratoria z wirtualnym hostem, terminalem, deterministycznymi wynikami poleceń i flagami.

**Architecture:** Definicja laboratorium jest niezmiennym modelem danych, natomiast stan sesji istnieje osobno. Parser akceptuje ograniczoną składnię, a silnik dopasowuje ją do jawnych reguł i nigdy nie uruchamia procesów ani połączeń sieciowych. Widok terminala konsumuje wyłącznie wynik silnika, dzięki czemu pierwsza wersja działa offline i jest deterministycznie testowalna.

**Tech Stack:** Swift 6, SwiftUI, Foundation, Swift Testing, XCTest, Xcode iOS target; bez zewnętrznych zależności.

**Spec:** `docs/superpowers/specs/2026-09-12-interactive-labs-design.md`

## Global Constraints

- Laboratoria działają całkowicie offline i nie wykonują ruchu sieciowego.
- Silnik nie uruchamia poleceń systemowych ani zewnętrznych procesów.
- Dozwolone są wyłącznie polecenia z jawnej listy danej misji.
- Próba zmiany celu lub użycia niedozwolonej komendy nie wykonuje operacji.
- Brak publicznych celów, brute force, phishingu, persistence, eksfiltracji i automatycznej eksploatacji.
- Postęp trwały nie zawiera historii terminala, adresów użytkownika ani danych logowania.
- Pierwszy etap nie zmienia istniejących ekranów aplikacji.
- Commit, push, instalacja i publikacja wymagają osobnego polecenia użytkownika.

---

### Task 1 (25%): Offline Lab Domain and Command Engine

**Files:**
- Create: `CipherPath/LabModels.swift`
- Create: `CipherPath/LabCommandParser.swift`
- Create: `CipherPath/LabEngine.swift`
- Create: `CipherPathTests/LabEngineTests.swift`
- Modify: `CipherPath.xcodeproj/project.pbxproj`

**Interfaces:**
- Produces: `LabCommand`, `LabCommandParser.parse(_:)`, `LabDefinition`, `LabRule`, `LabSession`, `LabEngine.execute(_:in:)`.
- Consumes: wyłącznie typy wartościowe z `Foundation`; nie zależy od SwiftUI ani istniejącego magazynu postępu.

- [x] **Step 1: Write failing parser tests**

  Dodać testy pokazujące, że parser rozpoznaje `help`, `ping 10.10.0.12`, `nmap -sC -sV 10.10.0.12`, `curl http://10.10.0.12/robots.txt` i `cat user.txt`, normalizuje nadmiarowe odstępy oraz odrzuca pusty tekst, operatory powłoki (`;`, `|`, `&&`, przekierowania) i nieznane programy.

- [x] **Step 2: Run parser tests and verify RED**

  Run:

  ```zsh
  xcodebuild test -project CipherPath.xcodeproj -scheme CipherPath -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:CipherPathTests/LabCommandParserTests
  ```

  Expected: FAIL podczas kompilacji, ponieważ `LabCommandParser` jeszcze nie istnieje.

- [x] **Step 3: Implement minimal parser**

  Utworzyć `enum LabCommand: Equatable, Sendable` z przypadkami dla zatwierdzonej listy komend i `enum LabCommandParseResult: Equatable, Sendable` z wartościami `.command(LabCommand)` oraz `.rejected(String)`. Parser dzieli wejście wyłącznie po białych znakach, odrzuca metaznaki powłoki przed interpretacją i zachowuje argumenty jako dane.

- [x] **Step 4: Run parser tests and verify GREEN**

  Uruchomić polecenie ze Step 2. Expected: wszystkie testy `LabCommandParserTests` przechodzą.

- [x] **Step 5: Write failing engine tests**

  Dodać testy przykładowej definicji `network-scout`: sesja przed startem odrzuca polecenie, po starcie `ping` i `nmap` zwracają przypisane wyniki, prawidłowe komendy dodają odkrycia, inny adres celu jest odrzucany, komenda spoza listy misji jest odrzucana, identyczna sekwencja daje identyczny wynik i przesłanie flagi rozróżnia wynik błędny od poprawnego.

- [x] **Step 6: Run engine tests and verify RED**

  Run:

  ```zsh
  xcodebuild test -project CipherPath.xcodeproj -scheme CipherPath -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:CipherPathTests/LabEngineTests
  ```

  Expected: FAIL podczas kompilacji, ponieważ modele i `LabEngine` jeszcze nie istnieją.

- [x] **Step 7: Implement minimal offline engine**

  `LabDefinition` zawiera `id`, `title`, `targetAddress`, `allowedPrograms`, `rules`, `objectives`, `flags` i `defenseSummary`. `LabRule` dopasowuje dokładnie znormalizowane polecenie do tekstowego wyniku i opcjonalnego odkrycia. `LabSession` zawiera `isRunning`, wpisy terminala, zbiór odkryć i zdobyte identyfikatory flag. `LabEngine` najpierw sprawdza stan sesji, parser, listę programów i zgodność adresu celu, a dopiero potem zwraca wynik z definicji.

- [x] **Step 8: Run focused tests and verify GREEN**

  Uruchomić obie suity parsera i silnika. Expected: wszystkie nowe testy przechodzą, bez dostępu do sieci i bez uprawnień systemowych.

- [x] **Step 9: Verify project integrity**

  Run:

  ```zsh
  xcodebuild build -project CipherPath.xcodeproj -scheme CipherPath -destination 'platform=iOS Simulator,name=iPhone 17'
  git diff --check
  ```

  Expected: `BUILD SUCCEEDED` oraz brak wyniku `git diff --check`. Nie wykonywać commita ani pushu.

### Task 2 (50%): Interactive Terminal and Two Playable Labs

**Files:**
- Create: `CipherPath/LabTerminalView.swift`
- Create: `CipherPath/StarterLabs.swift`
- Modify: `CipherPath/LessonFlowView.swift`
- Create: `CipherPathTests/StarterLabsTests.swift`
- Modify: `CipherPath.xcodeproj/project.pbxproj`

**Interfaces:**
- Consumes: `LabDefinition`, `LabSession`, `LabEngine.execute(_:in:)`, `LearningLesson.id`.
- Produces: `StarterLabs.definition(for:)`, grywalne Network Scout i Hidden Web oraz terminal z historią i podpowiedziami.

- [x] **Step 1: Write failing content and mapping tests**

  Sprawdzić, że dwa identyfikatory lekcji mają kompletne definicje, różne reguły i flagi; każda reguła używa tylko dozwolonego programu, a wszystkie odwołania do celu wskazują wirtualny adres definicji.

- [x] **Step 2: Verify RED, implement minimal definitions, verify GREEN**

  Uruchomić `StarterLabsTests`, potwierdzić brak `StarterLabs`, dodać dwie jawne definicje i powtórzyć test do wyniku PASS.

- [x] **Step 3: Write failing lesson-to-lab routing test**

  Sprawdzić, że wejście w przypisaną lekcję wybiera laboratorium, a zwykła lekcja zachowuje dotychczasowy czteroetapowy widok.

- [x] **Step 4: Implement terminal and routing**

  Widok pokazuje status, cel, historię, pole wpisywania, podpowiedzi, cele i flagę. `LessonFlowView` wybiera `LabTerminalView` tylko wtedy, gdy `StarterLabs.definition(for:)` zwróci definicję.

- [ ] **Step 5: Verify two complete flows**

  Uruchomić testy, build oraz ręcznie ukończyć Network Scout i Hidden Web w symulatorze; zapisać wynik bez twierdzenia o przejściu, jeżeli interakcja nie została wykonana.

### Task 3 (75%): Full Mission Pack, Adventure Mode, XP and Medals

**Files:**
- Modify: `CipherPath/StarterLabs.swift`
- Modify: `CipherPath/LabModels.swift`
- Modify: `CipherPath/LabEngine.swift`
- Modify: `CipherPath/LearningProgressStore.swift`
- Create: `CipherPath/AchievementModels.swift`
- Create: `CipherPath/AchievementStore.swift`
- Modify: `CipherPath/AchievementsView.swift`
- Modify: `CipherPathTests/StarterLabsTests.swift`
- Create: `CipherPathTests/AchievementTests.swift`

**Interfaces:**
- Consumes: ukończenie flag, użycie podpowiedzi i identyfikator trybu.
- Produces: 10 różnych definicji, `LabMode.guided/adventure`, XP i deterministyczne kryteria medali.

- [x] **Step 1: Write failing catalog diversity tests**

  Wymagać 10 dostępnych definicji, po dwóch na ścieżkę, co najmniej pięciu różnych zestawów programów oraz co najmniej jednej misji z dwiema flagami.

- [x] **Step 2: Verify RED, add eight definitions, verify GREEN**

  Dodać pozostałe misje opisane w specyfikacji i uruchomić `StarterLabsTests` do wyniku PASS.

- [x] **Step 3: Write failing mode and reward tests**

  Sprawdzić blokadę Adventure przed pierwszym ukończeniem, odblokowanie po ukończeniu Guided, zapis użycia podpowiedzi, stałą wartość XP i medal za Adventure bez podpowiedzi.

- [x] **Step 4: Implement modes and deterministic rewards**

  Zapisywać wyłącznie identyfikator misji, ukończone tryby, użycie podpowiedzi, XP i identyfikatory medali. Adventure ukrywa cele etapowe i ogranicza podpowiedzi, ale używa tego samego bezsieciowego silnika.

- [x] **Step 5: Verify focused and regression tests**

  Uruchomić `StarterLabsTests`, `AchievementTests`, `LearningProgressTests` oraz `git diff --check`.

### Task 4 (100%): Integration, Accessibility and Final QA

**Files:**
- Modify: `CipherPath/LabTerminalView.swift`
- Modify: `CipherPath/MissionsView.swift`
- Modify: `CipherPath/DashboardView.swift`
- Modify: `CipherPath/AchievementsView.swift`
- Create: `docs/design/interactive-labs-qa.md`

**Interfaces:**
- Consumes: gotowy katalog laboratoriów, postęp i nagrody.
- Produces: pełny przepływ Start → Misja → Laboratorium → Flaga → Wynik → Medal.

- [x] **Step 1: Write failing integration-state tests**

  Sprawdzić wznowienie rozpoczętej misji, prezentację kolejnego celu, ukończenie po wymaganych flagach i widoczność nagrody na ekranie Start.

- [x] **Step 2: Implement final integration and accessibility labels**

  Dodać semantyczne etykiety VoiceOver, obsługę Dynamic Type, czytelny kontrast, wznowienie sesji od bezpiecznego początku i jasne stany błędu.

- [x] **Step 3: Run full tests and simulator build**

  Uruchomić cały target testów oraz Debug build dla iPhone 17. Wyniki testów i buildu raportować oddzielnie.

- [x] **Step 4: Perform visual and flow QA**

  Przejść po jednej misji z każdej ścieżki, sprawdzić mały i duży Dynamic Type oraz zapisać problemy P0–P2 i wynik w `docs/design/interactive-labs-qa.md`.

- [x] **Step 5: Run pre-push verification without publishing**

  Uruchomić `./scripts/pre-push-check.sh` i `git diff --check`. Nie wykonywać commita, pushu ani instalacji bez osobnego polecenia użytkownika.

## Self-review

- Spec coverage: oba tryby, terminal, 10 misji, flagi, podpowiedzi, XP, medale, dostępność i pełna integracja mają przypisane zadania.
- Placeholder scan: plan nie zawiera `TBD`, `TODO` ani kroków pozbawionych oczekiwanego zachowania.
- Type consistency: wszystkie widoki korzystają z `LabDefinition` i `LabSession`; nagrody konsumują wyłącznie zapisane wyniki misji.
- Scope split: Mac Lab Runner pozostaje osobnym przyszłym podprojektem i nie jest częścią tego planu.
