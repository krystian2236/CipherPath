# CipherPath Android Demo — specyfikacja

## Cel

Przygotować małe, prywatne i działające demo CipherPath na Androida, które można przekazać jednej osobie do oceny wyglądu, zakładek i przebiegu nauki znanego z wersji iPhone. Demo ma zawierać trzy sprawdzalne misje, ale nie odtwarzać całej funkcjonalności iOS ani wykonywać prawdziwych działań sieciowych.

## Granice wersji demo

- osobny projekt i prywatne repozytorium `CipherPath-Android`;
- nazwa aplikacji: `CipherPath Demo`;
- identyfikator pakietu: `pl.krystian.cipherpath.demo`;
- interfejs w języku polskim;
- działanie całkowicie offline;
- minimalna wersja: Android 10 (API 29);
- brak konta, subskrypcji, zakupów, analityki i integracji z NetScope;
- wszystkie wskazówki i pełne rozwiązania są bezpłatne;
- wygląd ma odpowiadać wersji iPhone, a trzy misje i ich podstawowe funkcje muszą działać;
- brak prawdziwego skanowania, połączeń SSH i wykonywania poleceń systemowych;
- kod, README i plik APK pozostają prywatne.

## Zakres funkcjonalny i prezentacyjny

### Start

Ekran odwzorowuje zatwierdzony wygląd iPhone: ciemne tło, nagłówek CipherPath, dużą kartę „Dzisiejsza misja”, etapy misji, poziomy postępu, kolorowe ścieżki oraz medale. Przycisk misji otwiera jej opis, a nie uruchamia zadania automatycznie.

### Zakładki

Dolna nawigacja pokazuje pięć zakładek zgodnych z iPhone: Start, Ścieżki, Misje, Praktyka i Osiągnięcia. Każda zakładka otwiera dopracowany ekran podglądowy. Elementy, które nie są potrzebne do oceny demo, mogą być nieaktywne i oznaczone jako „Wkrótce”.

### Ścieżki

Demo zawiera trzy działające misje:

1. **Network Scout** — rozpoznanie hosta i usług na podstawie symulowanego wyniku skanowania.
2. **Suspicious Login** — analiza krótkiego dziennika logowania i wskazanie anomalii.
3. **Hidden Web** — odnalezienie ukrytego zasobu w przygotowanych odpowiedziach HTTP.

`Network Scout`, `Suspicious Login` i `Hidden Web` można przejść od odprawy do ukończenia. Kolejne dwie pozycje są zablokowanymi zapowiedziami aktualizacji. Elementy przyszłe, takie jak konto, sklep, subskrypcja i integracja z NetScope, pozostają nieaktywne.

### Misja

Każda z trzech misji ma czytelny przebieg:

1. krótka historia i legalny cel ćwiczenia;
2. lista etapów;
3. symulowany terminal;
4. pole do samodzielnego wpisania odpowiedzi;
5. opcjonalna, bezpłatna wskazówka otwierana przyciskiem „Chcę wskazówkę”;
6. bezpłatne pełne rozwiązanie otwierane osobno przyciskiem „Pokaż rozwiązanie” i potwierdzeniem decyzji;
7. podsumowanie wyniku i lokalne zapisanie ukończenia.

Terminal przyjmuje tylko polecenia przewidziane dla danej misji. Odpowiedzi są prezentowane jako zwykłe, opisane wartości do przepisania, bez niezrozumiałego formatu flagi. Wskazówka ani rozwiązanie nie pojawiają się automatycznie po błędzie lub upływie czasu. Użytkownik sam wybiera pomoc; skorzystanie z niej nie blokuje misji ani kolejnych treści.

### Postęp

Lokalnie zapisujemy:

- ukończone misje;
- użyte wskazówki;
- otwarte pełne rozwiązania;
- zdobyte punkty;
- ostatnio otwartą misję.

Usunięcie danych aplikacji resetuje cały postęp. Demo nie wysyła danych poza urządzenie.

## Architektura

- Kotlin;
- Jetpack Compose i Material 3;
- pojedynczy moduł aplikacji;
- nawigacja Compose między pięcioma zakładkami, odprawą i misją pokazową;
- dane misji zapisane lokalnie jako modele Kotlin;
- DataStore Preferences dla małego stanu postępu;
- logika misji oddzielona od widoków, aby można ją było testować jednostkowo;
- brak backendu i zależności sieciowych.

Projekt powinien używać aktualnego stabilnego zestawu Android Gradle Plugin, Kotlin i Compose dostępnego podczas tworzenia. Wersje zostaną przypięte w repozytorium, a ich zgodność potwierdzona czystym buildem.

## Bezpieczeństwo i prywatność

- wszystkie adresy, logi, usługi i wyniki są fikcyjnymi danymi laboratorium;
- aplikacja nie prosi o uprawnienia sieci lokalnej, lokalizacji, kontaktów ani plików;
- nie przechowuje haseł, tokenów, kluczy ani danych osobowych;
- repozytorium nie zawiera kluczy podpisujących;
- przekazanie APK odbywa się prywatnie, poza publicznym GitHub Releases i Google Play.

## Dystrybucja pierwszego demo

Pierwsza wersja będzie instalowalnym debug APK z lokalnym podpisem deweloperskim. Odbiorca instaluje go ręcznie po jednorazowym zezwoleniu Androida na instalację z wybranego źródła. Publikacja w Google Play i trwałe podpisywanie wydania są osobnym późniejszym etapem.

## Kryteria ukończenia

- aplikacja buduje się od czystego checkoutu;
- pięć zakładek otwiera właściwe ekrany podglądowe;
- trzy misje działają od odprawy do ukończenia;
- błędna odpowiedź nie kończy etapu;
- wskazówka i pełne rozwiązanie są bezpłatne, opcjonalne i nigdy nie ujawniają się automatycznie;
- użycie wskazówki lub rozwiązania jest odnotowane w lokalnym wyniku, ale nie blokuje postępu;
- postęp pozostaje po ponownym uruchomieniu aplikacji;
- brak dostępu do sieci i zbędnych uprawnień potwierdza manifest;
- testy logiki misji przechodzą;
- APK instaluje się i uruchamia na zgodnym urządzeniu lub emulatorze;
- README opisuje aktualny zakres, prywatny sposób instalacji i ograniczenia demo.

## Poza zakresem

- pełny katalog misji CipherPath iOS;
- synchronizacja między urządzeniami;
- prawdziwe laboratoria, VPN, maszyny wirtualne i skanowanie sieci;
- NetScope i łącza między aplikacjami;
- logowanie, płatności, płatne wskazówki, punkty kupowane za pieniądze i subskrypcja;
- publikacja publiczna.
