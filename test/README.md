# cursorshape Test Suite

Themisテストフレームワークを使用したcursorshapeプラグインのテストスイート。

## テスト実行方法

### 依存関係のインストール

```bash
make test
```

初回実行時に自動的にvim-themisがインストールされます。

### テスト実行

```bash
# Vimでテストを実行
./vim-themis/bin/themis test

# Neovimでテストを実行
THEMIS_VIM=nvim ./vim-themis/bin/themis test
```

## テストファイル構成

### `test/core.vim` (30テスト)
**対象**: `autoload/cursorshape/core.vim`

- Backend選択ロジックのテスト
  - 明示的なbackend指定
  - 自動backend選択（auto）
  - tmux/screen環境での動作
- 形状変換のテスト
  - shape_to_termcap（DECSCUSR形式への変換）
  - shape_to_guicursor（Neovim guicursor形式への変換）
- 情報収集のテスト
  - build_info（設定と環境情報の統合）

### `test/compat.vim` (15テスト)
**対象**: `autoload/cursorshape/compat.vim`

- エディタ検出
  - Neovim判定（is_nvim）
- 機能検出
  - guicursorサポート（has_guicursor）
  - termcapサポート（has_termcap_si）
  - ModeChangedイベントサポート（supports_modechanged）
- 通知システム
  - 各レベル（info/warn/error）での通知機能

### `test/deps_env.vim` (22テスト)
**対象**: `autoload/cursorshape/deps/env.vim`

- 環境検出
  - tmux検出（is_tmux）
  - screen検出（is_screen）
  - ターミナル情報（term, term_program）
- キャッシング機能
  - 環境情報の一貫性
  - 複数回呼び出し時の動作
- キャッシュリセット機能
  - reset_cache()による手動クリア
  - force オプションによる強制更新
  - テストでのキャッシュ制御

### `test/internal_guicursor.vim` (13テスト)
**対象**: `autoload/cursorshape/internal/guicursor.vim`

- カーソル形状の適用
  - 単一/複数モードでの適用
  - &guicursorオプションの変更
- リストア機能
  - 'default'モード（安全なデフォルト）
  - 'startup'モード（元の値への復元）
  - 'none'モード（何もしない）
- 状態管理
  - reset機能
  - 複数回適用時の動作

**注意**: Neovim専用の機能のため、Vimではguicursorサポートがない場合があります。

### `test/internal_termcap.vim` (15テスト)
**対象**: `autoload/cursorshape/internal/termcap.vim`

- termcapオプションの設定
  - t_SI（挿入モード）
  - t_EI（通常モード）
  - t_SR（置換モード）
  - t_te（終了時）
- 重複適用の防止
- 形状変換の検証
- リストアモード
  - 'default'/'startup'/'none'

**注意**: Vim専用の機能のため、Neovimでは自動的にスキップされます。

## テストの特徴

### 環境非依存性
- `-u NONE`オプションで動作
- vimrcに依存しない
- 実機のカーソル形状変化は検証しない（文字列・構造のみ検証）

### エディタ別の動作
- **Vim**: termcap関連テストが実行される
- **Neovim**: guicursor関連テストが実行される
- 環境に応じて自動的にテストがスキップされる

### カバレッジ
- **合計テスト数**: 113
- **core層**: 30テスト
- **compat層**: 15テスト
- **deps/env層**: 22テスト
- **internal/guicursor層**: 13テスト
- **internal/termcap層**: 16テスト
- **integration層**: 7テスト
- **guicursor_merge層**: 10テスト

## 継続的インテグレーション

GitHub ActionsなどのCIで両方のエディタでテストを実行することを推奨：

```yaml
strategy:
  matrix:
    editor: [vim, nvim]
steps:
  - run: make test
  - run: |
      if [ "${{ matrix.editor }}" = "nvim" ]; then
        THEMIS_VIM=nvim ./vim-themis/bin/themis test
      else
        ./vim-themis/bin/themis test
      fi
```

## トラブルシューティング

### テストが失敗する場合

1. **vim-themisが見つからない**
   ```bash
   make clean
   make test
   ```

2. **Neovimでtermcapテストが失敗**
   - 正常な動作です。termcapテストはNeovimでは自動スキップされます。

3. **Vimでguicursorテストが失敗**
   - 一部のVimビルドではguicursorがサポートされていない場合があります。
   - テストは自動的にスキップされます。

## 参考資料

- [vim-themis](https://github.com/thinca/vim-themis)
- [DECSCUSR仕様](https://invisible-island.net/xterm/ctlseqs/ctlseqs.html)
- [Vim guicursor](https://neovim.io/doc/user/options.html#'guicursor')
