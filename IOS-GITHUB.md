# Divora Kiosk LM auf iPhone und iPad

Version **0.3.0** wird auf einem macOS-Rechner von GitHub gebaut. Auf dem eigenen Windows-PC wird kein Xcode benötigt. Der Workflow prüft Spielregeln, Touch-Oberfläche, Speichern, acht Stunden Wirtschaft und die Xcode-Vorbereitung. Xcode baut anschließend die App inklusive nativer lokaler Fertigmeldungen.

## Die richtige Datei

Lokal: `build/ios/DivoraKioskLM-unsigned.ipa` im Projektordner. Es ist eine **IPA**, keine ISO und keine Android-APK. Sie enthält ARM64-Code für iPhone und iPad, Version 0.3.0 und Bundle-ID `de.divora.kiosk.lm`.

Unter [GitHub Actions](https://github.com/HazemZockt/Divora-Kiosk-LM/actions) einen grünen Lauf von „Divora iPhone und iPad bauen“ wählen. Sein Artifact **DivoraKioskLM-iPhone-iPad** enthält die IPA. Artifacts werden nach sieben Tagen gelöscht; veröffentlichte Testdateien bleiben unter [Releases](https://github.com/HazemZockt/Divora-Kiosk-LM/releases) erreichbar.

## Von Windows installieren

1. [Sideloadly von der offiziellen Seite](https://sideloadly.io/) installieren und dessen Hinweise zu benötigten Apple-Treibern beachten.
2. iPhone/iPad per USB verbinden, entsperren und dem Computer vertrauen.
3. Sideloadly öffnen, Gerät auswählen und `DivoraKioskLM-unsigned.ipa` hineinziehen.
4. Mit dem eigenen Apple-Account signieren und installieren. Passwort und Bestätigungscodes nur in die Anmeldemaske eingeben.
5. Falls iOS es verlangt, unter „Einstellungen → Allgemein → VPN & Geräteverwaltung“ dem Entwicklerprofil vertrauen und den Entwicklermodus aktivieren.
6. **Divora Kiosk LM** öffnen. Im **SHOP** nach unten wischen, **Hayat** einlösen und kostenlose Test-Juwelen holen.

Die Datei ist unsigniert; bloßes Kopieren auf das Gerät installiert sie nicht. Sideloadly unterstützt laut offizieller Anleitung kostenlose Apple-Accounts. Deren Signierungen gelten üblicherweise sieben Tage und können erneuert werden. Beim Aktualisieren dieselbe Apple-ID und Bundle-ID benutzen und die alte App vorher nicht löschen, um Spielstände zu erhalten.

## Hochkant und iPad-Fenster

Auf iPhone bleibt die App hochkant. Auf iPad sind alle vier Ausrichtungen erlaubt; die Vollbildpflicht ist ausgeschaltet. In breiten Fenstern bleibt der Spielbereich mittig und schmal. Die Xcode-Vorbereitung setzt `UIRequiresFullScreen=false` und die iPad-Ausrichtungen, ohne die iPhone-Ausrichtung zu ändern. Apples Hinweise: [TN3192 zur iPad-Fenstermigration](https://developer.apple.com/documentation/technotes/tn3192-migrating-your-app-from-the-deprecated-uirequiresfullscreen-key).

## Fertigmeldungen testen

**☰ → Fertigmeldungen: AN** aktivieren und den iOS-Systemdialog erlauben. Ware bestellen oder Ausbau starten und die App in den Hintergrund legen. Nach Ablauf sollte eine lokale Mitteilung erscheinen. Überspringen mit Juwelen entfernt die zugehörige geplante Meldung. Bei verweigerter Erlaubnis unter „Einstellungen → Mitteilungen → Divora Kiosk LM“ nachträglich erlauben. Auch das achtstündige Offline-Limit erzeugt bei aktivierten Mitteilungen eine Erinnerung; sie wird beim Zurückkehren entfernt. Kein Server und keine Push-Anmeldung nötig.

**Offen:** GitHub-Kompilierung und Paketstruktur sind geprüft. Signierung, Installation, echte Touch-Bedienung, Bildschirmtastatur, iPad-Fenster und tatsächliche Mitteilungszustellung müssen auf dem eigenen Apple-Gerät getestet werden. Diese Testversion löst keine echten Käufe aus.