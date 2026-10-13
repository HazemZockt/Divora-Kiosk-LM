# Divora Kiosk LM

**0.3.0 Testversion - Los Angeles Idle Tycoon.** Starte bei $0 mit einem frontalen Kiosk und 24 Wasserflaschen. Verkaufe, bestelle nach und baue eine Kette in Los Angeles auf. Geöffnete Läden arbeiten automatisch; Manager übernehmen den Nachschub. Alle Wirtschafts- und Polizeiregeln sind fiktive Spielregeln.

## Ausprobieren

- **Windows:** `build/DivoraKioskLM-Windows.exe` öffnen. Godot muss zum Spielen nicht installiert werden.
- **iPhone/iPad:** `build/ios/DivoraKioskLM-unsigned.ipa` mit dem eigenen Apple-Account signieren und installieren. Anleitung: [IOS-GITHUB.md](IOS-GITHUB.md).
- **Android:** `build/DivoraKioskLM-Android.apk` ist eine signierte Debug-Testdatei ausschließlich für Android.
- GitHub: [Builds](https://github.com/HazemZockt/Divora-Kiosk-LM/actions) und [Test-Releases](https://github.com/HazemZockt/Divora-Kiosk-LM/releases). Lokale Exporte liegen im ignorierten `build`-Ordner.

## Vom ersten Verkauf zur Kette

**KIOSK** zeigt Laden, Einnahmen und Ausbau. Kunden kaufen von selbst; „Kunden bedienen“ verkauft zusätzlich vorhandene Ware. **WAREN** bietet sieben Produkte, Kartons zu je zwölf Stück und veränderbare Verkaufspreise. Wasser kommt nach 20 echten Sekunden; andere Lieferungen dauern länger. Neue Produkte benötigen Kiosk-Level und eine Freischaltung. Ist alles leer und kein Karton bezahlbar, hilft eine kostenlose Notfall-Lieferung nach 60 Sekunden.

**STADT** bietet Echo Park, Venice Beach, Downtown LA, Santa Monica, Hollywood und Beverly Hills. Die stilisierte Karte zeigt Pier/Riesenrad, Skyline, Hollywood-Hügel und Observatorium. Neue Filialen kosten Geld, Bauzeit und anschließend stündliche Miete. Sind alle sechs auf Level 10, kannst du einen teureren Franchise-Bezirk beginnen; die alte Kette zahlt dauerhaft Lizenzgebühren. Es gibt keinen vorgesehenen letzten Bezirk. Technische Zahlengrenzen verhindern Überläufe.

**TEAM** bietet Mitarbeiter, Einkaufsmanager, Kasse und Aufträge. Gehälter und Mieten werden nach echten Spielstunden abgerechnet. Manager bestellen bei geöffnetem Laden, ausreichendem Geld und freiem Lagerplatz. Alle geöffneten Filialen verkaufen auch ohne zusätzliches Personal; Mitarbeiter erhöhen das Tempo.

Unter **Sicherheit & Unterwelt** entscheidest du über Alterskontrollen bei Vapes und Snus. Riskante Verkäufe und zwielichtige Lieferungen erhöhen das Polizeirisiko. Kontrollen können hohe Strafen, Schulden, Rufverlust und eine 30-minütige Sperre des 18+-Sortiments auslösen. Sicherheitsausbau schützt vor Ladendiebstahl.

## Juwelen und Wartezeiten

Nur **Juwelen** überspringen Liefer-, Ausbau- und Eröffnungszeiten. Im **SHOP** sind Europreise als Vorschau sichtbar; echte Zahlungen sind vollständig ausgeschaltet. Es gibt keine Werbung und keine Abbuchungen.

Im Shop nach unten wischen, **Hayat** eingeben und einlösen. Danach sind Juwelenpakete kostenlos abrufbar. Der Code ist eine gewünschte Testfunktion im öffentlichen Quellcode, keine sichere Admin-Anmeldung. Vor einer echten Verkaufsversion muss dieser Zugang entfernt und ein geprüftes Kaufverfahren eingerichtet werden.

## Offline, Speichern und Mitteilungen

Verkäufe, Nachschub und laufende Kosten werden für höchstens **acht Stunden Abwesenheit** nachberechnet. Bereits laufende Lieferungen und Ausbauten werden auch bei längerer Abwesenheit fertig. Speichern erfolgt alle 15 Sekunden, nach Entscheidungen und beim Pausieren, mit Prüfsumme, atomarer Ablage und Sicherungskopie. Gültige v2-Spielstände werden übernommen; ihre Originaldatei bleibt erhalten.

Unter **☰ → Fertigmeldungen** aktivierst du lokale iPhone-/iPad-Mitteilungen und erlaubst den iOS-Systemdialog. Sie erinnern an bereits geplante Lieferungen, Ausbauten und Filialeröffnungen sowie nach acht Stunden an das Offline-Limit. Die Offline-Erinnerung wird bei deiner Rückkehr entfernt. Managerbestellungen, die erst während späterer Offline-Nachberechnung entstehen, waren beim Verlassen noch nicht geplant und bekommen keine vorherige Mitteilung. Auf Windows/Android enthält diese Version nur Hinweise im Spiel. Ton und Bewegung sind einstellbar.

## Bedienung und Testgrenzen

Die Oberfläche bleibt hochkant. Kopf und Navigation bleiben fest, der Seiteninhalt lässt sich wischen. Breite Tabletfenster zeigen einen mittigen Telefonbereich. Vorschauen mit 320 × 700, 420 × 900 und 1024 × 768 wurden unter Windows geprüft. Native Touch-Ereignisse und ein Android-36-Emulator prüfen Wischen, Codeeingabe, Käufe, Pause und Neustart. Echte iPhone-/iPad-Bedienung, iPadOS-Fenster und die Zustellung von Mitteilungen sind ohne Apple-Gerät **noch nicht verifiziert**. Details: [TESTBERICHT.md](TESTBERICHT.md).

## Entwicklung

Godot **4.5.1**, aktive Hauptszene `tycoon/idle_main.tscn`. `idle_economy.gd` hält Spielregeln, `idle_save.gd` Speicher/Migration, `idle_game.gd` Lebenszyklus und stabile Controls, `idle_pages.gd` die Seiten. Zeichnungen liegen in `idle_art.gd`, `idle_scene.gd`, `idle_map.gd`. Die iOS-Brücke in `platform/ios/DivoraNotifications.mm` wird durch `scripts/prepare_ios.py` ins Xcode-Projekt integriert. v2-Regeln und Speicherprüfung bleiben für Migration/Regression erhalten; die alte Oberfläche gehört nicht zum Export.

```text
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tycoon/tests/economy_test.gd
godot --headless --path . --script res://tycoon/tests/save_test.gd
godot --headless --path . --script res://tycoon/tests/idle_test.gd
godot --headless --path . --script res://tycoon/tests/idle_ui_test.gd
godot --headless --path . --script res://tycoon/tests/idle_longrun_test.gd
python -m unittest discover -s scripts -p "test_*.py"
```

Die lokale Windows-Testumgebung verwendet `.tools/godot/editor_data` für `APPDATA`/`LOCALAPPDATA` und dessen `temp`-Unterordner für `TEMP`/`TMP`. Exportvorlagen müssen zur Godot-Version passen. Der GitHub-Workflow richtet macOS-Vorlagen selbst ein.

Die App funktioniert ohne Server und ohne neue Laufzeitpakete. Godot und enthaltene Bibliotheken unterliegen ihren jeweiligen Lizenzen. [ARTWORK.md](ARTWORK.md) dokumentiert die eigenen Grafiken. Bilder und Spielelemente aus den Referenzspielen werden nicht ausgeliefert.