# Divora Kiosk LM auf iPhone und iPad testen

Für den iOS-Build wird kein eigener Mac benötigt. Der Workflow `.github/workflows/ios-build.yml` verwendet einen macOS-Rechner von GitHub: Er testet die Spielregeln, exportiert das Godot-Projekt und baut daraus eine **unsignierte** iPhone-/iPad-App. Das Verfahren folgt dem H-Fit-Projekt, nutzt aber Godot statt SwiftPM.

## Build herunterladen

1. Im GitHub-Repository **Actions → Divora iPhone und iPad bauen** öffnen.
2. Einen grünen Lauf auswählen. Unter **Artifacts** das Paket **DivoraKioskLM-iPhone-iPad** herunterladen und entpacken.
3. Darin liegt `DivoraKioskLM-unsigned.ipa`. Eine rote Aktion oder eine fehlende IPA bedeutet, dass kein verlässlich installierbarer Build vorliegt.

## Auf dem eigenen Gerät installieren

Wie bei H-Fit kann die unsignierte IPA auf einem Windows-PC mit [Sideloadly](https://sideloadly.io/) und dem eigenen Apple-Account signiert und auf ein per USB verbundenes iPhone oder iPad installiert werden. Die in Sideloadly genannten Apple-Treiber und Geräteeinstellungen müssen vorhanden sein. Apple-Passwort und Bestätigungscodes gehören nur in die Anmeldemaske, niemals in GitHub oder diesen Chat. Kostenlos signierte Apps müssen üblicherweise nach sieben Tagen erneuert werden; dabei dieselbe Apple-ID und Bundle-ID verwenden und die App vorher nicht löschen, damit lokale Spielstände erhalten bleiben.

Die IPA ist für **iPhone und iPad** konfiguriert. Das schmale iPad-Fenster und die Berührungseingaben lassen sich erst auf einem echten Gerät bestätigen. Die Vorschauen im Projekt zeigen lediglich die dynamische Godot-Oberfläche auf Windows und Android.

**Stand:** Der Workflow ist vorbereitet. Ein grüner GitHub-Lauf und die Installation auf einem Apple-Gerät müssen gesondert bestätigt werden.
