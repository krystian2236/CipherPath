# CipherPath

<p align="center">
  <img src="CipherPath/Assets.xcassets/AppIcon.appiconset/CipherPathIcon.png" width="160" alt="Ikona CipherPath">
</p>

CipherPath to natywna aplikacja SwiftUI na iOS 17+ do legalnej nauki
cyberbezpieczeństwa na iPhonie. Łączy lekcje i laboratoria offline z defensywnymi
narzędziami do pracy we własnej sieci lub środowisku, na którego testowanie
uzyskano zgodę.

## Aktualny stan aplikacji

Bieżący katalog zawiera pięć ścieżek nauki:

- **Podstawy**,
- **Blue Team**,
- **Red Team**,
- **Web Security**,
- **Mobile Security**.

Każda ścieżka ma pięć lekcji, czyli łącznie **25 lekcji**. Każda aktualnie
wydana lekcja przechodzi przez cztery etapy:

1. **Poznaj**,
2. **Sprawdź**,
3. **Znajdź odpowiedź**,
4. **Wyjaśnienie**.

Materiały szkoleniowe i przygotowane laboratoria działają lokalnie. Aplikacja
nie uruchamia automatycznie poleceń na zewnętrznych systemach i nie udostępnia
publicznych celów treningowych.

### Dostęp do lekcji

Kod zawiera przygotowany model `free`, `testFlightDemo` i `pro`, ale w bieżącym
wydaniu nie ma jeszcze StoreKit ani obsługi płatnego entitlementu. Dlatego
aktualna polityka Release udostępnia cały gotowy katalog zamiast pokazywać
martwą blokadę PRO bez możliwości zakupu.

Docelowe ograniczenia Free/Pro pozostają w modelu jako przygotowanie pod
przyszłą, pełną integrację StoreKit.

## Nawigacja

W buildzie App Store użytkownik widzi cztery główne zakładki:

- **Start** — polecana lekcja, punkty i podsumowanie osiągnięć,
- **Ścieżki** — pięć ścieżek i 25 lekcji,
- **Praktyka** — narzędzia sieciowe i defensywny Toolbox,
- **Osiągnięcia** — postęp i odblokowane osiągnięcia.

W buildzie developerskim dodatkowo dostępna jest zakładka **Misje**. Obecnie
jest to ekran zapowiadający przyszłe, niezależne wyzwania i dlatego nie jest
pokazywany w buildzie App Store.

Podobnie przyszły **Sklep** pozostaje widoczny wyłącznie w development do czasu
wdrożenia rzeczywistego StoreKit.

## Polecana lekcja i postęp

Ekran Start wybiera polecaną lekcję przez tę samą politykę dostępu co widok
Ścieżek. Dzięki temu lekcja nie może być zablokowana w jednym miejscu i dostępna
inną drogą w tym samym buildzie.

Postęp nauki, punkty i osiągnięcia są przechowywane lokalnie na urządzeniu.
Punkty mogą być używane przez przygotowane mechanizmy podpowiedzi i rozwiązań w
laboratoriach.

## Praktyka

Zakładka **Praktyka** grupuje funkcje sieciowe w jednym miejscu:

- skan prywatnej sieci lokalnej,
- listę wykrytych urządzeń,
- szczegóły urządzeń i widocznych usług,
- skanowanie wybranych portów TCP,
- DNS, lokalny i opcjonalny publiczny adres IP oraz TCP Ping,
- wykrywanie usług Bonjour,
- defensywny Toolbox.

Skan sieci lokalnej jest ograniczony do prywatnego lub link-localnego IPv4 i
lokalnego zakresu `/24`.

## CipherPath Toolbox

Toolbox prowadzi użytkownika przez workflow:

**Discover → Inspect → Verify**.

