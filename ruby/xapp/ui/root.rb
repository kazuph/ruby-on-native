module XApp
  module UI
    ROOT_STYLES = UI.stylesheet(
      root:  { flex: 1, backgroundColor: COLORS[:background] },
      stage: { flex: 1 }
    )

    RootShell = UI.component 'RootShell' do |_props|
      insets       = use_safe_area_insets
      tab, set_tab = use_state('home')
      top_padding  = insets[:top]    || 0
      bottom_inset = insets[:bottom] || 0

      present View,
              testID: 'app-root',
              style:  [ROOT_STYLES[:root], { paddingTop: top_padding }] do
        present StatusBar, style: 'light'
        present View, style: ROOT_STYLES[:stage] do
          case tab
          when 'home'          then present Screens::HomeScreen
          when 'search'        then present Screens::SearchScreen
          when 'notifications' then present Screens::NotificationsScreen
          when 'messages'      then present Screens::MessagesScreen
          end
        end
        present Components::BottomTabs,
                active:       tab,
                on_change:    set_tab,
                bottom_inset: bottom_inset
      end
    end

    Root = UI.component 'Root' do |_props|
      present SafeAreaProvider do
        present RootShell
      end
    end
  end
end
