# CP-03 — lokalne testy StoreKit

## Cel

Zweryfikować zakup Pro i subskrypcję bez App Store Connect, bez Sandbox Apple Account i bez prawdziwych opłat.

Ten etap bazuje na StoreKit Testing in Xcode. Lokalna konfiguracja StoreKit zastępuje dane App Store podczas uruchomienia z aktywnym plikiem `.storekit`.

## Konfiguracja lokalna w Xcode

1. File → New → File from Template.
2. Wybierz **StoreKit Configuration File**.
3. Utwórz lokalny plik bez synchronizacji z App Store Connect.
4. Nazwij go `CipherPath.storekit`.
5. Dodaj:
   - Non-Consumable: `local.cipherpath.pro`
   - Auto-Renewable Subscription: `local.cipherpath.subscription.monthly`
   - Auto-Renewable Subscription: `local.cipherpath.subscription.yearly`
6. W schemacie **CipherPath Dev** otwórz Edit Scheme → Run → Options.
7. Ustaw StoreKit Configuration na `CipherPath.storekit`.
8. Schemat **CipherPath App Store** pozostaw bez lokalnej konfiguracji StoreKit.

## Konfiguracja Product ID dla lokalnego testu

W buildzie developerskim ustaw:

- `CipherPathProProductID = local.cipherpath.pro`
- `CipherPathSubscriptionProductIDs = local.cipherpath.subscription.monthly,local.cipherpath.subscription.yearly`

Nie używaj tych identyfikatorów jako produkcyjnych Product ID.

## Scenariusze obowiązkowe

### T01 — start bez zakupów

Oczekiwane:
- poziom FREE;
- darmowa zawartość działa;
- Pro pozostaje zablokowane;
- sklep pokazuje produkty z lokalnej konfiguracji.

### T02 — zakup lifetime Pro

Oczekiwane:
- systemowy arkusz testowego zakupu;
- wynik `purchased`;
- poziom PRO bez restartu aplikacji;
- aktualne misje Pro zostają odblokowane.

### T03 — zakup subskrypcji

Oczekiwane:
- poziom SUB;
- Pro pozostaje dostępne;
- `hasActiveSubscription == true`.

### T04 — Pro + subskrypcja

Najpierw kup lifetime Pro, później subskrypcję.

Oczekiwane:
- bieżący poziom SUB;
- `hasLifetimePro == true`;
- po wygaśnięciu/usunięciu subskrypcji dostęp wraca do PRO, nie FREE.

### T05 — anulowanie zakupu

Anuluj arkusz płatności.

Oczekiwane:
- wynik `cancelled`;
- brak zmiany entitlementów;
- brak komunikatu sugerującego błąd płatności.

### T06 — pending / Ask to Buy

W lokalnym środowisku StoreKit włącz warunek oczekującego zakupu.

Oczekiwane:
- wynik `pending`;
- zawartość nie zostaje odblokowana przed zweryfikowaną transakcją.

### T07 — przerwany zakup

W konfiguracji StoreKit włącz Interrupted Purchases.

Oczekiwane:
- brak przedwczesnego odblokowania;
- po rozwiązaniu transakcji aktualizacja z `Transaction.updates`;
- zweryfikowana transakcja zostaje zakończona.

### T08 — przywracanie bez zakupów

Usuń wszystkie transakcje w Debug → StoreKit → Manage Transactions i użyj „Przywróć zakupy”.

Oczekiwane:
- operacja kończy się bez odblokowania Pro/Sub;
- aplikacja pozostaje używalna.

### T09 — przywracanie Pro

Po zakupie Pro uruchom ponownie aplikację i użyj przywracania.

Oczekiwane:
- `currentEntitlements` odtwarza lifetime Pro;
- poziom PRO.

### T10 — odnowienie i wygaśnięcie subskrypcji

Przyspiesz Subscription Renewal Rate w lokalnym StoreKit.

Oczekiwane:
- odnowienie zachowuje SUB;
- wygaśnięcie usuwa SUB;
- jeśli lifetime Pro istnieje, poziom wraca do PRO;
- bez lifetime Pro poziom wraca do FREE.

## Kontrola bezpieczeństwa

- nie odblokowywać zawartości na podstawie samego builda Developer;
- nie ufać niezweryfikowanym transakcjom;
- nie zapisywać ceny jako stałej wartości w kodzie;
- nie uruchamiać zakupu automatycznie przy wejściu do widoku;
- `AppStore.sync()` tylko po świadomej akcji „Przywróć zakupy”;
- Store build nie może używać lokalnych Product ID.

## Kryterium zakończenia CP-03

CP-03 jest zakończony dopiero wtedy, gdy T01–T10 mają zapisany wynik PASS/FAIL/BLOCKED dla konkretnego commita i konkretnego środowiska testowego.
