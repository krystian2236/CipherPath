# CipherPath Design QA

## Etap 50% — ekran Start i nawigacja kursu

- Data: 2026-09-12
- Urządzenie docelowe: iPhone 17 Simulator
- Referencja: `docs/design/cipherpath-approved-home.png`
- Stan kompilacji: aplikacja i testy kompilują się w Xcode
- Stan testów: 53/53 testy zaliczone (29 XCTest + 24 Swift Testing)
- Stan uruchomienia: Xcode potwierdził `Running CipherPath on iPhone 17`
- Pięć zakładek: Start, Ścieżki, Misje, Praktyka, Osiągnięcia
- Narzędzia sieciowe: zachowane w zakładce Praktyka

## Kontrola wizualna

Automatyczne przechwycenie ekranu jest zablokowane, ponieważ proces `simctl`
nie ma połączenia z `CoreSimulatorService` w bieżącym środowisku. Nie wykonano
więc wiarygodnego porównania pikselowego z zatwierdzoną makietą.

## Wynik

`blocked` — implementacja i testy są poprawne, ale Step 5 etapu 50% pozostaje
otwarty do czasu wykonania i oceny zrzutu ekranu bez błędów P0–P2.
