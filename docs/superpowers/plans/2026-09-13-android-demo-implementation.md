# CipherPath Android Demo Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Zbudować prywatne, działające offline demo CipherPath na Androida, wiernie prezentujące wygląd i zakładki wersji iPhone oraz trzy kompletne misje.

**Architecture:** Osobna aplikacja Compose w repozytorium `CipherPath-Android`. Czysta logika misji działa niezależnie od UI, postęp zapisuje DataStore, a Compose renderuje ekran startowy, ścieżki i wspólny ekran misji.

**Tech Stack:** Kotlin 2.3.21, Jetpack Compose BOM 2026.08.00, Material 3, AGP 9.4.0, Gradle 9.6.0, JDK 21, compileSdk/targetSdk 37, minSdk 29, DataStore Preferences, JUnit 4.

**Spec:** `docs/superpowers/specs/2026-09-13-android-demo-design.md`

## Global Constraints

- Projekt docelowy: `/Users/Projekty/CipherPath-Android`; prywatne repozytorium GitHub.
- Nazwa aplikacji: `CipherPath Demo`; applicationId: `pl.krystian.cipherpath.demo`.
- Android 10 (API 29) lub nowszy; interfejs po polsku; praca całkowicie offline.
- Pięć zakładek zgodnych z iPhone: Start, Ścieżki, Misje, Praktyka i Osiągnięcia.
- Trzy kompletne, sprawdzalne misje oraz dwie nieaktywne zapowiedzi.
- Priorytetem są wygląd zgodny z iPhone oraz działające misje; konto, sklep, subskrypcja i integracja NetScope są nieaktywne i oznaczone „Wkrótce”.
- Brak INTERNET oraz zbędnych uprawnień w manifeście.
- Wskazówki i rozwiązania są bezpłatne, ukryte domyślnie i ujawniane tylko na żądanie.
- Nie commitować kluczy podpisujących, APK, danych osobowych ani sekretów.
- Zgodnie z ustalonym procesem wszystkie kroki wykonujemy bez commitów pośrednich. Jeden commit następuje dopiero po pełnej weryfikacji i akceptacji użytkownika, a push dopiero po jego osobnej zgodzie.

---

### Task 1: Prywatny szkielet aplikacji i odtwarzalny build

**Files:**
- Create: `/Users/Projekty/CipherPath-Android/settings.gradle.kts`
- Create: `/Users/Projekty/CipherPath-Android/build.gradle.kts`
- Create: `/Users/Projekty/CipherPath-Android/gradle/libs.versions.toml`
- Create: `/Users/Projekty/CipherPath-Android/gradle.properties`
- Create: `/Users/Projekty/CipherPath-Android/app/build.gradle.kts`
- Create: `/Users/Projekty/CipherPath-Android/app/src/main/AndroidManifest.xml`
- Create: `/Users/Projekty/CipherPath-Android/app/src/main/java/pl/krystian/cipherpath/demo/MainActivity.kt`
- Create: `/Users/Projekty/CipherPath-Android/app/src/main/res/values/strings.xml`
- Create: `/Users/Projekty/CipherPath-Android/.gitignore`

**Interfaces:**
- Produces: moduł `:app`, `MainActivity`, pakiet `pl.krystian.cipherpath.demo`.

- [ ] **Step 1: Sprawdź narzędzia i zainstaluj tylko brakujący Android SDK po osobnej zgodzie użytkownika**

Run: `java -version && gradle --version && command -v sdkmanager && command -v adb`

Expected: Java i Gradle są dostępne; brak `sdkmanager` uruchamia zatwierdzoną instalację narzędzi Android, nigdy `curl | sh`.

- [ ] **Step 2: Utwórz konfigurację projektu**

Przypnij w katalogu wersji: `agp = "9.4.0"`, `kotlin = "2.3.21"`, `composeBom = "2026.08.00"`, `activityCompose = "1.13.0"`, `lifecycle = "2.10.0"`, `datastore = "1.1.7"`, `junit = "4.13.2"`. Skonfiguruj wrapper Gradle `9.6.0`, namespace/applicationId, `minSdk = 29`, `compileSdk = 37`, `targetSdk = 37` i Compose.

