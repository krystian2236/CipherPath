# Zasady pracy nad CipherPath

Te instrukcje obowiązują Codex, ChatGPT oraz GitHub Copilot podczas pracy w tym repozytorium.

## Sposób pracy

- Odpowiadaj po polsku, krótko i konkretnie.
- Najpierw sprawdź bieżący stan repozytorium, odpowiedni diff i wskazane pliki. Nie powtarzaj analizy, która została już wykonana i nadal jest aktualna.
- Domyślnie wykonuj diagnostykę tylko do odczytu. Zmieniaj pliki dopiero po jednoznacznym zatwierdzeniu zakresu.
- Realizuj jedną małą, logiczną zmianę naraz. Nie modyfikuj plików niezwiązanych z zadaniem.
- Nie uruchamiaj drugiego agenta nad tym samym zakresem zmian. Przed rozpoczęciem pracy ustal, czy bieżący diff należy do użytkownika, Copilota lub Codex.
- Używaj możliwie małego kontekstu: najpierw `git status`, potem diff wskazanych plików, następnie tylko pliki wymagane przez zadanie.
- Nie uruchamiaj pełnych skanów, wszystkich narzędzi ani wielokrotnych buildów, jeżeli węższa weryfikacja wystarcza.

## Spójność produktu

- Po zmianie nawigacji, widoczności funkcji, modelu Free/Pro albo tekstów opisujących możliwości aplikacji sprawdź, czy `README.md` i `CHANGELOG.md` nadal opisują faktyczny stan produktu.
- Zmiana `ContentAccessPolicy` lub innej reguły dostępu wymaga sprawdzenia wszystkich wejść do tej samej treści, między innymi z ekranu Start, Ścieżek i pozostałych aktywnych ekranów.
- Funkcje oznaczone jako niedostępne, `Wkrótce` albo nieinteraktywne nie powinny być pokazywane w buildzie App Store, chyba że użytkownik wyraźnie zatwierdzi ich obecność. Mogą pozostać widoczne w buildzie developerskim.
- Nie dubluj reguł dostępu lub widoczności bez potrzeby. Preferuj jedno źródło prawdy używane przez UI i testy.

## Bezpieczeństwo i Git

- Nigdy nie ujawniaj, zapisuj ani commituj tokenów, haseł, kluczy prywatnych, plików `.env`, danych uwierzytelniających lub danych osobowych.
- Diagnostykę sieci wykonuj wyłącznie dla prywatnych adresów użytkownika albo systemów, na których testowanie ma zgodę właściciela.
- CipherPath może przygotowywać i kopiować polecenia SSH, ale nie może przechowywać haseł ani kluczy prywatnych.
- Nie wykonuj commita, pushu, instalacji, usuwania, zmiany uprawnień, publikacji ani wysyłki do App Store bez jednoznacznego polecenia użytkownika.
- Nie używaj force push i nie zmieniaj istniejącej historii Git.
- Przed proponowanym push uruchom najwęższe testy obejmujące zmianę, następnie `./scripts/pre-push-check.sh`, i podaj rzeczywiste wyniki obu kontroli.
- Stosuj małe commity Conventional Commits z angielskim tytułem do 72 znaków.

## Weryfikacja

- Najpierw uruchom najwęższe testy obejmujące zmianę, potem testy regresji wymagane przez zmieniony obszar, a na końcu `git diff --check`.
- Sam build nie zastępuje testów. `./scripts/pre-push-check.sh` także nie zastępuje testów jednostkowych, dopóki jawnie ich nie uruchamia.
- Nie twierdź, że testy przeszły, jeśli zostały tylko skompilowane albo ich uruchomienie zablokował symulator lub środowisko.
- Po zakończeniu podaj: wynik, zmienione pliki, wykonaną weryfikację, kontrole niewykonane oraz jedno krótkie zalecenie lub wniosek.

## Simulator iOS

- Preferowanym urządzeniem projektu jest Simulator nazwany `CipherPath — iPhone 17`. Nie zapisuj stałego UDID w instrukcjach ani skryptach; przed poleceniami `xcodebuild` lub `simctl` ustal aktualny UDID z `xcrun simctl list devices available`.
- Jeżeli preferowany Simulator nie istnieje, użyj aktualnie uruchomionego iPhone Simulatora i jawnie podaj wybrane urządzenie. Nie twórz nowego Simulatora bez potrzeby.
- Po zmianach restartuj tylko aplikację. Nie wyłączaj, nie restartuj ani nie wymazuj całego Simulatora bez osobnego polecenia użytkownika.
- Do kontroli innych rozmiarów używaj trybu zmiany rozmiaru ekranu w Device Hub zamiast tworzenia lub przełączania Simulatora.
- Funkcje zależne od Local Network weryfikuj na prawdziwym iPhonie, gdy zachowanie Simulatora nie odwzorowuje rzeczywistego uprawnienia lub sieci.

## App Store

- Przy zmianach wydaniowych sprawdź `Info.plist`, `PrivacyInfo.xcprivacy`, używane uprawnienia, deklaracje prywatności, numer wersji, numer buildu i zasoby aplikacji.
- Sprawdź, czy build App Store pokazuje wyłącznie funkcje przeznaczone do wydania oraz czy dostęp Free/Pro jest spójny ze wszystkimi wejściami do treści.
- Porównaj aktualny UI i dostępne funkcje z `README.md` oraz `CHANGELOG.md`; rozbieżności traktuj jako problem wydaniowy.
- Nie dodawaj prywatnych API, nieuzasadnionych uprawnień, ukrytego śledzenia ani zbierania danych bez wyraźnej potrzeby i zgody użytkownika.
- Nie obchodź procesu App Review i nie wysyłaj buildu do App Store Connect bez osobnego zatwierdzenia.
