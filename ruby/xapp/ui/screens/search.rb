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
        clear_hit: { paddingHorizontal: SPACING[:sm], paddingVertical: 2 },
        section_title: {
          color: COLORS[:text], fontWeight: '700', fontSize: 18,
          paddingHorizontal: SPACING[:lg], paddingVertical: SPACING[:sm]
        },
        result_meta: {
          color: COLORS[:textMuted], fontSize: 13,
          paddingHorizontal: SPACING[:lg], paddingBottom: SPACING[:sm]
        },
        trend_row: {
          flexDirection: 'row', alignItems: 'center',
          paddingHorizontal: SPACING[:lg], paddingVertical: SPACING[:md],
          borderBottomColor: COLORS[:borderSoft],
          borderBottomWidth: HAIRLINE
        },
        trend_body: { flex: 1 },
        category:   { color: COLORS[:textMuted], fontSize: 12 },
        title:      { color: COLORS[:text], fontWeight: '700', fontSize: 15, marginVertical: 2 },
        volume:     { color: COLORS[:textMuted], fontSize: 12 },
        empty_state: { padding: SPACING[:xl], alignItems: 'center' },
        empty_text:  { color: COLORS[:textMuted], marginTop: SPACING[:sm] }
      )

      SearchScreen = UI.component 'SearchScreen' do |props|
        on_open_post = props[:on_open_post]

        query, set_query = use_state('')
        trends           = use_constant { XApp::API.trends }
        me               = use_constant { XApp::API.me }
        my_handle        = me[:handle]

        trimmed = query.to_s.strip
        results = trimmed.empty? ? [] : XApp::API.search(trimmed)

        present View, style: SEARCH_STYLES[:wrap], testID: 'search-screen' do
          present View, style: SEARCH_STYLES[:search_row] do
            present Ionicons, name: 'search', size: 18, color: COLORS[:textMuted]
            present TextInput,
                    value:                query,
                    onChangeText:         ->(t) { set_query.call(t) },
                    placeholder:          '検索 (本文 / ハンドル / 名前)',
                    placeholderTextColor: COLORS[:textMuted],
                    style:                SEARCH_STYLES[:input],
                    returnKeyType:        'search',
                    autoCorrect:          false,
                    testID:               'search-input'
            if !trimmed.empty?
              present Pressable,
                      onPress: -> { set_query.call('') },
                      hitSlop: 8,
                      style:   SEARCH_STYLES[:clear_hit],
                      testID:  'search-clear' do
                present Ionicons, name: 'close-circle', size: 18, color: COLORS[:textMuted]
              end
            end
          end

          if trimmed.empty?
            present ScrollView, testID: 'search-trends' do
              present Text, style: SEARCH_STYLES[:section_title] do
                'あなた向けのトレンド'
              end
              trends.each_with_index do |t, idx|
                present View,
                        key:    t[:title],
                        style:  SEARCH_STYLES[:trend_row],
                        testID: "trend-#{idx}" do
                  present View, style: SEARCH_STYLES[:trend_body] do
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
          else
            present View, testID: 'search-results', style: { flex: 1 } do
              present Text, style: SEARCH_STYLES[:result_meta] do
                "「#{trimmed}」の結果: #{results.length} 件"
              end
              if results.empty?
                present View, style: SEARCH_STYLES[:empty_state], testID: 'search-empty' do
                  present Ionicons, name: 'search-outline', size: 32, color: COLORS[:textMuted]
                  present Text, style: SEARCH_STYLES[:empty_text] do
                    '一致するポストは見つかりませんでした。'
                  end
                end
              else
                present FlatList,
                        data:         results,
                        keyExtractor: ->(item, _i) { item[:id] },
                        renderItem:   ->(info) {
                          item = info[:item]
                          present Components::PostCard,
                                  post:      item,
                                  on_change: ->(_p) {},
                                  on_open:   on_open_post,
                                  is_mine:   item[:author][:handle] == my_handle
                        }
              end
            end
          end
        end
      end
    end
  end
end
