# Divora Kiosk LM - Testbericht 13.10.2026

Version **0.3.0**, aktiver Spielcode **29f1cb0**. Die Überarbeitung ersetzt den bisherigen beschleunigten Simulator durch einen Idle-Tycoon mit echten Liefer-/Bauzeiten, Juwelen-Testshop, LA-Karte, Offline-Wirtschaft und stabilen Controls.

## Automatische Prüfungen

| Prüfung | Ergebnis |
|---|---|
| Bestehende v2-Wirtschaft | 34 Checks bestanden |
| Bestehendes Speichern/Uhrzeit | 10 Checks bestanden |
| Neue Idle-Wirtschaft und Migration | 48 Checks bestanden |
| UI: native Touch-Events, Fokus, Scrollposition, große Guthaben, neun Seiten, Mitteilungsplan inklusive Offline-Limit | 27 Checks bestanden |
| Native Xcode-Vorbereitung | 2 Python-Tests bestanden |
| Acht Stunden, sechs Filialen, Level 20, Manager, Personal und sieben Produkte | 979.928 Verkäufe; Mieten/Löhne abgerechnet; Speicherzustand gültig |

Der Acht-Stunden-Stresstest brauchte lokal rund 6,3 Sekunden und auf GitHub macOS 12,4 Sekunden. Das ist eine beschleunigte Simulation, kein achtstündiger physischer Gerätetest. Der Aufwand ist auf acht Stunden begrenzt; Meldungen und Buchungen besitzen feste Obergrenzen. Geschwindigkeit auf einem echten iPhone ist noch unbekannt.

Neue Regeln wurden zuerst mit fehlschlagenden Tests abgesichert. Die spätere Prüfung fand einen Lagerfehler: Ein zwielichtiger Lieferant konnte bezahlten Lieferungen Lagerraum wegnehmen. Reservierungen werden jetzt berücksichtigt; beide Regressionstests bestehen. Bruchzahlen bei Personal, Bezirken und Liefermengen werden abgewiesen. Ein absichtlich umgedrehter Juwelen-Check löste den erwarteten Testfehler aus; der richtige Check wurde wiederhergestellt und die vollständige Suite lief danach grün.

## Bedienung im Android-36-Emulator

- APK installiert und gestartet; alter v2-Spielstand übernommen.
- Mehrfach im Shop und Warenlager über Inhalte und Knöpfe gewischt; tiefere Bereiche bleiben erreichbar.
- Codefeld mit „Hayat“ gefüllt und per Eingabetaste eingelöst; Text/Fokus bleiben bei Zahlenupdates erhalten.
- Kostenloses 100-Juwelenpaket geholt. Anschließendes Wischen über dem aktiven 550er-Paket erhöhte den Stand nicht versehentlich.
- Wasser bestellt: $29,60 → $23,00, bezahlter Timer im gespeicherten Zustand vorhanden.
- App pausiert und später fortgesetzt: Lieferung abgeschlossen und zwölf Wasser verkauft, $43,40 und 36 Verkäufe. Kein Rest-Timer.
- Vollständiger App-Neustart: $43,40, 100 Juwelen und Testzugang erhalten.
- Abschließenden APK-Export erneut installiert; Daten bleiben erhalten. Keine GDScript-Laufzeitfehler. Der Emulator meldete beim Start einen neu kompilierten Shader-Cache.

Die physische Bildschirmtastatur auf iOS wurde nicht geprüft; der Emulator nutzte Eingabeereignisse. Automatische UI-Tests injizieren zusätzlich native Finger-Drag-Ereignisse. Sie prüfen, dass Ticks weder Touch-Ziele zerstören noch Scrolloffset oder Eingabefokus verlieren.

## Darstellung und Exporte

Native Windows-Vorschauen mit 320 × 700, 420 × 900 und 1024 × 768 visuell geprüft. Kopf/Navigation bleiben frei, der breite Fensterinhalt ist zentriert. Windows-Release-EXE (eingebettetes Spielpaket) exportiert und gestartet, Android-Debug-APK exportiert und verifiziert. Keine zusätzlichen Laufzeitpakete erforderlich.

[iOS-Build 38381641562](https://github.com/HazemZockt/Divora-Kiosk-LM/actions/runs/38381641562) erfolgreich; alle obigen Tests liefen auch auf macOS. Xcode kompilierte `divora_notifications.mm` als ARM64 Objective-C++ und meldete `BUILD SUCCEEDED`.

Heruntergeladene IPA geprüft: `de.divora.kiosk.lm`, Anzeigename Divora Kiosk LM, Version 0.3.0 / Build 3, mindestens iOS 15, ARM64, Gerätefamilien iPhone+iPad. iPhone hochkant, iPad alle vier Ausrichtungen, `UIRequiresFullScreen=false`. Native Klasse `DivoraNotifications`, `UNUserNotificationCenter` und Plan-Dateiname sind im Programm vorhanden. Keine Signatur und kein Provisioning-Profil.

IPA SHA-256: `89b36ede0d6745151d2c631b7979d89a23efe993fb2a76d9be12049611629b22`.

Builds, Screenshots, Logs und die maschinenlesbare Paketprüfung liegen im lokalen `build`-Ordner. Das öffentliche Repository enthält keine Test-Spielstände, Nutzerscreenshots oder Apple-Zugangsdaten.

## Codeprüfung

Korrektheit: Timer, Reservierungen, Speichervalidierung, Wiederanlauf und deaktivierte Zahlungen geprüft. Lesbarkeit/Architektur: Wirtschaft, Ablage, Lebenszyklus, Seiten, Zeichnungen und native Brücke sind getrennt; alte Regeln bleiben nur für Übernahme/Regression. Sicherheit: begrenzte und validierte JSON-Dateien, keine echten Zahlungen/Server/Secrets; Hayat bleibt bewusst öffentliche Testfreigabe. Leistung: bestehende Controls werden aktualisiert, keine komplette Seite pro Tick neu aufgebaut; Simulation und Listen bleiben begrenzt. Keine neuen Laufzeit-Abhängigkeiten. Export schließt inaktive Oberfläche, Testskripte und ungenutzten Erstentwurf aus.

## Noch offen

Echte iPhone-/iPad-Signierung und Installation, Touch/Softkeyboard, Safe Areas, Fenstergrößen unter iPadOS und die tatsächliche Zustellung/Erlaubnisabfrage lokaler Mitteilungen. Balancing über lange reale Spielsitzungen und Leistung/Akkulaufzeit auf Geräten sind nicht bestätigt. Dieses Ergebnis ist eine spielbare Testversion, kein veröffentlichungsfertiges Echtgeldprodukt und keine begehbare 3D-Stadt.