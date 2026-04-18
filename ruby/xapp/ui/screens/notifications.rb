module XApp
  module UI
    module Screens
      NOTIF_STYLES = UI.stylesheet(
        wrap:   { flex: 1, backgroundColor: COLORS[:background] },
        header: {
          color: COLORS[:text], fontWeight: '800', fontSize: 20, padding: SPACING[:lg],
          borderBottomColor: COLORS[:borderSoft], borderBottomWidth: HAIRLINE
        },
        row: {
          flexDirection: 'row',
          paddingHorizontal: SPACING[:lg], paddingVertical: SPACING[:md],
          borderBottomColor: COLORS[:borderSoft], borderBottomWidth: HAIRLINE
        },
        leading: { width: 30, marginTop: 4 },
        body:    { flex: 1, flexDirection: 'row' },
        avatar:  {
          width: 32, height: 32, borderRadius: 16,
          marginRight: SPACING[:sm], backgroundColor: COLORS[:border]
        },
        text_block: { flex: 1 },
        text:       { color: COLORS[:text], fontSize: 14, lineHeight: 19 },
        bold:       { fontWeight: '700', color: COLORS[:text] }
      )

      ICONS_BY_KIND = {
        'like'    => { name: 'heart',              color: COLORS[:like] },
        'repost'  => { name: 'repeat',             color: COLORS[:repost] },
        'follow'  => { name: 'person-add',         color: COLORS[:accent] },
        'mention' => { name: 'chatbubble-ellipses', color: COLORS[:accent] }
      }.freeze

      NotificationsScreen = UI.component 'NotificationsScreen' do |_props|
        items = use_memo { XApp::API.notifications }

        present View, style: NOTIF_STYLES[:wrap], testID: 'notifications-screen' do
          present Text, style: NOTIF_STYLES[:header] do
            '通知'
          end

          present FlatList,
                  data:         items,
                  keyExtractor: ->(_item, idx) { "notif-#{idx}" },
                  renderItem:   ->(info) {
                    item = info[:item]
                    idx  = info[:index]
                    icon = ICONS_BY_KIND[item[:kind]] || ICONS_BY_KIND[:mention]

                    node View, style: NOTIF_STYLES[:row], testID: "notification-#{idx}" do
                      present Ionicons, name: icon[:name], size: 22,
                                        color: icon[:color], style: NOTIF_STYLES[:leading]
                      present View, style: NOTIF_STYLES[:body] do
                        present Image,
                                source: { uri: item[:actor][:avatarUrl] },
                                style:  NOTIF_STYLES[:avatar]
                        present View, style: NOTIF_STYLES[:text_block] do
                          present Text, style: NOTIF_STYLES[:text] do
                            present Text, style: NOTIF_STYLES[:bold] do
                              item[:actor][:displayName]
                            end
                            t(item[:body])
                          end
                        end
                      end
                    end
                  }
        end
      end
    end
  end
end
