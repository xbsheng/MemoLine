<picture>
  <img src="../images/line.png" alt="Cuatro notas de papel de colores, sujetas con pinzas de aluminio a un cordel fino, con un botón + y otro para guardar la línea al final.">
</picture>

# MemoLine

Notas tendidas en un cordel bajo la barra de menús del Mac.
Fuera de la vista, al alcance de la mano.

<p>
  <a href="../../README.md">English</a> ·
  <a href="README.zh-Hans.md">简体中文</a> ·
  <a href="README.ja.md">日本語</a> ·
  <a href="README.ko.md">한국어</a> ·
  Español ·
  <a href="README.fr.md">Français</a> ·
  <a href="README.de.md">Deutsch</a> ·
  <a href="README.pt-BR.md">Português (Brasil)</a>
</p>

Deja el puntero en la barra de menús y el cordel baja despacio, con las notas
meciéndose. Aparta el puntero y se recoge. Nada en el escritorio, ninguna
ventana que abrir.

Gratis, con licencia MIT, macOS 13 o posterior. Sin cuenta, sin red, sin permisos.

<br>

## Un gesto para cada cosa

| | |
|:--|:--|
| Dejar el puntero en la barra de menús | El cordel baja en esa pantalla |
| Clic en una nota | Escribir esa nota |
| El botón de copiar de la esquina | Copia el texto; la nota muestra «Copiado» |
| La cruz de la esquina | Quita la nota (la borra) |
| Arrastrar una nota a lo largo del cordel | La reordena y las demás le hacen sitio |
| Arrastrar una nota fuera del cordel | Suelta el texto en otra app; la nota se queda |
| Clic derecho en una nota | Editar, copiar, nueva, color del papel, mover, quitar |
| **＋** al final del cordel | Nota nueva, con el editor abierto |
| **⌃** al final del cordel | Guardar el cordel |
| <kbd>⌃</kbd><kbd>⌥</kbd><kbd>N</kbd> | Nota nueva |
| <kbd>⌃</kbd><kbd>⌥</kbd><kbd>M</kbd> | Mostrar u ocultar el cordel (se cambia en la barra de menús) |
| Deslizar con dos dedos sobre el cordel | Ver más notas cuando no caben todas |
| <kbd>⌘</kbd><kbd>C</kbd> en el editor | Copiar, como en cualquier sitio |

El icono de la barra de menús también tiene: quitarlo todo, qué hace bajar el
cordel, cuántas notas guardar, el tamaño, el atajo, los sonidos y abrir al
iniciar sesión.

<br>

## Escribir

Haz doble clic en una nota y aparece una hoja bajo el cordel, del mismo color que
la nota. Se guarda con cada tecla, así que da igual cómo la cierres. La fila de
puntos de abajo cambia el papel, en la nota y en el editor a la vez.

<img src="../images/editor.png" width="340" alt="El editor: una hoja de color con la nota, cinco colores de papel abajo y el botón Listo.">

<br>

## Instalar

Descarga `MemoLine.app` de la [última versión](../../releases/latest), o
compílalo:

```sh
git clone <this repo>
cd MemoLine
scripts/build-app.sh        # crea build/MemoLine.app, universal
open build/MemoLine.app
```

`swift build && .build/debug/MemoLine` también lo ejecuta, sin el paquete .app.

Puedes comprobarlo sin pantalla y sin tocar las notas que estás usando:

```sh
swift run MemoLine --self-check     # disposición, reordenar, guardado
swift scripts/check-strings.swift   # cada idioma tiene todas las cadenas
```

Para que arranque con el Mac, arrastra la app a Aplicaciones y activa
**Abrir al iniciar sesión** en la barra de menús.

<br>

## Dónde viven las notas

`~/Library/Application Support/MemoLine/memos.json`, JSON normal y corriente.
No sale del Mac: sin cuenta, sin red, sin estadísticas y sin permisos especiales.
La app solo escribe ese archivo.

<br>

## Licencia

MIT, consulta [LICENSE](../../LICENSE).

El gesto del cordel —las capturas tendidas sobre la barra de menús, la cuerda,
las pinzas, el balanceo— es de [Tendedero](https://github.com/alejandrobujan/tendedero),
de Alejandro Buján, y esta app se construyó sobre él, con licencia MIT. Como pide
esa licencia, MemoLine lleva su propio nombre y su propio icono, y no está
vinculada a él.

<sub>Traducción del README en inglés. La estructura del código está en la versión inglesa.</sub>
