# CipherPath — standard pracy AI

To specyfikacja procesu, nie zmiana zakresu produktu. Istniejące specyfikacje i plany w `docs/superpowers/` pozostają źródłem wymagań funkcjonalnych.

## Acceptance criteria procesu

- Zachowane są `AGENTS.md` i bieżące lokalne zmiany.
- Każda faza ma mały diff, kryteria akceptacji i dowód walidacji.
- Lokalny harness sprawdza dokumenty, diff i nazwy potencjalnych sekretów.
- Pull request uruchamia build/integrity, CodeQL i dependency review na aktualnym commicie.
- Niezależny reviewer działa read-only ze świeżym kontekstem.
- Merge wymaga ręcznej decyzji po aktualnym CI, review i kontroli runtime na `SEC`.
