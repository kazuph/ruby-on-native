module XApp
  module UI
    module Screens
      SEARCH_STYLES = UI.stylesheet(
        wrap:       { flex: 1, backgroundColor: COLORS[:background] },
        search_row: {
          flexDirection: 'row', alignItems: 'center', margin: SPACING[:md],
          paddingHorizontal: SPACING[:md], paddingVertical: SPACING[:sm],
          borderRadius: 999,
          borderColor: COLORS[:border], borderWidth: HAIRLINE,
          backgroundColor: COLORS[:surface]
        },
        input: {
          flex: 1, color: COLORS[:text],
          marginLeft: SPACING[:sm], paddingVertical: 0
        },
        section_title: {
          color: COLORS[:text], fontWeight: '700', fontSize: 18,
          paddingHorizontal: SPACING[:lg], paddingVertical: SPACING[:sm]
        },
        row: {
          flexDirection: 'row', alignItems: 'center',
          paddingHorizontal: SPACING[:lg], paddingVertical: SPACING[:md],
          borderBottomColor: COLORS[:borderSoft],
          borderBottomWidth: HAIRLINE
        },
        body:     { flex: 1 },
        category: { color: COLORS[:textMuted], fontSize: 12 },
        title:    { color: COLORS[:text], fontWeight: '700', fontSize: 15, marginVertical: 2 },
        volume:   { color: COLORS[:textMuted], fontSize: 12 }
      )

      SearchScreen = UI.component 'SearchScreen' do |_props|
        trends = use_memo { XApp::API.trends }

        present View, style: SEARCH_STYLES[:wrap], testID: 'search-screen' do
          present View, style: SEARCH_STYLES[:search_row] do
            present Ionicons, name: 'search', size: 18, color: COLORS[:textMuted]
            present TextInput,
                    placeholder:          '検索',
                    placeholderTextColor: COLORS[:textMuted],
                    style:                SEARCH_STYLES[:input],
                    testID:               'search-input'
          end

          present ScrollView do
            present Text, style: SEARCH_STYLES[:section_title] do
              'あなた向けのトレンド'
            end
            trends.each_with_index do |t, idx|
              present View,
                      key:    t[:title],
                      style:  SEARCH_STYLES[:row],
                      testID: "trend-#{idx}" do
                present View, style: SEARCH_STYLES[:body] do
                  present Text, style: SEARCH_STYLES[:category] do
                    t[:category]
                  end
                  present Text, style: SEARCH_STYLES[:title] do
                    t[:title]
                  end
                  present Text, style: SEARCH_STYLES[:volume] do
                    "#{t[:volume]}のポスト"
                  end
                end
                present Ionicons, name: 'ellipsis-horizontal', size: 16, color: COLORS[:textMuted]
              end
            end
          end
        end
      end
    end
  end
end
