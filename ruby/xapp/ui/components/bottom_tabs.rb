module XApp
  module UI
    module Components
      BOTTOM_TAB_DEFS = [
        { key: 'home',          active: 'home',          inactive: 'home-outline' },
        { key: 'search',        active: 'search',        inactive: 'search-outline' },
        { key: 'notifications', active: 'notifications', inactive: 'notifications-outline' },
        { key: 'messages',      active: 'mail',          inactive: 'mail-outline' }
      ].freeze

      BOTTOM_STYLES = UI.stylesheet(
        wrap: {
          flexDirection: 'row',
          borderTopColor: COLORS[:borderSoft],
          borderTopWidth: HAIRLINE,
          backgroundColor: COLORS[:background],
          paddingTop: 6
        },
        tab: { flex: 1, alignItems: 'center', justifyContent: 'center', paddingVertical: 6 }
      )

      BottomTabs = UI.component 'BottomTabs' do |props|
        active       = props[:active]
        on_change    = props[:on_change]
        bottom_inset = (props[:bottom_inset] || 0).to_f
        pad_bottom   = [bottom_inset, 8].max
        wrap_style   = [BOTTOM_STYLES[:wrap], { paddingBottom: pad_bottom }]

        present View, testID: 'bottom-tabs', style: wrap_style do
          BOTTOM_TAB_DEFS.each do |tab|
            is_active = (tab[:key] == active)
            icon_name = is_active ? tab[:active] : tab[:inactive]
            color     = is_active ? COLORS[:text] : COLORS[:textMuted]

            present Pressable,
                    key:                 tab[:key],
                    style:               BOTTOM_STYLES[:tab],
                    onPress:             -> { on_change.call(tab[:key]) },
                    testID:              "bottom-tab-#{tab[:key]}",
                    accessibilityRole:   'button' do
              present Ionicons, name: icon_name, size: 26, color: color
            end
          end
        end
      end
    end
  end
end
