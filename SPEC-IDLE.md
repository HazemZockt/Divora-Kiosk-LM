# Divora Kiosk LM · Los Angeles Idle Tycoon 0.3

Bestätigt am 12.10.2026: Hochkant, frontaler Kiosk, automatische Verkäufe und Offline-Einnahmen. Neuaufbau nach Nutzerauftrag ohne weitere Freigabe-Unterbrechung. Referenzen dienen der Hierarchie und Cartoon-Stimmung; ihre Assets werden nicht übernommen.

## Fähigkeiten und Reihenfolge
| Modul | Aufgabe | Abhängigkeit |
|---|---|---|
| idle-economy | Sortiment, Kette, reale Liefer-/Bauzeiten, Mitarbeiter, Kosten, Kriminalität | — |
| idle-save | validierter Speicherstand, Backup, v2-Übernahme, Offline-Fortschritt | idle-economy |
| idle-ui | stabile Touch-Oberfläche, Kiosk, LA-Karte/Wahrzeichen, Shop | idle-economy, idle-save |
| ios-notifications | optionale lokale Fertigmeldungen | idle-save |
| release | überprüfte native Builds und heruntergeladene IPA | alle |

## Spielvertrag
- Start bei $0 mit geschenktem Wasservorrat. Verkäufe verdienen Geld, kein unendlicher Gratisgeld-Knopf.
- Sortiment bewusst wählen, Preise einstellen, Kartons bestellen; Lieferungen brauchen reale Zeit. Manager können Nachbestellungen automatisieren.
- Ausbauten und neue Filialen brauchen Geld und Zeit. Nur Juwelen überspringen die Zeit. Keine Werbung und keine echte Zahlung in 0.3.
- Shop mit Juwelenpaketen; Kauf ohne Testfreigabe deaktiviert. Code Hayat aktiviert ausschließlich im Testbuild kostenlose Pakete. Keine Behauptung einer sicheren Admin-Authentifizierung.
- LA-Viertel Echo Park, Venice, Downtown, Santa Monica, Hollywood, Beverly Hills; Karte mit stilisierten Wahrzeichen. Franchise-Runden wiederholbar, steigende Preise und dauerhafter Einkommensbonus.
- Miete und Löhne nach realen Spielstunden. Vapes/Snus als fiktiv regulierte Waren; riskante Entscheidungen erzeugen Polizeirisiko, Strafen und Sperren. Sicherheitsausbau senkt Diebstahl.
- Bis zu 8 Stunden Offline-Verkäufe, laufende Aufgaben werden auch bei längerer Abwesenheit fertig. Pause/Resume darf Zeit nicht doppelt abrechnen.
- Optionale iOS-Benachrichtigungen für fertige Lieferungen/Ausbauten, ohne Server und ohne Kaufpflicht.

## Bedienung und Gestaltung
420px Basis, ab 320px nutzbar, zentrierter Telefonbereich in großen Fenstern. Kopf und fünf Navigationstasten bleiben fest, gesamter Inhalt scrollt. Buttons mindestens 48px. Tick aktualisiert bestehende Labels/ProgressBars, baut keine Controls neu. Drag über Buttons darf keinen Kauf auslösen. Eingaben behalten Fokus und Text. Sichtbare Hinweise für Geldmangel, leere Regale, deaktivierte Käufe, Speichern und Offline-Ertrag.

## Technik und Grenzen
Godot 4.5.1, vorhandene Model/Save/View-Aufteilung. v2-Code und Tests bleiben zur Regression/Migration erhalten. Neue Module in tycoon/idle_*.gd, Tests in tycoon/tests/. Originale generierte Hintergrundgrafik + native animierte Figuren/Karte. Keine neuen Laufzeit-Pakete. Geld in Cent, endliche Werte und obere Zahlengrenzen gegen Überläufe.

## Prüfen
Godot-Binary ../.tools/godot/Godot_v4.5.1-stable_win64_console.exe; APPDATA/LOCALAPPDATA auf ../.tools/godot/editor_data setzen.
- `--headless --path . --editor --import --quit`
- `--headless --path . --script res://tycoon/tests/economy_test.gd`
- `--headless --path . --script res://tycoon/tests/save_test.gd`
- `--headless --path . --script res://tycoon/tests/idle_test.gd`
- `--headless --path . --script res://tycoon/tests/idle_ui_test.gd`
- Exporte Windows/Android lokal, iPhone-iPad auf GitHub macOS.
- Echte Touch-Events im UI-Test und Android-Emulator: Scrollen mehrfach, Drag über Kaufknopf, Textfeld, Tabwechsel, Timer, Schließen/Neustart; Screenshots verschiedener Fenstergrößen.
- IPA: Bundle, Version, iPhone+iPad, arm64, native Notification-Objektdatei im Build. Installation und Benachrichtigungszustellung am echten Apple-Gerät bleiben ohne Gerät unverifiziert.

## Fertig
Tests grün, Änderungen geprüft, GitHub-Build erfolgreich, IPA lokal vorhanden, Anleitung und Testbericht aktuell, PDF-Logbuch fortlaufend gespeichert. Danach ausdrücklich gewünschtes Herunterfahren mit kurzer Verzögerung.
