<picture>
  <img src="../images/line.png" alt="Quatre notes en papier coloré, retenues par des pinces en aluminium sur une fine corde, avec un bouton + et un bouton pour ranger la ligne au bout.">
</picture>

# MemoLine

Des notes étendues sur une corde à linge sous la barre de menus du Mac.
Hors de la vue, à portée de main.

<p>
  <a href="../../README.md">English</a> ·
  <a href="README.zh-Hans.md">简体中文</a> ·
  <a href="README.ja.md">日本語</a> ·
  <a href="README.ko.md">한국어</a> ·
  <a href="README.es.md">Español</a> ·
  Français ·
  <a href="README.de.md">Deutsch</a> ·
  <a href="README.pt-BR.md">Português (Brasil)</a>
</p>

Posez le pointeur dans la barre de menus : la corde descend doucement, les notes
se balancent. Éloignez le pointeur, elle se range. Rien sur le bureau, aucune
fenêtre à ouvrir.

Gratuit, sous licence MIT, macOS 13 ou plus. Sans compte, sans réseau, sans
autorisation.

<br>

## Un geste, une action

| | |
|:--|:--|
| Pointeur posé dans la barre de menus | La corde descend sur cet écran |
| Clic sur une note | Écrire cette note |
| Le bouton copier dans le coin | Copie le texte ; la note affiche « Copié » |
| La croix dans le coin | Décroche la note (la supprime) |
| Glisser une note le long de la corde | La réordonne, les autres se poussent |
| Glisser une note hors de la corde | Dépose le texte dans une autre app ; la note reste |
| Clic droit sur une note | Modifier, copier, nouvelle, couleur du papier, déplacer, décrocher |
| **＋** au bout de la corde | Nouvelle note, éditeur ouvert |
| **⌃** au bout de la corde | Ranger la corde |
| <kbd>⌃</kbd><kbd>⌥</kbd><kbd>N</kbd> | Nouvelle note |
| <kbd>⌃</kbd><kbd>⌥</kbd><kbd>M</kbd> | Afficher ou ranger la corde (modifiable dans la barre de menus) |
| Balayage à deux doigts le long de la corde | Faire défiler quand il y a plus de notes que la place |
| <kbd>⌘</kbd><kbd>C</kbd> dans l'éditeur | Copier, comme partout ailleurs |

L'icône de la barre de menus contient aussi : tout décrocher, ce qui fait
descendre la corde, combien de notes garder, la taille, le raccourci, les sons et
l'ouverture à la connexion.

<br>

## Écrire

Double-cliquez sur une note : une feuille apparaît sous la corde, de la même
couleur que la note. Tout est enregistré à chaque touche, donc peu importe comment
vous fermez. La rangée de pastilles en bas change le papier, sur la note et dans
l'éditeur à la fois.

<img src="../images/editor.png" width="340" alt="L'éditeur : une feuille colorée avec la note, cinq couleurs de papier en bas et le bouton OK.">

<br>

## Installer

Téléchargez `MemoLine.zip` depuis la [dernière version](../../releases/latest), décompressez-le et glissez **MemoLine.app** dans Applications.

L'app est signée ad hoc, sans Developer ID Apple : au premier lancement, macOS dira qu'il ne peut pas vérifier le développeur. Laissez passer une fois :

- **macOS 15 ou plus** — **Réglages du système › Confidentialité et sécurité**, descendez à Sécurité et cliquez **Ouvrir quand même** à côté de MemoLine.
- **Plus ancien** — clic droit sur l'app, puis **Ouvrir**.
- **Sans cliquer** — `xattr -dr com.apple.quarantine /Applications/MemoLine.app`

Ensuite elle s'ouvre comme n'importe quelle app. Elle ne demande aucune autorisation : ni enregistrement d'écran, ni accessibilité, ni réseau.

### Ou compilez-la

macOS 13 ou plus et une toolchain Swift. Xcode est optionnel.

```sh
git clone https://github.com/xbsheng/MemoLine.git
cd MemoLine
scripts/build-app.sh        # produit build/MemoLine.app, universel
open build/MemoLine.app
```

`swift build && .build/debug/MemoLine` le lance aussi, sans le paquet .app.

Vous pouvez le vérifier sans écran, et sans toucher aux notes que vous utilisez :

```sh
swift run MemoLine --self-check     # disposition, réordonnancement, stockage
swift scripts/check-strings.swift   # chaque langue a toutes ses chaînes
```

Pour qu'il démarre avec le Mac, glissez l'app dans Applications et activez
**Ouvrir à la connexion** dans la barre de menus.

<br>

## Où vivent les notes

`~/Library/Application Support/MemoLine/memos.json`, du JSON tout simple. Rien ne
quitte le Mac : pas de compte, pas de réseau, pas de statistiques, aucune
autorisation particulière. L'app n'écrit que ce fichier.

<br>

## Licence

MIT, voir [LICENSE](../../LICENSE).

Le geste de la corde — les captures étendues au-dessus de la barre de menus, la
corde, les pinces, le balancement — vient de
[Tendedero](https://github.com/alejandrobujan/tendedero) d'Alejandro Buján, sous
licence MIT, et cette app a été construite par-dessus. Comme cette licence le
demande, MemoLine porte son propre nom et sa propre icône, et n'y est pas
rattachée.

<sub>Traduction du README anglais. La structure du code se trouve dans la version anglaise.</sub>
