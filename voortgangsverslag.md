# Voortgangsverslag

Korte samenvatting van wat er deze week is toegevoegd.

## Nieuwe features

### Reservatie-logica
Gebruikers kunnen nu toestellen reserveren via het detailscherm. De `reservation_provider` werd uitgebreid en `device_detail.dart` toont nu de reservatie-functionaliteit (datumselectie, beschikbaarheid, bevestiging).

### Chat-functionaliteit
Volledige chat-logica toegevoegd:
- Nieuwe `chat_provider.dart` voor het beheren van gesprekken.
- `chats_screen.dart` en `chat_detail_screen.dart` werden uitgewerkt zodat gebruikers berichten kunnen sturen en ontvangen via Firestore.
- Push notifications via een nieuwe `notification_service.dart` (Android-permissions toegevoegd in `AndroidManifest.xml`).

### Foto's bij toestellen
Gebruikers kunnen nu foto's vanaf hun toestel toevoegen aan een product/device. Aanpassingen in `device_provider.dart` en `add_device.dart`.

### Toestellen bewerken
Bestaande toestellen kunnen nu bewerkt worden (`add_device.dart` werd hergebruikt voor edit-modus). Extra methodes toegevoegd in `device_provider.dart` en `firestore_service.dart`. `my_devices.dart` toont nu bewerk-acties.

## Refactoring & opkuis
- Grote refactor van `homepage.dart`, `device_detail.dart`, `profile.dart` en `all_devices_screen.dart` voor properere structuur.
- Oude `productspage.dart` verwijderd (vervangen door `all_devices_screen.dart`).
- Bottom navigation (`bottom_nav.dart`) vereenvoudigd.

## Bugfixes / kleine verbeteringen
- "Working Documents" commit: kleine fixes in `add_device.dart`, `device_detail.dart`, `map_screen.dart` en `all_devices_screen.dart` zodat de schermen correct werken na de OpenStreetMap-integratie.
