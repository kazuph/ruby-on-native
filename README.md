# ruby-opal-native-x-ui-sample

Ruby で書いた **UI ツリー** を **Opal** で JavaScript にコンパイルし、
**React Native (Expo)** の iOS アプリが直接描画する、X.com 風スマホ UI の実験作品。

**データもロジックも UI も、動いているのは全部 Ruby** です。
TypeScript は「`__RN__` グローバルに React / RN のプリミティブを置いて、Opal が焼いた
JS を `require` するだけ」の薄い玄関 (`src/native-bridge.ts`, `App.tsx`) しかありません。
それらを消すと Metro のエントリーが無くなって起動できないので残っているだけで、業務
ロジックや UI 定義は一切入っていません。

<p align="center">
  <img src=".artifacts/Xクローン構築/screenshots/home_after_like.png" width="240"/>
  <img src=".artifacts/Xクローン構築/screenshots/search.png"          width="240"/>
  <img src=".artifacts/Xクローン構築/screenshots/notifications.png"   width="240"/>
  <img src=".artifacts/Xクローン構築/screenshots/messages.png"        width="240"/>
</p>

## Ruby で UI を書く DSL

`zetachang/opal-native` (react-rb ベースの `present(View) do ... end` DSL)
にインスパイアされつつ、モダンな React 19 の **function component + hooks**
に合わせて再実装しました。JSX も ERB も使いません。

```ruby
HomeScreen = XApp::UI.component('HomeScreen') do |_props|
  active_top, set_active_top = XApp::UI.use_state('foryou')
  posts,      set_posts      = XApp::UI.use_state(-> { XApp::API.timeline })
  engine                     = XApp::UI.use_memo { XApp::API.engine_info }

  XApp::UI.present(View, style: HOME_STYLES[:wrap], testID: 'home-screen') do
    XApp::UI.present(XApp::UI::Components::TopBar,
                     tabs: TOP_TABS, activeTab: active_top, onChangeTab: set_active_top)

    XApp::UI.present(FlatList,
                     testID: 'timeline-list',
                     data: posts,
                     keyExtractor: ->(item, _) { item['id'] },
                     renderItem: ->(info) {
                       XApp::UI.present(XApp::UI::Components::PostCard,
                                        post: info[:item], onChange: update_post)
                     })
  end
end
```

背後では `present(type, props, &block)` がスタックベースで子要素を収集して
`React.createElement(type, props, *children)` を呼んでいます。

## ファイル構成

```
ruby/                       # 全てのロジックと UI
  xapp/
    user.rb                 # Ruby の User クラス
    post.rb                 # Ruby の Post クラス
    feed.rb                 # タイムライン / トレンド / 通知 / DM を生成
    formatter.rb            # "12.3K" / "1h" のコンパクト表記
    engagement.rb           # いいね・RT・ブックマークのトグル状態遷移
    api.rb                  # Ruby 側に閉じたファサード API
    ui.rb                   # present DSL + hooks + JS⇄Ruby 変換
    ui/
      components/{top_bar,bottom_tabs,post_card}.rb
      screens/{home,search,notifications,messages}.rb
      root.rb               # SafeAreaProvider 配下のルート
      register.rb           # `__RN__.setRoot(Root)` で RN 側へ手渡す
  main.rb                   # 上記を require するだけ

src/
  native-bridge.ts          # React / RN / Expo を __RN__ に出すだけの薄い玄関
  ruby-generated/xapp.js    # `npm run build:ruby` の成果物 (git管理外)

App.tsx                     # `return <RubyRoot />` 一行だけ
index.ts                    # Expo の registerRootComponent
.maestro/smoke.yaml         # E2E
```

## 起動

```
npm install
npm run ios      # preios フックで Ruby→Opal を自動ビルド
```

Ruby を変更したら `npm run build:ruby` → iOS シミュレータで Expo Go を再起動。

## ビルドパイプライン

```
opal --no-exit --no-source-map -I ruby -c ruby/main.rb -o src/ruby-generated/xapp.js
```

Opal ランタイム + アプリ全ソースで 約 870KB。Metro がそのまま iOS バイナリに
同梱します。

## Ruby ⇄ JS の橋渡し (`ruby/xapp/ui.rb`)

| 課題 | ui.rb でやっていること |
|------|------------------------|
| React.createElement を Ruby から呼ぶ | `present / el / node` DSL + 子要素スタック |
| hooks を Ruby から使う | `use_state` / `use_memo` / `use_callback` / `use_safe_area_insets` |
| JS→Ruby Hash 再変換 (props, callback 引数) | `__walk_js_to_rb__`、plain Object のみ Map 化 |
| Ruby→JS 変換 (React 側に渡す) | `__deep_to_native__`、Proc は `wrap_proc` |
| Opal の `$def` が自己再帰しない件 | 変換系は module 自体に JS メソッドを生やして回避 |
| `%x{}` 内のバッククォート変数解決 | 全て `#{var}` で明示的に interpolate |

## Maestro E2E

```
maestro test .maestro/smoke.yaml
```

- 上部の「おすすめ」「フォロー中」表示
- エンジンバナー (`Engine: Opal (opal)`)
- 1 ポスト目のいいねタップ → Ruby の `Engagement.toggle_like` が発火
- 4 タブ (ホーム/検索/通知/メッセージ) をすべて巡回
- 各画面を PNG 保存 → `.artifacts/Xクローン構築/screenshots/`

## 既知事項

- アバター / 投稿画像は picsum.photos からランダム取得。最初の 1 回だけ
  シミュレータで数秒グレー → 読み込み待ち。
- Opal 1.8 は `Integer / Integer` が JS `Number` を返すので、
  `Formatter#relative_time` では明示的に `.to_i` をかけて整数化しています。
- Opal は Object.prototype に `$$class` を生やすので、ruby-hash 判別に
  `instanceof Map` と prototype 比較の両方を使っています。
- `backtick_javascript: true` マジックコメントを UI 系ファイルに付けて、
  Opal 2.0 対応の移行警告を抑制しています。
