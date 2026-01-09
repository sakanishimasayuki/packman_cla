# Pacman風ゲーム（ウィンドウ版 / Ruby + Gosu）

Gosuライブラリを使ったウィンドウ表示のPacman風ゲームです。プレイヤーはWASDまたは矢印キーで移動し、ゴーストを避けながら全てのペレットを食べるとクリアです。

また、本リポジトリには開発時の GitHub Copilot との対話ログを [chatlog.md](chatlog.md) に記録しています。

## 操作方法

- 移動: `W`, `A`, `S`, `D` または矢印キー
- 終了: `Esc` または `Q`

## 使い方（Windows）

### 1. 依存のインストール（Gosu）

```powershell
gem install gosu
```

インストールに失敗する場合は、PowerShellで `ridk install` を実行してMSYS2ツールチェーンを導入した後、再度 `gem install gosu` を試してください。

### 2. プロジェクトのビルドとローカルインストール

```powershell
# プロジェクトルートで実行
gem build rubycla-pacman.gemspec
gem install --local .\rubycla-pacman-*.gem
```

### 3. ゲームの起動（`pacman` コマンド）

```powershell
pacman --map .\config\maps\default.yaml
```

補足:
- 環境変数 `PACMAN_MAP` でもマップを指定できます（省略時は `./config/maps/default.yaml` を優先）。
- 開発中にローカルの `./lib` を常に優先して使いたい場合は、以下のいずれかを使います。

```powershell
# セッション限定の開発モード
$env:PACMAN_DEV = "1"
pacman --map .\config\maps\default.yaml
```

## 相対パスでの実行例

```powershell
# 縦の狭路ステージ
pacman --map .\config\maps\stage_narrow_grid.yaml

# リポジトリ直から起動（開発用途）
ruby exe/pacman --map .\config\maps\default.yaml
```

## マップ設定（YAML）

マップは [config/maps/default.yaml](config/maps/default.yaml) を編集して変更できます。

- フォーマット: `grid` は文字列の配列で、各行は同じ幅に揃えます。
- 文字の意味: `#` = 壁, `.` = ペレット, 空白 = 通路, `P` = プレイヤー初期位置, `G` = ゴースト初期位置。
- 読み込み順: コマンド引数 `--map` > 環境変数 `PACMAN_MAP` > カレントディレクトリの `./config/maps/default.yaml` > gem同梱のデフォルト。

簡単な例:

```yaml
name: MyMap
grid:
  - "########"
  - "#P....G#"
  - "#......#"
  - "########"
```

YAMLが欠落しているか不正な場合、ゲームは内蔵マップジェネレーターにフォールバックします。

### 起動時のマップ選択（相対パス）

```powershell
# プロジェクトルートから
pacman --map ".\config\maps\default.yaml"

# 環境変数で指定
$env:PACMAN_MAP = ".\config\maps\default.yaml"
pacman
```

## 開発者向け（再ビルドなしでローカルコードを反映）

`pacman` 実行時に常にワークスペースのローカルコード（`./lib`）を優先する方法です。

- 方法A: セッション単位

```powershell
$env:PACMAN_DEV = "1"  # ローカル ./lib を優先
pacman --map ".\config\maps\default.yaml"
```

- 方法B: Bundlerでローカルパスを使う

```powershell
bundle config set --local path vendor/bundle
bundle add rubycla-pacman --path .
bundle install
bundle exec pacman
```

- 方法C: リポジトリから直接実行

```powershell
ruby exe/pacman --map ".\config\maps\default.yaml"
```

注記:
- `PACMAN_DEV` の設定、またはリポジトリルートでの実行により、`pacman` コマンドは `./lib` を最優先で読み込みます。
- `PACMAN_MAP` は任意のYAMLファイルを指せます。未指定の場合は `./config/maps/default.yaml` が存在すればそれが使われます。

## 同梱ステージ（狭路）

- [config/maps/stage_narrow_grid.yaml](config/maps/stage_narrow_grid.yaml): 垂直の1マス幅通路に、ところどころ水平接続がある狭路ステージです。

クイック起動:

```powershell
pacman --map ".\config\maps\stage_narrow_grid.yaml"
```
