module XApp
  module UI
    ROOT_STYLES = UI.stylesheet(
      root:  { flex: 1, backgroundColor: COLORS[:background] },
      stage: { flex: 1 }
    )

    RootShell = UI.component 'RootShell' do |_props|
      insets       = use_safe_area_insets
      nav          = Nav.use
      settings_open,  set_settings_open  = use_state(false)
      feed_version,   set_feed_version   = use_state(0)   # bump to remount feed
      top_padding  = insets[:top]    || 0
      bottom_inset = insets[:bottom] || 0

      bump_feed = -> { set_feed_version.call(->(n) { n + 1 }) }

      open_post = ->(post)   { nav.navigate(:post_detail, post_id: post[:id]) }
      open_user = ->(handle) { nav.navigate(:profile, handle: handle) }
      back      = -> { nav.back }
      set_tab   = ->(t) { nav.set_tab(t) }

      # Hardware back (Android): pop the Nav stack when inside detail /
      # profile / settings. When the stack is bare we let the OS bubble
      # through to its default "exit the app" handling.
      use_back_handler(nav.depth, settings_open) do
        if settings_open
          set_settings_open.call(false)
          true
        elsif nav.depth > 1
          nav.back
          true
        else
          false
        end
      end

      handle_refresh = lambda do
        set_settings_open.call(false)
        bump_feed.call
      end

      handle_reset = lambda do
        confirm('全ポストを削除しますか？',
                '自分で書いたポストとそれに付いたコメントをすべて消します。',
                ok: '削除する', cancel: 'キャンセル') do
          XApp::API.reset_my_data
          set_settings_open.call(false)
          bump_feed.call
        end
      end

      present View,
              testID: 'app-root',
              style:  [ROOT_STYLES[:root], { paddingTop: top_padding }] do
        present StatusBar, style: 'light'

        present View, style: ROOT_STYLES[:stage] do
          case nav.top[:kind]
          when :post_detail
            present Screens::PostDetailScreen,
                    post_id:      nav.top[:post_id],
                    on_back:      back,
                    on_open_user: open_user
          when :profile
            present Screens::ProfileScreen,
                    handle:       nav.top[:handle],
                    on_back:      back,
                    on_open_post: open_post
          else
            case nav.current_tab
            when 'home'
              present Screens::HomeScreen,
                      key:          "home-#{feed_version}",
                      on_open_post: open_post,
                      on_open_user: open_user,
                      on_sparkle:   -> { set_settings_open.call(true) }
            when 'search'
              present Screens::SearchScreen,
                      on_open_post: open_post,
                      on_open_user: open_user
            when 'notifications'
              present Screens::NotificationsScreen
            when 'messages'
              present Screens::MessagesScreen
            end
          end
        end

        # Hide the bottom tabs while drilled into a detail / profile view
        # so the "Back" nav is the only way out (matches X.com iOS).
        if nav.depth == 1
          present Components::BottomTabs,
                  active:       nav.current_tab,
                  on_change:    set_tab,
                  bottom_inset: bottom_inset
        end

        present Components::SettingsSheet,
                visible:    settings_open,
                on_close:   -> { set_settings_open.call(false) },
                on_refresh: handle_refresh,
                on_reset:   handle_reset
      end
    end

    Root = UI.component 'Root' do |_props|
      present SafeAreaProvider do
        present RootShell
      end
    end
  end
end
