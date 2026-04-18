module XApp
  module UI
    module Components
      SETTINGS_STYLES = UI.stylesheet(
        backdrop: {
          position: 'absolute',
          top: 0, left: 0, right: 0, bottom: 0,
          backgroundColor: 'rgba(0,0,0,0.65)',
          justifyContent: 'flex-end',
          zIndex: 200
        },
        sheet: {
          backgroundColor: COLORS[:surface],
          borderTopLeftRadius: 20, borderTopRightRadius: 20,
          paddingHorizontal: SPACING[:lg], paddingBottom: SPACING[:xl]
        },
        handle_bar: {
          alignSelf: 'center', width: 40, height: 4,
          borderRadius: 2, backgroundColor: COLORS[:border],
          marginTop: SPACING[:sm], marginBottom: SPACING[:md]
        },
        title:    { color: COLORS[:text], fontWeight: '800', fontSize: 18, marginBottom: SPACING[:md] },
        row:      {
          flexDirection: 'row', alignItems: 'center',
          paddingVertical: SPACING[:sm]
        },
        row_label: { color: COLORS[:textSecondary], fontSize: 14, flex: 1 },
        row_value: { color: COLORS[:text], fontSize: 14, fontWeight: '700' },
        divider:  { height: HAIRLINE, backgroundColor: COLORS[:border], marginVertical: SPACING[:sm] },
        action: {
          flexDirection: 'row', alignItems: 'center',
          paddingVertical: SPACING[:md]
        },
        action_icon: { marginRight: SPACING[:md] },
        action_label: { color: COLORS[:text], fontSize: 15, fontWeight: '700' },
        destructive: { color: COLORS[:like] }
      )

      SettingsSheet = UI.component 'SettingsSheet' do |props|
        visible  = props[:visible]
        on_close = props[:on_close]
        on_refresh = props[:on_refresh]
        on_reset   = props[:on_reset]

        if !visible
          nil
        else
          engine = XApp::API.engine_info
          own_posts = XApp::Store.count_user_posts
          comments_total = XApp::Store.db.scalar('SELECT COUNT(*) FROM post_comments').to_i

          present Pressable,
                  onPress: on_close,
                  style:   SETTINGS_STYLES[:backdrop],
                  testID:  'settings-backdrop' do
            # Stop-propagation wrapper so tapping the sheet itself doesn't
            # dismiss. Pressable onPress with no handler = swallowed event.
            present Pressable,
                    onPress: -> {},
                    style:   SETTINGS_STYLES[:sheet],
                    testID:  'settings-sheet' do
              present View, style: SETTINGS_STYLES[:handle_bar]
              present Text, style: SETTINGS_STYLES[:title] do
                '✨ ruby-on-native の現在'
              end

              # Engine + live SQLite stats
              present View, style: SETTINGS_STYLES[:row] do
                present Text, style: SETTINGS_STYLES[:row_label] do
                  'エンジン'
                end
                present Text, style: SETTINGS_STYLES[:row_value] do
                  "#{engine[:engine]} (#{engine[:rubyEngine]})"
                end
              end
              present View, style: SETTINGS_STYLES[:row] do
                present Text, style: SETTINGS_STYLES[:row_label] do
                  '自分のポスト数 (SQLite)'
                end
                present Text, style: SETTINGS_STYLES[:row_value], testID: 'settings-user-post-count' do
                  own_posts.to_s
                end
              end
              present View, style: SETTINGS_STYLES[:row] do
                present Text, style: SETTINGS_STYLES[:row_label] do
                  '累計コメント数 (SQLite)'
                end
                present Text, style: SETTINGS_STYLES[:row_value] do
                  comments_total.to_s
                end
              end

              present View, style: SETTINGS_STYLES[:divider]

              present Pressable,
                      onPress: on_refresh,
                      style:   SETTINGS_STYLES[:action],
                      testID:  'settings-refresh' do
                present Ionicons, name: 'refresh', size: 20, color: COLORS[:text],
                                  style: SETTINGS_STYLES[:action_icon]
                present Text, style: SETTINGS_STYLES[:action_label] do
                  'タイムラインを再読込'
                end
              end

              present Pressable,
                      onPress: on_reset,
                      style:   SETTINGS_STYLES[:action],
                      testID:  'settings-reset' do
                present Ionicons, name: 'trash-bin-outline', size: 20, color: COLORS[:like],
                                  style: SETTINGS_STYLES[:action_icon]
                present Text, style: [SETTINGS_STYLES[:action_label], SETTINGS_STYLES[:destructive]] do
                  '自分のポストを全削除'
                end
              end
            end
          end
        end
      end
    end
  end
end
