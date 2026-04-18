module XApp
  module UI
    module Screens
      PROFILE_STYLES = UI.stylesheet(
        wrap:  { flex: 1, backgroundColor: COLORS[:background] },
        nav_bar: {
          flexDirection: 'row', alignItems: 'center',
          paddingHorizontal: SPACING[:md], paddingVertical: SPACING[:sm],
          borderBottomColor: COLORS[:borderSoft], borderBottomWidth: HAIRLINE
        },
        back_hit:  { paddingVertical: 6, paddingRight: SPACING[:md] },
        nav_title: { color: COLORS[:text], fontSize: 18, fontWeight: '700' },
        banner:    { width: '100%', height: 140, backgroundColor: COLORS[:border] },
        header:    { paddingHorizontal: SPACING[:lg], paddingBottom: SPACING[:md] },
        avatar_row: {
          flexDirection: 'row', alignItems: 'flex-end',
          justifyContent: 'space-between',
          marginTop: -40, marginBottom: SPACING[:sm]
        },
        avatar: {
          width: 80, height: 80, borderRadius: 40,
          borderWidth: 4, borderColor: COLORS[:background],
          backgroundColor: COLORS[:border]
        },
        follow_btn: {
          paddingHorizontal: SPACING[:md], paddingVertical: 8,
          borderRadius: 999,
          borderWidth: 1, borderColor: COLORS[:text],
          backgroundColor: COLORS[:background]
        },
        follow_text: { color: COLORS[:text], fontWeight: '700' },
        name_row:    { flexDirection: 'row', alignItems: 'center' },
        display:     { color: COLORS[:text], fontSize: 22, fontWeight: '800' },
        verified:    { marginLeft: SPACING[:sm] },
        handle:      { color: COLORS[:textMuted], fontSize: 14, marginTop: 2 },
        bio:         { color: COLORS[:text], fontSize: 14, lineHeight: 20, marginTop: SPACING[:sm] },
        meta_row: {
          flexDirection: 'row', alignItems: 'center', flexWrap: 'wrap',
          marginTop: SPACING[:sm]
        },
        meta_item:  { flexDirection: 'row', alignItems: 'center', marginRight: SPACING[:md], marginBottom: 4 },
        meta_text:  { color: COLORS[:textMuted], fontSize: 13, marginLeft: 4 },
        stats_row:  { flexDirection: 'row', marginTop: SPACING[:sm] },
        stats_pair: { flexDirection: 'row', marginRight: SPACING[:lg] },
        stats_num:  { color: COLORS[:text], fontWeight: '700', marginRight: 4 },
        stats_label: { color: COLORS[:textMuted] },
        section_title: {
          color: COLORS[:text], fontWeight: '800', fontSize: 16,
          paddingHorizontal: SPACING[:lg], paddingVertical: SPACING[:md],
          borderBottomColor: COLORS[:borderSoft], borderBottomWidth: HAIRLINE
        },
        missing:     { padding: SPACING[:lg] },
        missing_txt: { color: COLORS[:textMuted] }
      )

      ProfileScreen = UI.component 'ProfileScreen' do |props|
        handle   = props[:handle]
        on_back  = props[:on_back]
        on_open  = props[:on_open_post]

        user             = use_memo(handle) { XApp::API.user(handle) }
        posts, set_posts = use_state(-> { XApp::API.user_posts(handle) })
        me               = use_constant { XApp::API.me }
        is_me            = user && user[:handle] == me[:handle]

        delete_post = lambda do |post|
          confirm('ポストを削除しますか？',
                  '削除すると元に戻せません。',
                  ok: '削除する', cancel: 'キャンセル') do
            XApp::API.delete_post(post[:id])
            set_posts.call(XApp::API.user_posts(handle))
          end
        end

        present View, style: PROFILE_STYLES[:wrap], testID: 'profile-screen' do
          present View, style: PROFILE_STYLES[:nav_bar] do
            present Pressable,
                    onPress: on_back,
                    hitSlop: 8,
                    style:   PROFILE_STYLES[:back_hit],
                    testID:  'profile-back' do
              present Ionicons, name: 'arrow-back', size: 22, color: COLORS[:text]
            end
            present Text, style: PROFILE_STYLES[:nav_title] do
              user ? user[:displayName] : 'プロフィール'
            end
          end

          if user.nil?
            present View, style: PROFILE_STYLES[:missing] do
              present Text, style: PROFILE_STYLES[:missing_txt] do
                "@#{handle} は見つかりませんでした。"
              end
            end
          else
            present ScrollView do
              present Image, source: { uri: user[:bannerUrl] }, style: PROFILE_STYLES[:banner]
              present View, style: PROFILE_STYLES[:header] do
                present View, style: PROFILE_STYLES[:avatar_row] do
                  present Image, source: { uri: user[:avatarUrl] }, style: PROFILE_STYLES[:avatar]
                  present Pressable,
                          style:  PROFILE_STYLES[:follow_btn],
                          testID: 'profile-follow' do
                    present Text, style: PROFILE_STYLES[:follow_text] do
                      is_me ? 'プロフィールを編集' : 'フォロー'
                    end
                  end
                end
                present View, style: PROFILE_STYLES[:name_row] do
                  present Text, style: PROFILE_STYLES[:display] do
                    user[:displayName]
                  end
                  if user[:verified]
                    present Ionicons, name: 'checkmark-circle', size: 18,
                                      color: COLORS[:accent],
                                      style: PROFILE_STYLES[:verified]
                  end
                end
                present Text, style: PROFILE_STYLES[:handle] do
                  "@#{user[:handle]}"
                end
                unless user[:bio].to_s.empty?
                  present Text, style: PROFILE_STYLES[:bio] do
                    user[:bio]
                  end
                end
                present View, style: PROFILE_STYLES[:meta_row] do
                  unless user[:location].to_s.empty?
                    present View, style: PROFILE_STYLES[:meta_item] do
                      present Ionicons, name: 'location-outline', size: 14, color: COLORS[:textMuted]
                      present Text, style: PROFILE_STYLES[:meta_text] do
                        user[:location]
                      end
                    end
                  end
                  unless user[:joinedAt].to_s.empty?
                    present View, style: PROFILE_STYLES[:meta_item] do
                      present Ionicons, name: 'calendar-outline', size: 14, color: COLORS[:textMuted]
                      present Text, style: PROFILE_STYLES[:meta_text] do
                        user[:joinedAt]
                      end
                    end
                  end
                end
                present View, style: PROFILE_STYLES[:stats_row] do
                  present View, style: PROFILE_STYLES[:stats_pair] do
                    present Text, style: PROFILE_STYLES[:stats_num] do
                      XApp::Formatter.compact_count(user[:following])
                    end
                    present Text, style: PROFILE_STYLES[:stats_label] do
                      'フォロー中'
                    end
                  end
                  present View, style: PROFILE_STYLES[:stats_pair] do
                    present Text, style: PROFILE_STYLES[:stats_num] do
                      XApp::Formatter.compact_count(user[:followers])
                    end
                    present Text, style: PROFILE_STYLES[:stats_label] do
                      'フォロワー'
                    end
                  end
                end
              end

              present Text, style: PROFILE_STYLES[:section_title] do
                "ポスト (#{posts.length})"
              end

              posts.each_with_index do |p, idx|
                present Components::PostCard,
                        key:       p[:id],
                        post:      p,
                        on_change: ->(_n) {},
                        on_open:   on_open,
                        # Only own posts are deletable — seed posts (other
                        # users) stay immutable — so we pair `is_mine`
                        # with a real `on_delete` hander here.
                        on_delete: (is_me ? delete_post : nil),
                        is_mine:   is_me,
                        test_id_prefix: "profile-post-#{idx}"
              end
            end
          end
        end
      end
    end
  end
end
