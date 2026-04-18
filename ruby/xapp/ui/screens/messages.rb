module XApp
  module UI
    module Screens
      MSG_STYLES = UI.stylesheet(
        wrap:   { flex: 1, backgroundColor: COLORS[:background] },
        header: {
          color: COLORS[:text], fontWeight: '800', fontSize: 20, padding: SPACING[:lg],
          borderBottomColor: COLORS[:borderSoft], borderBottomWidth: HAIRLINE
        },
        row: {
          flexDirection: 'row', padding: SPACING[:md],
          borderBottomColor: COLORS[:borderSoft], borderBottomWidth: HAIRLINE
        },
        avatar: {
          width: 48, height: 48, borderRadius: 24,
          marginRight: SPACING[:md], backgroundColor: COLORS[:border]
        },
        body:       { flex: 1 },
        header_row: { flexDirection: 'row', alignItems: 'center' },
        name:       { color: COLORS[:text], fontWeight: '700', maxWidth: 160 },
        handle:     { color: COLORS[:textMuted], fontSize: 13 },
        dot:        { color: COLORS[:textMuted], marginHorizontal: 4 },
        last:       { color: COLORS[:textMuted], marginTop: 2, fontSize: 14 }
      )

      MessagesScreen = UI.component 'MessagesScreen' do |_props|
        items = use_memo { XApp::API.messages }

        present View, style: MSG_STYLES[:wrap], testID: 'messages-screen' do
          present Text, style: MSG_STYLES[:header] do
            'メッセージ'
          end

          present FlatList,
                  data:         items,
                  keyExtractor: ->(item, _idx) { item[:peer][:id] },
                  renderItem:   ->(info) {
                    item = info[:item]
                    idx  = info[:index]
                    node View, style: MSG_STYLES[:row], testID: "message-#{idx}" do
                      present Image,
                              source: { uri: item[:peer][:avatarUrl] },
                              style:  MSG_STYLES[:avatar]
                      present View, style: MSG_STYLES[:body] do
                        present View, style: MSG_STYLES[:header_row] do
                          present Text, numberOfLines: 1, style: MSG_STYLES[:name] do
                            item[:peer][:displayName]
                          end
                          present Text, numberOfLines: 1, style: MSG_STYLES[:handle] do
                            " @#{item[:peer][:handle]}"
                          end
                          present Text, style: MSG_STYLES[:dot] do
                            '·'
                          end
                          present Text, style: MSG_STYLES[:handle] do
                            item[:relativeTime]
                          end
                        end
                        present Text, numberOfLines: 1, style: MSG_STYLES[:last] do
                          item[:last]
                        end
                      end
                    end
                  }
        end
      end
    end
  end
end
