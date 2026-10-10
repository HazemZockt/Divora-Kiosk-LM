# Divora Kiosk LM — Teststand 10.10.2026

## Geprüft

- Wirtschaft: Start bei 0 €, kostenloser Anfangsbestand, Verkäufe und Bestand, Großhandelseinkauf, Preise, Standortübernahme, Gehälter, Miete, Strom, Steuerrücklage, Altersprüfung, riskante Verkäufe, Polizeistrafe und Sperre, mehrere nachberechnete Spieltage.
- Spielstand: Schreiben und Laden, Prüfsumme, Sicherungskopie, ungültiges Schema, Uhrzeit und Fortschritt während Abwesenheit.
- Laufzeit: Godot-Szene startet ohne Skriptfehler; Hochkant-Vorschauen mit 420 × 900 und 320 × 700 Pixeln wurden visuell geprüft.
- Export: Windows-Datei und signierte Android-Debug-APK (Version 0.2.0) erfolgreich gebaut. Die APK wurde im Android-36-Emulator installiert und gestartet. Die Hochkantansicht, Tabwechsel und ein Wareneinkauf per simuliertem Touch wurden überprüft.

Die automatischen Protokolle und Vorschaubilder liegen im `build`-Ordner.

## Noch offen

Das Spiel ist ein früher Tycoon-Prototyp, kein fertiges großes Wirtschaftsspiel. Balancing und Langzeitsitzungen sind noch offen. Touch-Bedienung und Leistung auf echten Android-Geräten sind nicht verifiziert. Für iPhone und iPad fehlen ein iOS-Build, Apple-Signierung und echte Tests, besonders für iPadOS-Fenstergrößen.
