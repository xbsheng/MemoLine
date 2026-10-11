<picture>
  <img src="../images/line.png" alt="알루미늄 클립으로 얇은 줄에 걸린 여러 색의 종이 메모. 줄 끝에 + 와 숨기기 버튼.">
</picture>

# MemoLine

macOS 메뉴 막대 아래 빨랫줄에 메모를 걸어 둡니다.
보이지 않지만, 손은 닿습니다.

<p>
  <a href="../../README.md">English</a> ·
  <a href="README.zh-Hans.md">简体中文</a> ·
  <a href="README.ja.md">日本語</a> ·
  한국어 ·
  <a href="README.es.md">Español</a> ·
  <a href="README.fr.md">Français</a> ·
  <a href="README.de.md">Deutsch</a> ·
  <a href="README.pt-BR.md">Português (Brasil)</a>
</p>

포인터를 메뉴 막대에 잠시 두면 줄이 내려오고 메모가 살랑입니다. 멀어지면 다시 올라갑니다.
바탕 화면에는 아무것도 남지 않고, 열어 둘 창도 없습니다.

무료, MIT 라이선스, macOS 13 이상. 계정도, 네트워크도, 권한 요청도 없습니다.

<br>

## 하나의 동작에 하나의 일

| | |
|:--|:--|
| 포인터를 메뉴 막대에 두기 | 그 화면에서 줄이 내려옵니다 |
| 메모 클릭 | 그 메모를 씁니다 |
| 왼쪽 위 복사 버튼 | 글자를 복사하고 「복사됨」이 잠깐 뜹니다 |
| 오른쪽 위 × | 이 메모를 내립니다(삭제) |
| 줄을 따라 끌기 | 순서를 바꿉니다. 다른 메모가 자리를 비켜 줍니다 |
| 줄 밖으로 끌기 | 글자를 다른 앱으로. 메모는 줄에 남습니다 |
| 메모 오른쪽 클릭 | 편집, 복사, 새 메모, 종이색, 이동, 내리기 |
| 줄 끝의 **＋** | 새 메모, 편집기가 바로 열립니다 |
| 줄 끝의 **⌃** | 줄을 숨깁니다 |
| <kbd>⌃</kbd><kbd>⌥</kbd><kbd>N</kbd> | 새 메모 |
| <kbd>⌃</kbd><kbd>⌥</kbd><kbd>M</kbd> | 줄 보기/숨기기 (메뉴 막대에서 변경 가능) |
| 줄 위에서 두 손가락 스와이프 | 한 화면에 다 안 들어갈 때 넘겨 보기 |
| 편집기에서 <kbd>⌘</kbd><kbd>C</kbd> | 늘 하던 대로 복사 |

메뉴 막대 아이콘에는 모두 내리기, 줄을 내리는 방법, 남길 개수, 크기, 단축키, 소리,
로그인 시 열기가 더 있습니다.

<br>

## 쓰기

메모를 두 번 클릭하면 줄 아래에 같은 색 종이가 나타납니다. 입력하는 대로 저장되므로 어떻게
닫아도 글이 남습니다. 아래쪽 색 점을 누르면 종이가 바뀌고, 카드와 편집기가 함께 바뀝니다.

<img src="../images/editor.png" width="340" alt="편집기: 색 종이에 적은 메모, 아래 다섯 가지 종이색과 완료 버튼.">

<br>

## 설치

[최신 릴리스](../../releases/latest)에서 `MemoLine.zip` 을 받아 풀고 **MemoLine.app** 을 응용 프로그램 폴더로 끌어다 놓으세요.

Apple Developer ID 없이 ad-hoc 서명만 했기 때문에, 처음 한 번은 macOS 가 개발자를 확인할 수 없다고 합니다. 한 번만 허용하면 됩니다:

- **macOS 15 이상**: 시스템 설정 › 개인정보 보호 및 보안 → 보안에서 MemoLine 옆의 **확인 없이 열기**
- **그 이전**: 앱을 오른쪽 클릭하고 **열기**
- **클릭 없이**: `xattr -dr com.apple.quarantine /Applications/MemoLine.app`

그 뒤로는 평범한 앱입니다. 권한은 전혀 요구하지 않습니다: 화면 기록도, 손쉬운 사용도, 네트워크도 없습니다.

### 직접 빌드하기

macOS 13 이상과 Swift 툴체인(Xcode 는 선택).

```sh
git clone https://github.com/xbsheng/MemoLine.git
cd MemoLine
scripts/build-app.sh        # build/MemoLine.app (유니버설) 생성
open build/MemoLine.app
```

`swift build && .build/debug/MemoLine` 로도 실행됩니다.

화면 없이, 쓰고 있는 메모를 건드리지 않고 확인할 수 있습니다:

```sh
swift run MemoLine --self-check     # 배치, 순서 바꾸기, 저장
swift scripts/check-strings.swift   # 모든 언어에 문자열이 다 있는지
```

로그인할 때 켜지게 하려면 앱을 응용 프로그램 폴더로 옮기고 메뉴 막대에서
「로그인 시 열기」를 켜세요.

<br>

## 메모가 저장되는 곳

`~/Library/Application Support/MemoLine/memos.json` — 그냥 JSON 입니다.
Mac 밖으로 나가지 않습니다. 계정, 네트워크, 분석, 특별한 권한 모두 없고 이 파일만 씁니다.

<br>

## 라이선스

MIT, [LICENSE](../../LICENSE) 참고.

줄의 동작 — 메뉴 막대 위 빨랫줄, 클립, 흔들림 — 은 Alejandro Buján 의
[Tendedero](https://github.com/alejandrobujan/tendedero)(MIT) 에서 왔고, 이 앱은 그 위에
만들어졌습니다. 그 라이선스대로 MemoLine 은 자기 이름과 아이콘을 쓰며 Tendedero 와는
관계가 없습니다.

<sub>영어 README 를 옮긴 글입니다. 코드 구조는 영어판을 보세요.</sub>
