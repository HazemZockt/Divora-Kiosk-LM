# Divora Kiosk LM

Spielbarer Hochkant-Prototyp eines Kiosk-Tycoons für Smartphone-Größen. Du beginnst mit **0 €**, einem kostenlosen Straßenkiosk und zwölf Wasserflaschen als Startware. Der Kiosk wird frontal gezeigt; Kunden kaufen automatisch, wenn er geöffnet ist. Die Wirtschaft läuft auch beim Wechsel auf andere Seiten weiter. Spielwerte und Regeln sind fiktiv.

## Ausprobieren

- **Windows:** `build/DivoraKioskLM-Windows.exe` öffnen. Das Fenster kann schmaler oder größer gezogen werden.
- **Android:** `build/DivoraKioskLM-Android.apk` auf einem Android-Gerät installieren. Eine APK lässt sich nicht auf iPhone oder iPad installieren.
- **iPhone/iPad:** Ein GitHub-Workflow baut das Godot-Projekt auf einem GitHub-Mac ohne eigenen Mac. Die dabei erzeugte IPA ist zunächst unsigniert und muss vor der Installation mit deinem Apple-Account auf Windows signiert werden. Siehe [IOS-GITHUB.md](IOS-GITHUB.md).

## Spielen

Im Tab **LADEN** siehst du den frontalen Kiosk, deine Kasse, den Firmenwert und dein nächstes Vermögensziel. Anfangs verkaufen sich die zwölf geschenkten Wasserflaschen von selbst. Mit dem Erlös bestellst du im Tab **WAREN** weitere Kartons zu je zwölf Stück und änderst die Verkaufspreise. Höhere Preise können Kunden abschrecken; verderbliche Waren verfallen nach einigen Spieltagen.

Unter **ORTE** übernimmst du weitere Standorte mit unterschiedlicher Laufkundschaft und Tagesmiete. Unter **TEAM** stellst du Arbeitskräfte ein und zahlst ihre Gehälter; ein anderer Standort verkauft nur mit eigenem Personal weiter. **KASSE** zeigt Einnahmen, Ausgaben und den Vermögensrang. Unter **REGELN** entscheidest du über die Altersprüfung bei Vapes und Snus. Ein riskanter Verkauf an Minderjährige erhöht die Gefahr einer Kontrolle; Strafen, Rufverlust und eine zeitweise Sperre sind möglich. Diese Mechanik ist eine Spielentscheidung und keine Aussage über tatsächliches Recht.

Ein Spieltag dauert ungefähr eine reale Minute. Das Spiel speichert automatisch, beim Verlassen und nach Änderungen. Nach Rückkehr werden höchstens zehn Minuten Abwesenheit nachberechnet.

## Anzeige auf iPad und iPhone

Die Oberfläche ist für Hochkant angelegt. In einem breiteren Fenster bleibt das Spiel als maximal 480 Pixel breite Fläche mittig stehen. Bei schmaleren Fenstern passt es sich der verfügbaren Breite und Höhe an. Eine Vorschau mit 420 × 900 und 320 × 700 Pixeln liegt im `build`-Ordner. Das Verhalten in iPadOS-Fenstern und auf echten Apple-Geräten muss nach Installation der iOS-App getestet werden.

## Entwicklung

Projekt: Godot 4.5.1, `project.godot`. Der aktive Code liegt unter `tycoon/`: `economy.gd` für die Spielregeln, `save.gd` für lokale Spielstände, `kiosk_view.gd` für die frontale Zeichnung und `game.gd` für die Oberfläche. Der alte begehbare Prototyp ist lokal unter `.tools/legacy-first-person/` archiviert und gehört nicht zur aktiven App.

Tests:

```text
godot --headless --path . --script tycoon/tests/economy_test.gd
godot --headless --path . --script tycoon/tests/save_test.gd
godot --headless --path . --quit-after 120
```

Godot und die verwendeten Bibliotheken unterliegen ihren jeweiligen Lizenzen. Kiosk-Grafik und Spielcode sind für dieses Projekt erstellt.
