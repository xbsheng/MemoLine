<picture>
  <img src="../images/line.png" alt="Vier Notizzettel aus farbigem Papier, mit Aluminiumklammern an einer dünnen Leine, am Ende ein Plus und ein Wegpacken-Knopf.">
</picture>

# MemoLine

Notizen auf einer Wäscheleine unter der macOS-Menüleiste.
Nicht im Weg, aber in Reichweite.

<p>
  <a href="../../README.md">English</a> ·
  <a href="README.zh-Hans.md">简体中文</a> ·
  <a href="README.ja.md">日本語</a> ·
  <a href="README.ko.md">한국어</a> ·
  <a href="README.es.md">Español</a> ·
  <a href="README.fr.md">Français</a> ·
  Deutsch ·
  <a href="README.pt-BR.md">Português (Brasil)</a>
</p>

Den Zeiger in der Menüleiste ruhen lassen, und die Leine gleitet herunter, die
Zettel schwingen leicht. Weggehen, und sie rollt sich wieder ein. Nichts auf dem
Schreibtisch, kein Fenster zum Öffnen.

Kostenlos, MIT-Lizenz, macOS 13 oder neuer. Kein Konto, kein Netzwerk, keine
Berechtigungen.

<br>

## Eine Geste, eine Sache

| | |
|:--|:--|
| Zeiger in der Menüleiste ruhen lassen | Die Leine kommt auf diesem Bildschirm herunter |
| Klick auf einen Zettel | Diese Notiz schreiben |
| Der Kopier-Knopf in der Ecke | Kopiert den Text, der Zettel zeigt kurz „Kopiert“ |
| Das Kreuz in der Ecke | Nimmt die Notiz ab (löscht sie) |
| Einen Zettel an der Leine entlangziehen | Neue Reihenfolge, die anderen rücken nach |
| Einen Zettel von der Leine ziehen | Text in eine andere App ziehen, die Notiz bleibt |
| Rechtsklick auf einen Zettel | Bearbeiten, kopieren, neu, Papierfarbe, verschieben, abnehmen |
| **＋** am Ende der Leine | Neue Notiz, Editor offen |
| **⌃** am Ende der Leine | Leine wegpacken |
| <kbd>⌃</kbd><kbd>⌥</kbd><kbd>N</kbd> | Neue Notiz |
| <kbd>⌃</kbd><kbd>⌥</kbd><kbd>M</kbd> | Leine zeigen oder wegpacken (in der Menüleiste änderbar) |
| Mit zwei Fingern an der Leine entlangwischen | Durchblättern, wenn mehr Zettel als Platz da sind |
| <kbd>⌘</kbd><kbd>C</kbd> im Editor | Kopieren, wie überall sonst |

Das Symbol in der Menüleiste hat außerdem: alles abnehmen, was die Leine
herunterholt, wie viele Notizen bleiben, Größe, Kurzbefehl, Töne und beim
Anmelden öffnen.

<br>

## Schreiben

Doppelklick auf einen Zettel, und unter der Leine erscheint ein Blatt in derselben
Farbe. Jeder Tastendruck wird gespeichert, egal wie das Fenster geschlossen wird.
Die Punktreihe unten wechselt das Papier, am Zettel und im Editor zugleich.

<img src="../images/editor.png" width="340" alt="Der Editor: ein farbiges Blatt mit der Notiz, fünf Papierfarben unten und ein Fertig-Knopf.">

<br>

## Installieren

`MemoLine.app` aus der [letzten Version](../../releases/latest) laden oder selbst
bauen:

```sh
git clone <this repo>
cd MemoLine
scripts/build-app.sh        # erzeugt build/MemoLine.app, universal
open build/MemoLine.app
```

`swift build && .build/debug/MemoLine` startet es ebenfalls, ohne .app-Hülle.

Prüfen lässt es sich ohne Bildschirm und ohne die Notizen anzufassen, die du
gerade benutzt:

```sh
swift run MemoLine --self-check     # Anordnung, Umsortieren, Speichern
swift scripts/check-strings.swift   # jede Sprache hat alle Texte
```

Zum Mitstarten die App nach Programme ziehen und in der Menüleiste
**Beim Anmelden öffnen** einschalten.

<br>

## Wo die Notizen liegen

`~/Library/Application Support/MemoLine/memos.json` — schlichtes JSON. Nichts
verlässt den Mac: kein Konto, kein Netzwerk, keine Auswertung, keine besonderen
Berechtigungen. Die App schreibt nur diese Datei.

<br>

## Lizenz

MIT, siehe [LICENSE](../../LICENSE).

Die Geste der Leine — Screenshots über der Menüleiste, die Leine, die Klammern,
das Schwingen — stammt von [Tendedero](https://github.com/alejandrobujan/tendedero)
von Alejandro Buján (MIT), und diese App baut darauf auf. Wie diese Lizenz es
verlangt, trägt MemoLine einen eigenen Namen und ein eigenes Symbol und gehört
nicht zu Tendedero.

<sub>Übersetzung der englischen README. Der Code-Aufbau steht in der englischen Fassung.</sub>
