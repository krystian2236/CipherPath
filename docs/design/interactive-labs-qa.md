# Interactive Labs QA — 2026-09-12

## Zakres

- iPhone 17 Simulator, iOS Simulator 27.0.
- Build z worktree `feat/lesson-progress`.
- Katalog 10 laboratoriów, tryby gry, postęp, XP i osiągnięcia.

## Weryfikacja automatyczna

- Pełny target testów: passed, 80/80.
- Parser blokuje operatory powłoki i nieznane programy.
- Silnik odrzuca inny cel i nie wykonuje sieci ani procesów.
- Flagi są zablokowane do czasu ukończenia wymaganych celów.
- Katalog ma 10 unikalnych laboratoriów, po dwa na ścieżkę.
- Wszystkie flagi są osiągalne w regułach, a podpowiedzi wskazują istniejące reguły.
- Tryb Adventure odblokowuje się po Guided; XP jest idempotentne.
- Checkpoint nie zapisuje historii terminala ani wpisanych komend.

## Weryfikacja uruchomienia

- Debug build: passed.
- Instalacja w osobnym iPhone 17 Simulator: passed.
- Uruchomienie bundle `pl.krystian.CipherPath`: passed.
- Ekran Start: passed; poprawna nazwa CipherPath, pięć zakładek, nowa karta „Incident Lockdown”, brak odniesień do NetScope.
- Zrzut kontrolny: `/private/tmp/cipherpath-interactive-labs-100.png`.

## Dostępność i wygląd

- Widoczne etykiety przycisków i stan maszyny: sprawdzone kompilacyjnie.
- Terminal ma etykietę VoiceOver, przycisk wykonania ma opis, tekst wspiera Dynamic Type.
- Brak zauważonych problemów P0–P2 na ekranie Start.

## Ograniczenie kontroli ręcznej

Środowisko automatyzacji nie udostępniło powierzchni sterowania oknem iOS Simulator, dlatego nie wykonano klikanej kontroli wszystkich 10 ekranów terminala ani macierzy Dynamic Type. Logika pełnych przepływów, blokad, flag, trybów, zapisu i nagród została pokryta testami uruchomionymi w iPhone 17 Simulator.

## Wynik

`passed with manual UI limitation` — brak błędów kompilacji, testów i ekranu startowego; pełne ręczne przejście UI pozostaje do wykonania przed wydaniem do App Store.
