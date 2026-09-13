# CipherPath Pro 25% — projekt punktów i podpowiedzi

## Cel

Dodać lokalny portfel punktów, który nagradza ukończenie misji i pozwala wydawać punkty na podpowiedzi oraz pełne rozwiązania. Wersja deweloperska zachowuje pełny, nielimitowany dostęp testowy. Ten etap nie obejmuje konta, synchronizacji, StoreKit ani płatności.

## Zasady produktu

- Nowy użytkownik wersji App Store otrzymuje 100 punktów.
- Pierwsze ukończenie danej misji przyznaje 100 punktów.
- Podpowiedź kosztuje 20 punktów.
- Pełne rozwiązanie kosztuje 50 punktów.
- Nagrodę za misję można otrzymać tylko raz, niezależnie od ponownych ukończeń i trybu misji.
- Użyta pomoc pomniejsza saldo natychmiast. Nagroda za ukończenie nadal wynosi 100 punktów, więc podsumowanie misji pokazuje osobno nagrodę i wydatki.
- Transakcja nie może sprowadzić salda poniżej zera.
- Raz odblokowana pomoc pozostaje dostępna bez ponownego obciążenia dla tej samej misji i trybu.
- Debug, czyli `CipherPath Dev`, ma nielimitowane punkty i nie blokuje podpowiedzi ani rozwiązania.

## Architektura

`PointsWallet` jest osobnym modelem domenowym odpowiedzialnym za saldo, księgę operacji i reguły obciążania. Każda operacja ma stabilny identyfikator, rodzaj, wartość, datę oraz opcjonalny identyfikator misji i trybu. Saldo wersji App Store jest wyliczane z księgi, a nie przechowywane jako niezależna, możliwa do rozjechania wartość.

`LearningProgress` przechowuje portfel razem z dotychczasowym postępem w istniejącym rekordzie Codable. Dekodowanie zachowuje zgodność ze starszymi zapisami: brak portfela tworzy saldo początkowe 100 punktów. `LearningProgressStore` jest jedynym miejscem, które przyznaje nagrodę, kupuje pomoc i zapisuje wynik.

`LabTerminalView` nie modyfikuje salda bezpośrednio. Prosi magazyn o zakup i reaguje na wynik: odblokowanie, brak środków albo już kupiona pomoc. Dzięki temu UI, testy i późniejszy StoreKit korzystają z tych samych reguł.

## Model danych

- `PointsTransaction`: identyfikator, typ, liczba punktów ze znakiem, data, `lessonID`, opcjonalny `LabMode`.
- `PointsTransactionKind`: saldo początkowe, nagroda za misję, podpowiedź, rozwiązanie, korekta deweloperska.
- `PointsWallet`: lista transakcji oraz wyliczane saldo.
- `PointsPurchase`: podpowiedź za 20 punktów albo rozwiązanie za 50 punktów.
- `PointsPurchaseResult`: zakupiono, już odblokowano, brak środków z podaną brakującą liczbą punktów.

Idempotencję zapewniają deterministyczne klucze operacji oparte na rodzaju, misji i trybie. Nagroda używa klucza misji bez trybu, aby ukończenie Guided i Adventure nie naliczało dwóch nagród.

## Przepływ użytkownika

Karta „Punkty” na ekranie Start staje się aktywna i pokazuje saldo. Prowadzi do ekranu historii z najnowszymi operacjami na górze. Karta „Sklep” pozostaje nieaktywna i oznaczona jako „Wkrótce”.

Przed pierwszym ujawnieniem pomocy użytkownik potwierdza koszt. Po poprawnym zakupie podpowiedź pojawia się jako `Wskazówka: …`, a rozwiązanie odblokowuje gotowe polecenia. Jeśli brakuje punktów, aplikacja pokazuje dokładną brakującą wartość i nie ujawnia treści.

Po pierwszym ukończeniu misji ekran wyniku pokazuje nagrodę 100 punktów, wydatki poniesione w tej misji oraz zmianę netto. Kolejne ukończenie informuje, że nagroda została już odebrana.

## Wersja deweloperska

`CipherPath Dev` pokazuje saldo jako nielimitowane, nie pobiera punktów za pomoc i zachowuje natychmiastowy dostęp do odpowiedzi. Osobna sekcja diagnostyczna, kompilowana wyłącznie w Debug, pozwala dodać punkty, wyzerować testowy portfel i zresetować historię. Narzędzia te nie trafiają do Release.

## Trwałość i błędy

Operacja jest dopisywana do portfela i zapisywana razem z postępem tylko wtedy, gdy cała reguła się powiedzie. Nieudany zakup nie zmienia danych. Starszy lub częściowo uszkodzony wpis portfela nie może usuwać postępu misji; aplikacja korzysta z bezpiecznych wartości domyślnych i pomija nierozpoznane dane tam, gdzie pozwala na to Codable.

Reset całego postępu resetuje także portfel. Reset deweloperski portfela nie resetuje ukończonych misji, dzięki czemu oba zachowania są jawnie rozdzielone.

## Testowanie

Testy jednostkowe obejmują saldo początkowe, pojedynczą nagrodę za misję, brak podwójnej nagrody między trybami, zakup podpowiedzi, zakup rozwiązania, ponowne ujawnienie bez opłaty, odmowę przy zbyt małym saldzie, trwałość po ponownym utworzeniu magazynu oraz nielimitowany tryb Dev.

Testy widoków zastępują testy modeli tam, gdzie logika jest możliwa do wyodrębnienia: konfiguracja kart Start, treść podsumowania i komunikaty zakupowe mają być tworzone przez małe, testowalne modele prezentacyjne. Końcowa weryfikacja obejmuje pełny zestaw testów, `git diff --check`, `./scripts/pre-push-check.sh` oraz ręczny przebieg jednej misji na `CipherPath Dev` i jednej konfiguracji Release w symulatorze.

## Poza zakresem

- StoreKit 2, subskrypcje i pakiety punktów.
- Logowanie przez Apple i synchronizacja między urządzeniami.
- Serwerowe potwierdzanie transakcji.
- Nowe misje albo zmiany istniejącej zawartości demo.
- Publikacja w TestFlight lub App Store Connect.

## Kryteria zakończenia

Etap 25% jest zakończony, gdy portfel działa lokalnie, wszystkie operacje są idempotentne, użytkownik nie może wydać więcej niż posiada, Dev pozostaje bez blokad, karta „Sklep” nadal jest tylko zapowiedzią, a wszystkie testy i kontrola przed pushem przechodzą.
