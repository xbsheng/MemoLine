<picture>
  <img src="../images/line.png" alt="Quatro recados em papel colorido, presos por prendedores de alumínio num varal fino, com um botão + e outro para guardar o varal na ponta.">
</picture>

# MemoLine

Recados pendurados num varal sob a barra de menus do Mac.
Fora da vista, ao alcance da mão.

<p>
  <a href="../../README.md">English</a> ·
  <a href="README.zh-Hans.md">简体中文</a> ·
  <a href="README.ja.md">日本語</a> ·
  <a href="README.ko.md">한국어</a> ·
  <a href="README.es.md">Español</a> ·
  <a href="README.fr.md">Français</a> ·
  <a href="README.de.md">Deutsch</a> ·
  Português (Brasil)
</p>

Deixe o ponteiro na barra de menus e o varal desce devagar, com os papéis
balançando. Afaste o ponteiro e ele se recolhe. Nada na mesa, nenhuma janela para
abrir.

Grátis, licença MIT, macOS 13 ou mais recente. Sem conta, sem rede, sem permissões.

<br>

## Um gesto para cada coisa

| | |
|:--|:--|
| Ponteiro parado na barra de menus | O varal desce naquela tela |
| Clique num recado | Escrever aquele recado |
| O botão de copiar no canto | Copia o texto; o papel mostra “Copiado” |
| O xis no canto | Tira o recado (apaga) |
| Arrastar um recado ao longo do varal | Muda a ordem, os outros abrem espaço |
| Arrastar um recado para fora do varal | Solta o texto em outro app; o recado fica |
| Clique com o botão direito | Editar, copiar, novo, cor do papel, mover, tirar |
| **＋** na ponta do varal | Recado novo, com o editor aberto |
| **⌃** na ponta do varal | Guardar o varal |
| <kbd>⌃</kbd><kbd>⌥</kbd><kbd>N</kbd> | Recado novo |
| <kbd>⌃</kbd><kbd>⌥</kbd><kbd>M</kbd> | Mostrar ou guardar o varal (dá para mudar na barra de menus) |
| Deslizar com dois dedos sobre o varal | Ver os outros quando não cabem todos |
| <kbd>⌘</kbd><kbd>C</kbd> no editor | Copiar, como em qualquer lugar |

O ícone da barra de menus ainda tem: tirar tudo, o que faz o varal descer, quantos
recados manter, tamanho, atalho, sons e abrir ao iniciar a sessão.

<br>

## Escrever

Dê um clique duplo num recado e uma folha aparece sob o varal, da mesma cor do
papel. Salva a cada tecla, então não importa como você fecha. A fileira de
bolinhas embaixo troca o papel, no recado e no editor ao mesmo tempo.

<img src="../images/editor.png" width="340" alt="O editor: uma folha colorida com o recado, cinco cores de papel embaixo e o botão Concluir.">

<br>

## Instalar

Baixe o `MemoLine.zip` da [última versão](../../releases/latest), descompacte e arraste o **MemoLine.app** para Aplicativos.

O app é assinado ad hoc, sem um Developer ID da Apple, então na primeira vez o macOS vai dizer que não pode verificar o desenvolvedor. Libere uma vez:

- **macOS 15 ou mais recente** — **Ajustes do Sistema › Privacidade e Segurança**, desça até Segurança e clique em **Abrir assim mesmo** ao lado do MemoLine.
- **Anteriores** — clique com o botão direito no app e escolha **Abrir**.
- **Sem cliques** — `xattr -dr com.apple.quarantine /Applications/MemoLine.app`

Depois ele abre como qualquer app. Não pede permissão nenhuma: nem gravação de tela, nem acessibilidade, nem rede.

### Ou compile

macOS 13 ou mais recente e um toolchain Swift. Xcode é opcional.

```sh
git clone https://github.com/xbsheng/MemoLine.git
cd MemoLine
scripts/build-app.sh        # gera build/MemoLine.app, universal
open build/MemoLine.app
```

`swift build && .build/debug/MemoLine` também roda, sem o pacote .app.

Dá para conferir sem tela e sem mexer nos recados que você está usando:

```sh
swift run MemoLine --self-check     # posições, reordenação, arquivo
swift scripts/check-strings.swift   # todo idioma tem todos os textos
```

Para abrir junto com o Mac, arraste o app para Aplicativos e ligue
**Abrir ao iniciar sessão** na barra de menus.

<br>

## Onde ficam os recados

`~/Library/Application Support/MemoLine/memos.json` — JSON simples. Nada sai do
Mac: sem conta, sem rede, sem estatísticas e sem permissões especiais. O app só
escreve esse arquivo.

<br>

## Licença

MIT, veja [LICENSE](../../LICENSE).

O gesto do varal — capturas penduradas acima da barra de menus, a corda, os
prendedores, o balanço — é do [Tendedero](https://github.com/alejandrobujan/tendedero),
de Alejandro Buján, sob licença MIT, e este app foi feito em cima dele. Como essa
licença pede, o MemoLine usa nome e ícone próprios e não tem vínculo com ele.

<sub>Tradução do README em inglês. A estrutura do código está na versão em inglês.</sub>
