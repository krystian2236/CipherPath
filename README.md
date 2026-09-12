# CipherPath

<p align="center">
  <img src="CipherPath/Assets.xcassets/AppIcon.appiconset/CipherPathIcon.png" width="160" alt="Ikona CipherPath">
</p>

CipherPath to natywna aplikacja SwiftUI na iOS 17+ do legalnej nauki
cyberbezpieczeństwa na iPhonie. Łączy krótkie lekcje offline z defensywnymi
narzędziami odziedziczonymi z NetScope. Ćwiczenia dotyczą wyłącznie symulacji,
własnych urządzeń i środowisk, na których testowanie uzyskano zgodę.

## Kurs MVP

- pięć ścieżek: Podstawy, Blue Team, Red Team, Web Security i Mobile Security;
- 25 widocznych lekcji: po dwie dostępne i trzy zapowiedziane w każdej ścieżce;
- każda dostępna lekcja prowadzi przez: Poznaj, Sprawdź, Znajdź flagę i Wyjaśnienie;
- bezpieczne symulacje offline oraz przygotowanie do własnego, kontrolowanego labu;
- zachowany Toolbox, diagnostyka prywatnej sieci, iSH i skróty SSH;
- brak automatycznego uruchamiania poleceń i brak publicznych celów labów.

Szczegółowy zakres znajduje się w
`docs/superpowers/specs/2026-09-12-cipherpath-course-design.md`, a realizacja jest
prowadzona etapami po 25% według
`docs/superpowers/plans/2026-09-12-cipherpath-course-mvp.md`.

## Odziedziczone funkcje sieciowe

- pięć czytelnych zakładek: **Start**, **Sieć**, **Porty**, **Ping** i **Bonjour**,
- kompaktowy pulpit z liczbą urządzeń, usług i wyników wymagających uwagi,
- trzy profile skanu prywatnej podsieci IPv4 `/24`: szybki, standardowy
  i rozszerzony,
- wykrywanie typowych usług TCP bez logowania i wysyłania poleceń,
- odwrotne DNS oraz szacowanie rodzaju urządzenia na podstawie usług,
- szczegóły portów: kategoria, opis i informacja o typowym szyfrowaniu,
- lokalna historia ośmiu ostatnich skanów,
- szczegółowe statystyki przebiegu: liczba prób, hostów, odpowiedzi,
  przekroczeń czasu i odmów dostępu,
- telemetria każdego urządzenia: liczba sprawdzonych portów, czas wykrywania
  i opóźnienie otwartych usług,
- odkrywanie usług Bonjour, między innymi AirPlay, drukarek, SSH, HTTP,
  Google Cast, HomeKit, Matter i MQTT,
- filtrowanie urządzeń, rozszerzony widok szczegółów i bogatszy eksport CSV,
- **My IP** z lokalnym IPv4 i opcjonalnym publicznym IPv4/IPv6,
- diagnostyka domen: DNS, TCP ping i test wskazanego portu,
- skaner portów w stylu Nmap z profilami WWW, IoT, zdalnego dostępu,
  serwerów i baz danych oraz zakresem własnym do 512 portów,
- wyniki skanowania pozostają na urządzeniu.

## Integracja z iSH

Ekran **Start → Narzędzia dla iSH** przygotowuje:

- polecenie instalacji Nmap w Alpine,
- polecenie jednorazowego skanu dla podsieci albo wybranego urządzenia,
- skrypt `cipherpath-ish.sh`, który można zapisać w aplikacji Pliki,
  przenieść do lokalizacji iSH i uruchomić,
- trzy tryby: inwentaryzacja, rozszerzony TCP i lekka identyfikacja usług.

CipherPath używa w poleceniach iSH trybu `--unprivileged -sT`, czyli zwykłych
połączeń TCP zamiast surowych pakietów. Cel jest ograniczony do prywatnego IPv4.
Samodzielny skrypt `CipherPath-iSH-Toolkit.sh` jest również dołączony obok paczki
projektu.

Przykładowe uruchomienie w iSH:

```sh
apk update && apk add nmap
chmod +x CipherPath-iSH-Toolkit.sh
./CipherPath-iSH-Toolkit.sh 192.168.1.0/24
```

## Uruchomienie

1. Otwórz `CipherPath.xcodeproj` w Xcode.
2. W ustawieniach targetu `CipherPath` wybierz swój Apple Development Team.
3. Podłącz iPhone’a, wybierz go jako urządzenie docelowe i uruchom aplikację.
4. Naciśnij **Skanuj moją sieć** i zaakceptuj dostęp do sieci lokalnej.

Publiczny adres IP jest odczytywany z `api64.ipify.org` dopiero po wybraniu
przycisku **Pobierz publiczny IP**.

Skanowanie sieci lokalnej należy testować na prawdziwym iPhonie. Symulator nie
odwzorowuje uprawnienia Local Network i może widzieć inną sieć niż telefon.

## Zakres bezpieczeństwa

Aplikacja skanuje wyłącznie prywatny lub link-localny adres IPv4 urządzenia
i ogranicza zakres do lokalnego `/24`. Nie obsługuje publicznych celów,
uwierzytelniania, exploitów ani wykonywania poleceń na wykrytych urządzeniach.

Narzędzie Port Scan pozwala sprawdzić domenę lub adres wskazany przez
użytkownika, ale ogranicza pojedynczy własny zakres do 512 portów. Należy go
używać wyłącznie wobec własnych systemów lub po uzyskaniu zgody właściciela.
„TCP Ping” mierzy czas zestawienia połączenia TCP, ponieważ iOS nie udostępnia
zwykłym aplikacjom surowego ICMP w taki sposób jak narzędzia desktopowe.

Ocena rodzaju urządzenia i poziomu ekspozycji jest wskazówką opartą na
widocznych portach. Nie zastępuje audytu bezpieczeństwa ani nie potwierdza
podatności.