- [ ] **Step 3: Dodaj minimalną aktywność i manifest**

`MainActivity` wywołuje `setContent { CipherPathDemoApp() }`. Manifest deklaruje wyłącznie aktywność startową i nie zawiera `<uses-permission>`.

- [ ] **Step 4: Potwierdź czysty build**

Run: `./gradlew --no-daemon clean testDebugUnitTest assembleDebug`

Expected: `BUILD SUCCESSFUL` oraz `app/build/outputs/apk/debug/app-debug.apk`.

### Task 2: Model katalogu i trzy misje

**Files:**
- Create: `app/src/main/java/pl/krystian/cipherpath/demo/mission/Mission.kt`
- Create: `app/src/main/java/pl/krystian/cipherpath/demo/mission/MissionCatalog.kt`
- Test: `app/src/test/java/pl/krystian/cipherpath/demo/mission/MissionCatalogTest.kt`

**Interfaces:**
- Produces: `data class Mission`, `data class MissionStep`, `enum class MissionAvailability`, `object MissionCatalog { val missions: List<Mission> }`.

- [ ] **Step 1: Napisz test katalogu**

Test potwierdza pięć unikalnych identyfikatorów, trzy misje `AVAILABLE`, dwie `COMING_SOON`, niepuste opisy, podpowiedzi, rozwiązania i co najmniej dwa kroki w każdej dostępnej misji.

- [ ] **Step 2: Uruchom test i potwierdź RED**

Run: `./gradlew testDebugUnitTest --tests '*MissionCatalogTest'`

Expected: FAIL, ponieważ `MissionCatalog` jeszcze nie istnieje.

- [ ] **Step 3: Dodaj modele i treść**

Zaimplementuj `network-scout`, `suspicious-login`, `hidden-web` oraz zapowiedzi `service-detective`, `permission-trail`. Każdy krok zawiera prompt, dozwolone polecenia, symulowany wynik i czytelną odpowiedź bez formatu `CIPHER{}`.

- [ ] **Step 4: Uruchom test katalogu**

Run: `./gradlew testDebugUnitTest --tests '*MissionCatalogTest'`

Expected: PASS.

### Task 3: Deterministyczny silnik terminala

**Files:**
- Create: `app/src/main/java/pl/krystian/cipherpath/demo/mission/MissionEngine.kt`
- Test: `app/src/test/java/pl/krystian/cipherpath/demo/mission/MissionEngineTest.kt`

**Interfaces:**
- Consumes: `Mission`, `MissionStep`.
- Produces: `class MissionEngine`, `fun run(command: String): TerminalResult`, `fun submit(answer: String): AnswerResult`.

- [ ] **Step 1: Napisz testy silnika**

Pokryj poprawne polecenie, nieznane polecenie, pusty input, złą odpowiedź, poprawną odpowiedź i przejście do kolejnego kroku bez prawdziwego uruchamiania procesu.

- [ ] **Step 2: Potwierdź RED**

Run: `./gradlew testDebugUnitTest --tests '*MissionEngineTest'`

Expected: FAIL z brakiem `MissionEngine`.

- [ ] **Step 3: Zaimplementuj minimalny silnik**

Normalizuj wyłącznie białe znaki i wielkość liter odpowiedzi. Polecenie musi dokładnie pasować do listy danego kroku; każde inne zwraca bezpieczny komunikat edukacyjny.

- [ ] **Step 4: Potwierdź GREEN**

Run: `./gradlew testDebugUnitTest --tests '*MissionEngineTest'`

Expected: PASS.

### Task 4: Lokalny postęp i rejestr użytej pomocy

**Files:**
- Create: `app/src/main/java/pl/krystian/cipherpath/demo/progress/ProgressRepository.kt`
- Create: `app/src/main/java/pl/krystian/cipherpath/demo/progress/DataStoreProgressRepository.kt`
- Test: `app/src/test/java/pl/krystian/cipherpath/demo/progress/ProgressRepositoryTest.kt`

