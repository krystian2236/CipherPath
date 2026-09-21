# AI workflow i human merge gate

Przed merge użytkownik sprawdza na aktualnym commicie: zakres diffu, `git diff --check`, lokalny harness, właściwy build/test, wszystkie CI gates, niezależny review, dokumentację i zachowanie na `SEC`. Każdy actionable finding musi być poprawiony albo jawnie uzasadniony. Merge pozostaje ręczną decyzją użytkownika.
