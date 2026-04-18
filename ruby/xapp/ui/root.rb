module XApp
  module UI
    ROOT_STYLES = UI.stylesheet(
      root:  { flex: 1, backgroundColor: COLORS[:background] },
      stage: { flex: 1 }
    )

    RootShell = UI.component 'RootShell' do |_props|
      insets       = use_safe_area_insets
      nav          = Nav.use
      top_padding  = insets[:top]    || 0
      bottom_inset = insets[:bottom] || 0

      open_post = ->(post) { nav.navigate(:post_detail, post_id: post[:id]) }
      back      = -> { nav.back }
      set_tab   = ->(t) { nav.set_tab(t) }

      present View,
              testID: 'app-root',
              style:  [ROOT_STYLES[:root], { paddingTop: top_padding }] do
        present StatusBar, style: 'light'

        present View, style: ROOT_STYLES[:stage] do
          if nav.in_detail?
            present Screens::PostDetailScreen,
                    post_id: nav.top[:post_id],
                    on_back: back
          else
            case nav.current_tab
            when 'home'
              present Screens::HomeScreen, on_open_post: open_post
            when 'search'
              present Screens::SearchScreen, on_open_post: open_post
            when 'notifications'
              present Screens::NotificationsScreen
            when 'messages'
              present Screens::MessagesScreen
            end
          end
        end

        # Hide the bottom tabs when drilling into the detail stack so the
        # "Back" nav is the only way out (matches X.com iOS behaviour).
        unless nav.in_detail?
          present Components::BottomTabs,
                  active:       nav.current_tab,
                  on_change:    set_tab,
                  bottom_inset: bottom_inset
        end
      end
    end

    Root = UI.component 'Root' do |_props|
      present SafeAreaProvider do
        present RootShell
      end
    end
  end
end
