# CipherPath i NetScope — projekt prywatnej integracji

## Cel

Zmienić zakładkę „Praktyka” w CipherPath w czytelny most do osobnej aplikacji NetScope, zachowując tymczasowo obecne narzędzia wbudowane. Dodać bezpieczny deep link do NetScope i zaktualizować prywatny README CipherPath do rzeczywistego stanu produktu.

## Prywatność

Repozytoria `krystian2236/CipherPath` i `krystian2236/NetScope` są prywatne. README, specyfikacje, plany i kod pozostają widoczne wyłącznie dla osób z dostępem. Zakres nie obejmuje GitHub Pages, publicznych wydań, publicznych artefaktów ani publikacji w sklepach.

## Ekran Praktyka w CipherPath

Zakładka otwiera ekran informacyjny „Praktyka z NetScope”. Ekran wyjaśnia, że NetScope jest osobną aplikacją do legalnej analizy własnej sieci i pokazuje pięć możliwości:

- skan prywatnej sieci;
- rozpoznawanie urządzeń i usług;
- Toolbox do budowania poleceń;
- laboratoria Nmap i Nuclei;
- współpraca z iSH bez automatycznego wykonywania poleceń.

Główny przycisk „Otwórz NetScope” wywołuje `netscope://start`. Jeśli system nie może otworzyć linku, CipherPath pokazuje komunikat „NetScope nie jest zainstalowany” bez przekierowania do publicznego sklepu.

Poniżej pozostaje sekcja „Narzędzia wbudowane” z dotychczasowymi ekranami CipherPath: skan prywatnej sieci, Toolbox, urządzenia, usługi i prywatność. Usunięcie duplikatów nastąpi dopiero po osobnym teście współpracy aplikacji.

## Deep link NetScope

NetScope rejestruje prywatny schemat URL `netscope` w `Info.plist`. `AppShellView` obsługuje wyłącznie znaną trasę:

- `netscope://start` — przełącza aplikację na ekran Start.

Nieznane hosty i ścieżki są ignorowane. Deep link nie uruchamia skanowania, nie wybiera publicznego celu, nie przesyła danych i nie zmienia zapisów użytkownika. Przyszłe trasy `toolbox` i `laboratory` nie należą do tego etapu.

## README CipherPath

README ma opisywać obecny stan:

- iOS 17+, SwiftUI i Apple Silicon;
- 5 ścieżek, 25 widocznych lekcji i 10 grywalnych misji;
- Guided, Adventure, terminal offline, flagi, medale i zapis postępu;
- punkty Pro 25%: saldo, historia, koszt pomocy i nielimitowany Dev;
- różnicę między `CipherPath` Release i `CipherPath Dev`;
- rolę NetScope oraz sposób bezpiecznego otwarcia drugiej aplikacji;
- uruchomienie, testy i zasady legalnego użycia;
- prywatny status projektu bez obietnicy publicznej dystrybucji;
- roadmapę: konto/synchronizacja, StoreKit, więcej misji, TestFlight/App Store.

README nie może zawierać sekretów, danych konta, identyfikatorów urządzeń, ścieżek kluczy ani prywatnych danych użytkownika.

## Android demo

Android jest osobnym przyszłym projektem, nie portem obecnego SwiftUI. Rekomendowany zakres to Kotlin + Jetpack Compose, 2–3 misje offline, terminal symulowany i lokalny postęp. Pierwszy APK nie otrzyma skanera sieci ani połączenia z NetScope. Repozytorium i sposób udostępnienia pozostaną prywatne; dokładny kanał przekazania APK zostanie wybrany przed rozpoczęciem tego projektu.

## Pliki i granice repozytoriów

CipherPath:

- `CipherPath/AppShellView.swift` — ekran Praktyka i otwieranie NetScope;
- `CipherPath/Info.plist` — lista dozwolonych schematów zapytań, jeśli wymaga jej `canOpenURL`;
- `CipherPathTests/CipherPathTests.swift` — test modelu trasy i treści;
- `README.md` — aktualny opis prywatnego produktu.

NetScope:

- `NetScope/Info.plist` — rejestracja schematu;
- `NetScope/AppShellView.swift` — parser i obsługa trasy;
- `NetScopeTests/NetScopeTests.swift` — test akceptowanej i odrzucanej trasy.

Istniejące zmiany laboratoriów NetScope pozostają nietknięte. Integracja otrzyma osobny commit w każdym repozytorium.

## Weryfikacja

- test parsera tras w obu aplikacjach;
- test nieznanej trasy;
- `git diff --check` w obu repozytoriach;
- wąskie testy integracji;
- `pre-push-check.sh` osobno w CipherPath i NetScope;
- ręczne otwarcie NetScope z CipherPath na iPhonie;
- potwierdzenie, że samo otwarcie nie rozpoczyna skanu;
- sprawdzenie zachowania, gdy NetScope nie jest dostępny.

## Poza zakresem

- wymiana danych między aplikacjami;
- App Groups, iCloud i wspólny backend;
- automatyczne skanowanie;
- publiczny README lub release;
- implementacja Androida w tym samym commicie;
- TestFlight, App Store i Google Play.

