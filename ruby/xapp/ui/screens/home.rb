module XApp
  module UI
    module Screens
      TOP_TABS = [
        { key: 'foryou',    label: 'おすすめ' },
        { key: 'following', label: 'フォロー中' }
      ].freeze

      FOLLOWING_HANDLES = %w[matzlab reactive_gal].freeze

      HOME_STYLES = UI.stylesheet(
        wrap:       { flex: 1, backgroundColor: COLORS[:background] },
        empty:      { padding: SPACING[:xl], alignItems: 'center' },
        empty_text: { color: COLORS[:textMuted] },
        fab: {
          position: 'absolute', right: SPACING[:lg], bottom: SPACING[:xl],
          width: 56, height: 56, borderRadius: 28,
          backgroundColor: COLORS[:accent],
          alignItems: 'center', justifyContent: 'center',
          shadowColor: '#000', shadowOpacity: 0.3, shadowRadius: 6,
          shadowOffset: { width: 0, height: 2 }, elevation: 4
        },
        banner: {
          flexDirection: 'row', padding: SPACING[:md],
          marginHorizontal: SPACING[:lg], marginTop: SPACING[:md],
          marginBottom: SPACING[:sm], borderRadius: 12,
          backgroundColor: COLORS[:surface],
          borderColor: COLORS[:border], borderWidth: HAIRLINE
        },
        banner_body:  { marginLeft: SPACING[:sm], flex: 1 },
        banner_title: { color: COLORS[:text], fontWeight: '700', marginBottom: 2, fontSize: 13 },
        banner_note:  { color: COLORS[:textSecondary], fontSize: 12, lineHeight: 16 }
      )

      HomeScreen = UI.component 'HomeScreen' do |props|
        on_open_post = props[:on_open_post]
        on_open_user = props[:on_open_user]
        on_sparkle   = props[:on_sparkle]

        active_top,   set_active_top   = use_state('foryou')
        posts,        set_posts        = use_state(-> { XApp::API.timeline })
        compose_open, set_compose_open = use_state(false)
        engine                         = use_constant { XApp::API.engine_info }
        me                             = use_constant { XApp::API.me }
        my_handle                      = me[:handle]

        refresh_posts = -> { set_posts.call(XApp::API.timeline) }

        update_post = use_callback do |next_post|
          set_posts.call(->(current) { current.map { |p| p[:id] == next_post[:id] ? next_post : p } })
        end

        submit_post = lambda do |body|
          XApp::API.build_new_post(body)
          refresh_posts.call
          set_compose_open.call(false)
        end

        delete_post = lambda do |post|
          confirm('ポストを削除しますか？',
                  '削除すると元に戻せません。',
                  ok: '削除する', cancel: 'キャンセル') do
            XApp::API.delete_post(post[:id])
            refresh_posts.call
          end
        end

        visible_posts = if active_top == 'following'
                          posts.select { |p| FOLLOWING_HANDLES.include?(p[:author][:handle]) }
                        else
                          posts
                        end

        present View, style: HOME_STYLES[:wrap], testID: 'home-screen' do
          present Components::TopBar,
                  tabs:          TOP_TABS,
                  active_tab:    active_top,
                  on_change_tab: set_active_top,
                  on_sparkle:    on_sparkle

          banner = node View, style: HOME_STYLES[:banner], testID: 'engine-banner' do
            present Ionicons, name: 'diamond-outline', size: 18, color: COLORS[:accent]
            present View, style: HOME_STYLES[:banner_body] do
              present Text, style: HOME_STYLES[:banner_title] do
                "Engine: #{engine[:engine]} (#{engine[:rubyEngine]})"
              end
              present Text, style: HOME_STYLES[:banner_note] do
                engine[:note]
              end
            end
          end

          present FlatList,
                  testID:              'timeline-list',
                  data:                visible_posts,
                  keyExtractor:        ->(item, _i) { item[:id] },
                  ListHeaderComponent: banner,
                  renderItem:          ->(info) {
                    item = info[:item]
                    present Components::PostCard,
                            post:         item,
                            on_change:    update_post,
                            on_open:      on_open_post,
                            on_delete:    delete_post,
                            on_open_user: on_open_user,
                            is_mine:      item[:author][:handle] == my_handle
                  }

          present Pressable,
                  style:   HOME_STYLES[:fab],
                  testID:  'compose-fab',
                  onPress: -> { set_compose_open.call(true) } do
            present Ionicons, name: 'create-outline', size: 28, color: COLORS[:text]
          end

          present Components::Composer,
                  visible:   compose_open,
                  me:        me,
                  on_cancel: -> { set_compose_open.call(false) },
                  on_submit: submit_post
        end
      end
    end
  end
end
