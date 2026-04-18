# Maestro regression suite

Maestro スクリプトを書き捨てにせず、**機能ごとの回帰テスト** として成長させる
ための骨格です。他の人が追加するときの目印になるよう、以下の規約に揃えて
ください。

```
.maestro/
├── config.yaml                              # 全 flow 共通の appId など
├── README.md                                # このファイル
└── flows/
    ├── 01_home_render.yaml                  # 起動直後のRubyレンダリング
    ├── 02_post_actions.yaml                 # いいね/RT トグル
    ├── 03_tab_navigation.yaml               # 4タブ切替
    ├── 04_compose_and_persist.yaml          # コンポーザ → タイムライン挿入
    ├── 05_sqlite_persistence.yaml           # 再起動跨ぎの SQLite 永続化
    ├── 06_post_detail_and_comment.yaml      # 詳細画面 + コメント投稿
    ├── 07_search.yaml                       # 検索 + 空結果 + クリア
    ├── 08_delete_own_post.yaml              # 自分のポスト削除
    ├── 09_back_handler.yaml                 # nav.back 多段ポップ
    ├── 10_profile_from_post.yaml            # プロフィール遷移
    └── 11_sparkles_settings.yaml            # 設定シート + 全削除
```

## 命名規則

- ファイル名は `NN_<feature>.yaml`。`NN` は他の flow との実行順・依存順が出る
  よう昇順で並べる。
- flow 冒頭コメントに「Regression coverage:」ブロックを書く — どの契約を
  守っているか一目で分かるようにする。
- testID は Ruby 側 (`testID: 'post-p1-like'` など) で付与し、Maestro からは
  `id:` で刺す。表示テキストだけに依存すると文言変更で壊れる。

## 実行

単体で流す:
```bash
maestro test .maestro/flows/04_compose_and_persist.yaml
```

スイート全部:
```bash
maestro test .maestro/flows/
```

スクショは実行時の CWD に落ちる（Maestro の仕様）。CI では撮った後に
`.artifacts/<feature>/screenshots/` に移動する。

## タグ

`tags: [...]` を flow メタデータに書いておくと、`--include-tags smoke`
などで部分走行できる。現状のタグ：

- `smoke` — 起動後の最初の赤信号を拾う最小セット
- `home` / `navigation` / `engagement` / `compose` — 機能別
- `sqlite` — Ruby `XApp::Store` (SQLite) を経由する挙動

## 新 flow を追加するときのチェックリスト

1. 何の「契約」を守るテストか、冒頭コメントに書く。
2. できるだけ `id:` セレクタを使う。テキストは言語バリアントで壊れやすい。
3. `takeScreenshot` を要所に入れる（レビュー時の証跡になる）。
4. 状態変化を検証するときは、before/after を両方 assert する。
5. 既存 flow とテスト対象を重ねない（重複はメンテ負債になる）。