**Interfaces:**
- Produces: `data class MissionProgress(completed: Boolean, hintUsed: Boolean, solutionViewed: Boolean)`, `interface ProgressRepository`, metody `observe`, `markHintUsed`, `markSolutionViewed`, `markCompleted`.

- [ ] **Step 1: Napisz test repozytorium in-memory**

Test potwierdza niezależne zapisanie podpowiedzi, rozwiązania i ukończenia oraz brak blokady po użyciu pomocy.

- [ ] **Step 2: Potwierdź RED**

Run: `./gradlew testDebugUnitTest --tests '*ProgressRepositoryTest'`

Expected: FAIL z brakiem kontraktu repozytorium.

- [ ] **Step 3: Dodaj kontrakt i implementację DataStore**

Klucze mają postać `mission_<id>_completed`, `mission_<id>_hint_used`, `mission_<id>_solution_viewed`; zapis nie zawiera danych osobowych.

- [ ] **Step 4: Potwierdź GREEN**

Run: `./gradlew testDebugUnitTest --tests '*ProgressRepositoryTest'`

Expected: PASS.

### Task 5: Pięć zakładek i wizualny ekran Start

**Files:**
- Create: `app/src/main/java/pl/krystian/cipherpath/demo/ui/CipherPathDemoApp.kt`
- Create: `app/src/main/java/pl/krystian/cipherpath/demo/ui/HomeScreen.kt`
- Create: `app/src/main/java/pl/krystian/cipherpath/demo/ui/PathsScreen.kt`
- Create: `app/src/main/java/pl/krystian/cipherpath/demo/ui/MissionScreen.kt`
- Create: `app/src/main/java/pl/krystian/cipherpath/demo/ui/MissionViewModel.kt`
- Test: `app/src/androidTest/java/pl/krystian/cipherpath/demo/ui/DemoFlowTest.kt`

**Interfaces:**
- Consumes: `MissionCatalog`, `MissionEngine`, `ProgressRepository`.
- Produces: trasy `home`, `paths`, `missions`, `practice`, `achievements`, `briefing/{missionId}`, `mission/{missionId}` i wizualny przepływ prezentacyjny.

- [ ] **Step 1: Napisz test przepływu UI**

Test sprawdza: dolna nawigacja zawiera pięć zakładek; Start pokazuje kartę „Dzisiejsza misja”, pięć ścieżek i medale; każda z trzech misji otwiera odprawę; użytkownik dopiero osobnym przyciskiem rozpoczyna misję; zablokowane zapowiedzi nie reagują.

- [ ] **Step 2: Potwierdź RED**

Run: `./gradlew connectedDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=pl.krystian.cipherpath.demo.ui.DemoFlowTest`

Expected: FAIL, ponieważ ekrany nie istnieją.

- [ ] **Step 3: Zaimplementuj widoki i ViewModel**

Odtwórz język wizualny zatwierdzonego ekranu iPhone: ciemne granatowe tło, biało-fioletowy logotyp tekstowy, duża karta misji, kolorowe ścieżki, metaliczne medale i dolna nawigacja. Widoki nie wykonują logiki domenowej. `MissionViewModel` obsługuje wszystkie trzy dostępne misje.

- [ ] **Step 4: Uruchom test UI**

Run: `./gradlew connectedDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=pl.krystian.cipherpath.demo.ui.DemoFlowTest`

Expected: PASS na uruchomionym emulatorze lub urządzeniu.

### Task 6: Terminal oraz dobrowolne wskazówki i rozwiązania

**Files:**
- Modify: `app/src/main/java/pl/krystian/cipherpath/demo/ui/MissionScreen.kt`
- Modify: `app/src/main/java/pl/krystian/cipherpath/demo/ui/MissionViewModel.kt`
- Test: `app/src/androidTest/java/pl/krystian/cipherpath/demo/ui/HelpFlowTest.kt`

