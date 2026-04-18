# ruby-on-native

> **Write your React Native UI 100% in Ruby.**
> Opal が Ruby ソースを JavaScript にコンパイルし、React Native (Expo) が
> そのまま iOS / Android でレンダリング。投稿は SQLite に永続化。

<p align="center">
  <img src=".artifacts/Xクローン構築/screenshots/home_initial.png"         width="220"/>
  <img src=".artifacts/Xクローン構築/screenshots/compose_open.png"         width="220"/>
  <img src=".artifacts/Xクローン構築/screenshots/nav_search.png"           width="220"/>
  <img src=".artifacts/Xクローン構築/screenshots/sqlite_after_restart.png" width="220"/>
</p>

## こころざし

- **Ruby の書き心地のまま** React Native アプリが書けること
- **JSX でも ERB でもない**、純粋な Ruby のメソッド DSL
  (`present(View) do ... end` — zetachang/opal-native 方式の現代版)
- React Native の作法は内部で粛々と守る。**Ruby 側に摩擦を露出させない**
- リグレッションは Maestro で **資産として** 育てる

## サンプルアプリ

X.com のスマホ UI を模した SNS クローン。

- ホームタイムライン / 検索 / 通知 / DM の 4 タブ
- ポストカード: アバター + 認証バッジ + 本文 + 画像グリッド (1 / 2 / 3 / 4 枚)
- いいね / リポスト / ブックマークのトグル
- FAB → コンポーザ → 投稿 → SQLite に永続化 (再起動しても残る)
- Ruby の `Formatter.relative_time` が "1s" / "12m" / "3h" を計算
- `Formatter.compact_count` が "12.3K" / "1.2M" を生成

## Ruby コードのフィーリング

```ruby
module XApp
  module UI
    module Screens
      HOME_STYLES = UI.stylesheet(
        wrap: { flex: 1, backgroundColor: COLORS[:background] },
        fab:  { position: 'absolute', right: SPACING[:lg], bottom: SPACING[:xl] }
      )

      HomeScreen = UI.component 'HomeScreen' do |_props|
        posts,        set_posts        = use_state(-> { XApp::API.timeline })
        compose_open, set_compose_open = use_state(false)

        submit_post = ->(body) {
          set_posts.call(->(current) { [XApp::API.build_new_post(body)] + current })
          set_compose_open.call(false)
        }

        present View, style: HOME_STYLES[:wrap], testID: 'home-screen' do
          present FlatList,
                  data:         posts,
                  keyExtractor: ->(item, _i) { item[:id] },
                  renderItem:   ->(info) {
                    present Components::PostCard,
                            post:      info[:item],
                            on_change: set_posts
                  }

          present Pressable,
                  style:   HOME_STYLES[:fab],
                  testID:  'compose-fab',
                  onPress: -> { set_compose_open.call(true) } do
            present Ionicons, name: 'create-outline', size: 28, color: COLORS[:text]
          end

          present Components::Composer,
                  visible:   compose_open,
                  on_cancel: -> { set_compose_open.call(false) },
                  on_submit: submit_post
        end
      end
    end
  end
end
```

`XApp::UI.` プレフィックスも `Native()` ラップも `.to_n` も書かなくて OK。
DSL 内部で hooks / `instance_exec` / props の symbol キー変換を全部
処理しています。

## ファイル構成

```
ruby/
  main.rb                       # エントリ (require チェーン)
  xapp/
    user.rb  post.rb            # Ruby モデル
    feed.rb  formatter.rb       # シードデータ + 文字列ヘルパ
    engagement.rb               # いいね/RT/ブックマーク状態遷移
    db.rb                       # expo-sqlite 薄ラッパー (XApp::DB)
    store.rb                    # XApp::Store (ユーザー投稿の永続化)
    api.rb                      # UI 層が叩くファサード
    ui.rb                       # present DSL / hooks / Ruby↔JS 変換
    ui/
      components/{top_bar,bottom_tabs,post_card,composer}.rb
      screens/{home,search,notifications,messages}.rb
      root.rb                   # SafeAreaProvider → RootShell
      register.rb               # __RN__.setRoot(Root)

src/
  native-bridge.ts              # React / RN / Expo / SQLite を __RN__ に橋渡し
  ruby-generated/xapp.js        # Opal の成果物 (git管理外)

App.tsx                         # RubyRoot を return するだけ
index.ts                        # Expo registerRootComponent

.maestro/
  config.yaml  README.md
  flows/                        # 5 本の機能別リグレッション

.artifacts/                     # スクショ + レポート (git管理外)
```

## 起動

```bash
npm install
npm run ios        # Expo Go + iOS シミュレータ (preios フックで Opal 再ビルド)
npm start          # 手動選択 (i = iOS, a = Android, w = Web)
```

### Android APK (実機配布)

```bash
npm run build:android:apk
# → android/app/build/outputs/apk/release/app-release.apk が生成される
```

生成された APK は debug keystore で v2 署名済。端末側で「提供元不明」を許可して
`adb install` または直接インストールできます。

## テスト (Maestro)

```bash
npm run maestro:smoke
# → maestro test .maestro/flows/ のショートカット
```

5 本のフロー:

| #   | Flow                            | 何を守るか                             |
|-----|---------------------------------|----------------------------------------|
| 01  | `01_home_render.yaml`           | 起動直後の Ruby レンダリング           |
| 02  | `02_post_actions.yaml`          | いいね / RT トグル (Engagement 往復)   |
| 03  | `03_tab_navigation.yaml`        | 4 タブ切替 + 各画面の存在              |
| 04  | `04_compose_and_persist.yaml`   | コンポーザ → タイムライン先頭に挿入    |
| 05  | `05_sqlite_persistence.yaml`    | 再起動を跨いだ SQLite 永続化           |

Flow 追加時の規約は `.maestro/README.md` を参照。

## Ruby ⇄ JS ブリッジ (`ruby/xapp/ui.rb`)

| 課題                                  | 解決策                                                   |
|---------------------------------------|----------------------------------------------------------|
| React.createElement を Ruby から呼ぶ  | スタックベースの `present` / `node` DSL                  |
| hooks を Ruby から呼ぶ                | `use_state` / `use_memo(deps)` / `use_callback(deps)`     |
| 「一度だけ計算」の意図を明示する      | `use_constant { ... }` (空 deps の React.useMemo)         |
| JS props → Ruby Hash                  | `__walk_js_to_rb__` — Map 化 (symbol キー)               |
| Ruby Hash → JS object                 | `__deep_to_native__` — Map / Array / Proc / Symbol を変換 |
| component 本体を自然な Ruby にする    | `_call_component` が `instance_exec` で UI コンテキスト化 |
| Ruby nil を React に返さない          | `_call_component` が nil を JS null にコエルス            |
| StyleSheet の numeric ID を使う       | `UI.stylesheet` が RN.StyleSheet.create を経由            |

## 制限・今後

- 現状 UI テストは Maestro 経由の E2E のみ。component 単体テスト用の
  Opal minitest ランナーは未整備。
- Opal ランタイム + アプリ全コードで約 870KB。
- Android APK のサイズ (約 64MB) は ABI 4 種同梱の標準サイズ。
  arm64 だけにフィルタすれば半減できる。

## ライセンス

MIT. 愉しみで作った実験です。
