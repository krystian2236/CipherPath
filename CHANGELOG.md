# CipherPath — historia zmian

## Unreleased

- dodano pięć ścieżek nauki: Podstawy, Blue Team, Red Team, Web Security i Mobile Security,
- dodano pełny katalog 25 lekcji z etapami: Poznaj, Sprawdź, Znajdź odpowiedź i Wyjaśnienie,
- dodano przygotowane laboratoria i terminal szkoleniowy działające w kontrolowanym środowisku offline,
- dodano ekran Start z polecaną lekcją, punktami i podsumowaniem osiągnięć,
- dodano zapisywanie postępu nauki, system punktów oraz osiągnięcia,
- uporządkowano główną nawigację na Start, Ścieżki, Praktyka i Osiągnięcia w buildzie App Store,
- pozostawiono zakładkę Misje jako developerski podgląd przyszłych niezależnych wyzwań,
- ukryto przyszły Sklep w buildzie App Store do czasu wdrożenia rzeczywistego StoreKit,
- ujednolicono dostęp do polecanej lekcji i Ścieżek przez wspólną politykę dostępu,
- dodano tymczasową politykę Release otwierającą cały gotowy katalog do czasu wdrożenia StoreKit i entitlementów,
- przebudowano Toolbox wokół workflow Discover → Inspect → Verify i wybranego urządzenia,
- zgrupowano skan sieci, urządzenia, usługi i diagnostykę w zakładce Praktyka,
- poprawiono tekst dostępności postępu skanowania tak, aby VoiceOver odczytywał rzeczywiste wartości,
- rozszerzono zasady agentów o kontrolę spójności UI, README, CHANGELOG, Free/Pro i powierzchni Release,
- usunięto stały UDID Simulatora z instrukcji pracy i zastąpiono go dynamicznym wyborem urządzenia,
- zaktualizowano README do faktycznego stanu aplikacji,
- dodano przełącznik języka aplikacji (System/Polski/Angielski) dostępny z ikony ustawień na ekranie Start,
- przeniesiono teksty ekranu Start i pulpitu do String Catalog, dzięki czemu są w pełni dwujęzyczne (PL/EN).

## 1.3

- dodano ekran szczegółów przebiegu skanowania,
- dodano liczbę zaplanowanych i wykonanych prób TCP,
- dodano podział odpowiedzi na otwarte, zamknięte, bez odpowiedzi i bez dostępu,
- dodano czas wykrywania urządzenia oraz opóźnienie poszczególnych usług,
- dodano generator poleceń i skryptów dla iSH,
- dodano profile iSH: inwentaryzacja, rozszerzony TCP i szczegóły usług,
- ograniczono generowane cele iSH do prywatnych adresów IPv4,
- dodano samodzielny skrypt `CipherPath-iSH-Toolkit.sh`,
- rozszerzono testy telemetrii i generatora poleceń.

## 1.2

- przebudowano aplikację na pięć kompaktowych zakładek,
- dodano pulpit z podsumowaniem sieci i historią skanów,
- dodano profil rozszerzony i zwiększono zakres własny do 512 portów,
- dodano profile zdalnego dostępu oraz serwerów i baz danych,
- dodano odwrotne DNS i rozpoznawanie nazw urządzeń,
- dodano szacowanie typu urządzenia i poziomu ekspozycji,
- rozszerzono informacje o usługach: opis, kategoria i typowe szyfrowanie,
- dodano filtry urządzeń i bogatszy eksport CSV,
- zmniejszono typografię, odstępy i rozmiary kart,
- rozszerzono testy modeli, profili i walidacji portów.

## 1.1

- dodano moduł **My IP** z lokalnym IPv4 i opcjonalnym publicznym IPv4/IPv6,
- dodano rozwiązywanie nazw DNS,
- dodano **TCP Ping** z pomiarem czasu zestawienia połączenia,
- dodano test pojedynczego portu dla adresu IP lub domeny,
- dodano skaner portów **Nmap-style**,
- dodano profile Popularne, WWW i IoT,
- dodano własny zakres ograniczony do 256 portów,
- dodano zatrzymywanie skanu i filtrowanie zamkniętych portów,
- rozszerzono informacje o prywatności i ograniczeniach iOS,
- dodano testy walidacji hostów i portów.

## 1.0

- skanowanie prywatnej podsieci IPv4 `/24`,
- wykrywanie usług Bonjour,
- widok urządzeń i popularnych usług TCP,
- eksport wyników do CSV.