**Interfaces:**
- Produces: zdarzenia `requestHint()`, `requestSolution()`, `confirmSolution()` oraz stan `hintVisible`, `solutionConfirmationVisible`, `solutionVisible`.

- [ ] **Step 1: Napisz test zachowania pomocy**

Test wykonuje przepływ pomocy we wszystkich trzech misjach i potwierdza, że błędna odpowiedź nie pokazuje pomocy, „Chcę wskazówkę” pokazuje bezpłatną wskazówkę, „Pokaż rozwiązanie” najpierw pokazuje potwierdzenie, anulowanie niczego nie ujawnia, a potwierdzenie ujawnia rozwiązanie bez blokowania postępu.

- [ ] **Step 2: Potwierdź RED**

Run: `./gradlew connectedDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=pl.krystian.cipherpath.demo.ui.HelpFlowTest`

Expected: FAIL, ponieważ kontrolki pomocy nie istnieją.

- [ ] **Step 3: Dodaj kontrolki i zapis użycia**

Terminal wizualnie naśladuje sprawdzony układ NetScope: karta celu, czarna historia terminala, prompt, pomoc i karta ukończenia. Nie dodawaj działania „we własnej sieci”. Przyciski pomocy pozostają drugorzędne wizualnie. Nie pokazuj ceny, salda ani kary punktowej. Po świadomym otwarciu wywołaj odpowiednią metodę `ProgressRepository`.

- [ ] **Step 4: Potwierdź GREEN**

Run: `./gradlew connectedDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=pl.krystian.cipherpath.demo.ui.HelpFlowTest`

Expected: PASS.

### Task 7: README, prywatny APK i końcowa weryfikacja

**Files:**
- Create: `/Users/Projekty/CipherPath-Android/README.md`
- Modify: `/Users/Projekty/CipherPath-Android/.gitignore`

**Interfaces:**
- Produces: zweryfikowany `app-debug.apk` oraz instrukcję prywatnej instalacji.

- [ ] **Step 1: Dodaj README i reguły wykluczeń**

README opisuje wizualny cel demo, pięć zakładek, trzy pełne misje, ograniczenia offline, minimalny Android 10, ręczną instalację APK i brak publicznej dystrybucji. `.gitignore` wyklucza `local.properties`, `.gradle/`, `build/`, `*.apk`, `*.jks`, `*.keystore`.

- [ ] **Step 2: Zweryfikuj manifest i sekrety**

Run: `rg -n '<uses-permission|INTERNET|token|password|PRIVATE KEY' app README.md .gitignore || true`

Expected: brak uprawnień i sekretów; słowa dokumentacyjne sprawdzić ręcznie, nie traktować jako sekretu.

- [ ] **Step 3: Uruchom pełną weryfikację**

Run: `./gradlew --no-daemon clean testDebugUnitTest lintDebug assembleDebug connectedDebugAndroidTest`

Expected: `BUILD SUCCESSFUL`, wszystkie testy PASS i gotowy prywatny APK.

- [ ] **Step 4: Zainstaluj i uruchom demo**

Run: `adb install -r app/build/outputs/apk/debug/app-debug.apk && adb shell am start -n pl.krystian.cipherpath.demo/.MainActivity`

Expected: aplikacja uruchamia się na wybranym urządzeniu/emulatorze; użytkownik ręcznie przechodzi wszystkie trzy misje.

- [ ] **Step 5: Po akceptacji użytkownika wykonaj jeden commit**

Run: `git status --short && git diff --check && git add . && git commit -m "feat: add private Android demo"`

Expected: commit nie zawiera APK, `local.properties`, kluczy ani sekretów.

- [ ] **Step 6: Po osobnej zgodzie wykonaj jeden push do prywatnego repozytorium**

Run: `gh repo view --json visibility,nameWithOwner && git push -u origin HEAD`

Expected: `visibility` ma wartość `PRIVATE`; push kończy się bez force push.