Najpierw wykonywany jest lokalny skan i wybór konkretnego urządzenia. Dalsze
narzędzia korzystają wyłącznie z bieżącego kontekstu sieci i wybranego celu.
CipherPath może przygotować polecenie do skopiowania lub przekazania do
skonfigurowanego klienta SSH, ale nie wykonuje go automatycznie na zdalnym
urządzeniu.

Biblioteka skrótów SSH oraz narzędzia współpracujące z iSH służą do pracy we
własnym środowisku. Aplikacja nie przechowuje haseł ani kluczy prywatnych.

## Funkcje sieciowe

Aktualny kod obejmuje między innymi:

- trzy profile skanowania prywatnej podsieci: szybki, standardowy i rozszerzony,
- wykrywanie typowych usług TCP bez logowania do urządzeń,
- odwrotne DNS i rozpoznawanie nazw hostów,
- szacowanie rodzaju urządzenia na podstawie widocznych usług,
- opis portów, kategorię usługi i informację o typowym szyfrowaniu,
- statystyki przebiegu skanu i telemetrię prób TCP,
- wykrywanie usług Bonjour, między innymi HTTP, SSH, drukarek, AirPlay,
  Google Cast, HomeKit, Matter i MQTT,
- skaner portów z profilami oraz własnym zakresem ograniczonym do 512 portów,
- diagnostykę DNS i TCP,
- lokalny adres IP oraz opcjonalne pobranie publicznego IPv4/IPv6.

Publiczny adres IP jest pobierany z `api64.ipify.org` dopiero po świadomym
wybraniu odpowiedniej funkcji przez użytkownika.

## Prywatność

CipherPath nie wymaga konta i w obecnym kodzie nie zawiera reklam, analityki ani
śledzenia. Postęp, historia skanów i informacje o znanych urządzeniach są
przechowywane lokalnie.

`PrivacyInfo.xcprivacy` deklaruje brak śledzenia i brak zbieranych typów danych.
Dostęp do sieci lokalnej jest opisany w `Info.plist` i jest potrzebny do
funkcji skanowania oraz Bonjour.

## Uruchomienie

1. Otwórz `CipherPath.xcodeproj` w Xcode.
2. W ustawieniach targetu wybierz swój Apple Development Team.
3. Uruchom aplikację na iPhonie albo właściwym Simulatorze.
4. Do testów skanowania sieci lokalnej użyj prawdziwego iPhone’a podłączonego do
   testowanej sieci Wi‑Fi.
5. Przy pierwszym użyciu funkcji sieciowych zaakceptuj dostęp do sieci lokalnej.

Preferowany Simulator developerski jest nazwany `CipherPath — iPhone 17`, ale
jego UDID nie jest traktowany jako stały. Aktualny identyfikator należy ustalać
z `xcrun simctl list devices available`.

## Zakres bezpieczeństwa

Automatyczny skan CipherPath działa wyłącznie w prywatnej sieci lokalnej.
Toolbox i przygotowywane polecenia należy uruchamiać tylko wobec własnych
urządzeń lub systemów objętych zgodą właściciela.

Aplikacja nie zawiera modułów eksploatacji, łamania haseł ani automatycznego
uwierzytelniania do wykrytych urządzeń. Ocena rodzaju urządzenia i poziomu
ekspozycji jest wskazówką opartą na widocznych usługach i nie potwierdza
podatności.

„TCP Ping” mierzy czas zestawienia połączenia TCP. Zwykła aplikacja iOS nie ma
takiego dostępu do surowego ICMP jak typowe narzędzia desktopowe.

## Dokumentacja projektu

Szczegółowy projekt kursu znajduje się w:

`docs/superpowers/specs/2026-09-12-cipherpath-course-design.md`

Plan realizacji MVP znajduje się w:

`docs/superpowers/plans/2026-09-12-cipherpath-course-mvp.md`

Zasady pracy agentów są zapisane w `AGENTS.md`, a ręczny audyt gotowości do
App Store jest opisany w `.github/agents/app-store-reviewer.agent.md`.
