# CipherPath — interaktywne laboratoria offline

## Cel

Zastąpić powtarzalne analizowanie statycznego tekstu różnorodnymi, kontrolowanymi laboratoriami przypominającymi tok nauki Starting Point: użytkownik uruchamia wirtualny cel, wpisuje polecenia, rozpoznaje usługi, zdobywa flagę i poznaje sposób obrony.

## Zasady bezpieczeństwa

- Laboratorium działa całkowicie lokalnie i nie wykonuje ruchu sieciowego.
- Adres celu jest elementem fikcyjnego środowiska, a nie rzeczywistym hostem.
- Terminal akceptuje wyłącznie polecenia jawnie dozwolone w danej misji.
- Nie ma dowolnych publicznych celów, brute force, phishingu, persistence, eksfiltracji ani automatycznej eksploatacji.
- Każda misja ofensywna kończy się wyjaśnieniem ryzyka i sposobem obrony.
- Próba użycia niedozwolonej komendy lub innego celu zwraca bezpieczny komunikat bez wykonania operacji.

## Tryby gry

Pierwsze przejście odbywa się w trybie prowadzonym: widoczne są cele etapowe, pytania i opcjonalne podpowiedzi. Po ukończeniu misji odblokowuje się tryb przygodowy z samym celem głównym, ograniczonymi wskazówkami i dodatkowym medalem za samodzielne rozwiązanie.

## Przebieg misji

1. Krótka lekcja, zakres prawny i cel.
2. Uruchomienie wirtualnego hosta z prywatnym adresem laboratoryjnym.
3. Wpisywanie komend w terminalu lub wstawienie podpowiadanej komendy jednym dotknięciem.
4. Odczyt realistycznego, deterministycznego wyniku.
5. Rozpoznanie portów, usług, plików albo błędnej konfiguracji.
6. Przesłanie flagi użytkownika; trudniejsze misje mogą zawierać flagę administratora.
7. Wyjaśnienie rozwiązania, opis obrony, XP i medal.

## Interfejs

Ekran laboratorium zawiera pasek stanu maszyny, wirtualny adres celu, przewijalny terminal, pole polecenia, podpowiadane komendy, panel celów, wskazówki, notatnik odkryć i pole przesłania flagi. Terminal zachowuje historię tylko w pamięci bieżącej sesji; trwały zapis obejmuje wyłącznie postęp, użycie podpowiedzi, XP i medale.

## Model i silnik

`LabDefinition` opisuje identyfikator misji, host, dozwolone polecenia, reguły odpowiedzi, cele, flagi i treść obronną. `LabSession` przechowuje stan uruchomienia, historię terminala i odkrycia. `LabCommandParser` normalizuje bezpieczny podzbiór składni, a `LabEngine` dopasowuje polecenie do deterministycznej reguły bez uruchamiania procesu systemowego i bez użycia sieci.

Pierwszy zakres silnika obsługuje `help`, `clear`, `ping`, `nmap`, `curl`, `ftp`, `smbclient`, `ssh`, `ls`, `cd`, `cat`, `find`, `id`, `whoami` i `sudo -l`. Konkretna misja udostępnia tylko potrzebny podzbiór.

## Pakiet MVP

Po dwie misje dla każdej istniejącej ścieżki:

- Podstawy: Network Scout, Port Detective.
- Blue Team: Log Hunter, Incident Lockdown.
- Red Team: Forgotten FTP, Permission Trail.
- Web Security: Hidden Web, Unsafe API.
- Mobile Security: iPhone Vault, Mobile Traffic Inspector.

Każda ścieżka nadal pokazuje trzy zaszarzone zapowiedzi. Misje różnią się sekwencją komend, rodzajem materiału, liczbą flag i warunkiem zdobycia medalu.

## Etapy dostarczenia

1. 25% — model danych, parser, bezsieciowy silnik, przykładowy host i testy jednostkowe.
2. 50% — terminal oraz kompletne misje Network Scout i Hidden Web.
3. 75% — pozostałe osiem misji, tryb przygodowy, XP i medale.
4. 100% — integracja postępu, dostępność, testy całego przepływu i kontrola Xcode.

## Poza zakresem

Mac Lab Runner, UTM, Docker, VPN, prawdziwe skanowanie sieci, konta, synchronizacja chmurowa, publiczny ranking, płatności i pobieranie definicji misji z serwera.
