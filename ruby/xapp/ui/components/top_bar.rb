module XApp
  module UI
    module Components
      TOP_BAR_STYLES = UI.stylesheet(
        wrap: {
          backgroundColor: COLORS[:background],
          borderBottomColor: COLORS[:borderSoft],
          borderBottomWidth: HAIRLINE
        },
        logo_row: {
          paddingVertical: SPACING[:sm],
          alignItems: 'center',
          flexDirection: 'row',
          justifyContent: 'center'
        },
        logo:    { color: COLORS[:text], fontSize: 26, fontWeight: '900' },
        sparkle: { position: 'absolute', right: SPACING[:lg] },
        tab_row: { flexDirection: 'row', justifyContent: 'space-around' },
        tab:     { paddingVertical: SPACING[:sm], alignItems: 'center', flex: 1 },
        label:   { color: COLORS[:textMuted], fontSize: 15 },
        active:  { color: COLORS[:text], fontWeight: '700' },
        bar:     {
          marginTop: 6, height: 4, width: 48, borderRadius: 2,
          backgroundColor: COLORS[:accent]
        }
      )

      TopBar = UI.component 'TopBar' do |props|
        tabs       = props[:tabs]
        active_tab = props[:active_tab]
        on_change  = props[:on_change_tab]

        present View, style: TOP_BAR_STYLES[:wrap], testID: 'top-bar' do
          present View, style: TOP_BAR_STYLES[:logo_row] do
            present Text, style: TOP_BAR_STYLES[:logo] do
              '𝕏'
            end
            present Ionicons, name: 'sparkles-outline', size: 20,
                              color: COLORS[:text], style: TOP_BAR_STYLES[:sparkle]
          end

          present View, style: TOP_BAR_STYLES[:tab_row] do
            tabs.each do |tab|
              key    = tab[:key]
              label  = tab[:label]
              active = (key == active_tab)
              style  = active ? [TOP_BAR_STYLES[:label], TOP_BAR_STYLES[:active]] : TOP_BAR_STYLES[:label]

              present Pressable,
                      key:     key,
                      style:   TOP_BAR_STYLES[:tab],
                      onPress: -> { on_change.call(key) },
                      testID:  "top-tab-#{key}" do
                present Text, style: style do
                  label
                end
                present View, style: TOP_BAR_STYLES[:bar] if active
              end
            end
          end
        end
      end
    end
  end
end
