module XApp
  module UI
    module Screens
      DETAIL_STYLES = UI.stylesheet(
        wrap: { flex: 1, backgroundColor: COLORS[:background] },
        nav_bar: {
          flexDirection: 'row', alignItems: 'center',
          paddingHorizontal: SPACING[:md], paddingVertical: SPACING[:sm],
          borderBottomColor: COLORS[:borderSoft], borderBottomWidth: HAIRLINE
        },
        back_hit:    { paddingVertical: 6, paddingRight: SPACING[:md] },
        nav_title:   { color: COLORS[:text], fontSize: 18, fontWeight: '700' },
        missing:     { padding: SPACING[:lg] },
        missing_txt: { color: COLORS[:textMuted] },
        comment_row: {
          flexDirection: 'row',
          paddingHorizontal: SPACING[:lg], paddingVertical: SPACING[:md],
          borderBottomColor: COLORS[:borderSoft], borderBottomWidth: HAIRLINE
        },
        avatar: {
          width: 36, height: 36, borderRadius: 18,
          marginRight: SPACING[:sm], backgroundColor: COLORS[:border]
        },
        comment_body:   { flex: 1 },
        comment_header: { flexDirection: 'row', alignItems: 'center', marginBottom: 2 },
        name:      { color: COLORS[:text], fontWeight: '700', fontSize: 14, maxWidth: 160 },
        handle:    { color: COLORS[:textMuted], fontSize: 12 },
        dot:       { color: COLORS[:textMuted], marginHorizontal: 4 },
        body_text: { color: COLORS[:text], fontSize: 14, lineHeight: 19 },
        reply_bar: {
          flexDirection: 'row', alignItems: 'flex-end',
          padding: SPACING[:md],
          borderTopColor: COLORS[:borderSoft], borderTopWidth: HAIRLINE,
          backgroundColor: COLORS[:background]
        },
        reply_input: {
          flex: 1, color: COLORS[:text], fontSize: 15,
          paddingHorizontal: SPACING[:md], paddingVertical: 8,
          backgroundColor: COLORS[:surface], borderRadius: 999,
          maxHeight: 120
        },
        reply_send: {
          paddingHorizontal: SPACING[:md], paddingVertical: 8,
          marginLeft: SPACING[:sm], borderRadius: 999,
          backgroundColor: COLORS[:accent]
        },
        reply_send_off: { backgroundColor: '#0b4a75' },
        reply_send_text: { color: '#ffffff', fontWeight: '700' },
        empty: {
          padding: SPACING[:lg], alignItems: 'center'
        },
        empty_text: { color: COLORS[:textMuted], fontSize: 13 }
      )

      PostDetailScreen = UI.component 'PostDetailScreen' do |props|
        post_id = props[:post_id]
        on_back = props[:on_back]

        post,     set_post     = use_state(-> { XApp::API.find_post(post_id) })
        comments, set_comments = use_state(-> { XApp::API.comments(post_id) })
        draft,    set_draft    = use_state('')
        me                     = use_constant { XApp::API.me }
        my_handle              = me[:handle]

        trimmed      = draft.to_s.strip
        can_reply    = !trimmed.empty? && !post.nil?

        update_post = lambda do |next_post|
          set_post.call(next_post)
        end

        delete_post = lambda do |p|
          confirm('ポストを削除しますか？',
                  '削除すると元に戻せません。',
                  ok: '削除する', cancel: 'キャンセル') do
            XApp::API.delete_post(p[:id])
            on_back.call
          end
        end

        submit_reply = lambda do
          next unless can_reply
          XApp::API.add_comment(post_id, trimmed)
          set_comments.call(XApp::API.comments(post_id))
          set_post.call(XApp::API.find_post(post_id))
          set_draft.call('')
        end

        send_style = can_reply ? DETAIL_STYLES[:reply_send] : [DETAIL_STYLES[:reply_send], DETAIL_STYLES[:reply_send_off]]

        present KeyboardAvoidingView,
                style:    DETAIL_STYLES[:wrap],
                behavior: (PLATFORM_OS == 'ios' ? 'padding' : 'height'),
                testID:   'post-detail-screen' do

          present View, style: DETAIL_STYLES[:nav_bar] do
            present Pressable,
                    onPress: on_back,
                    hitSlop: 8,
                    style:   DETAIL_STYLES[:back_hit],
                    testID:  'detail-back' do
              present Ionicons, name: 'arrow-back', size: 22, color: COLORS[:text]
            end
            present Text, style: DETAIL_STYLES[:nav_title] do
              'ポスト'
            end
          end

          present ScrollView do
            if post.nil?
              present View, style: DETAIL_STYLES[:missing] do
                present Text, style: DETAIL_STYLES[:missing_txt] do
                  'ポストが見つかりませんでした。'
                end
              end
            else
              present Components::PostCard,
                      post:      post,
                      on_change: update_post,
                      on_delete: delete_post,
                      is_mine:   post[:author][:handle] == my_handle,
                      test_id_prefix: 'detail-post'

              if comments.empty?
                present View, style: DETAIL_STYLES[:empty], testID: 'detail-no-comments' do
                  present Text, style: DETAIL_STYLES[:empty_text] do
                    'まだコメントはありません。最初のコメントを投稿しよう！'
                  end
                end
              else
                comments.each_with_index do |c, idx|
                  present View,
                          key:    c[:id],
                          style:  DETAIL_STYLES[:comment_row],
                          testID: "comment-#{idx}" do
                    present Image,
                            source: { uri: c[:author][:avatarUrl] },
                            style:  DETAIL_STYLES[:avatar]
                    present View, style: DETAIL_STYLES[:comment_body] do
                      present View, style: DETAIL_STYLES[:comment_header] do
                        present Text, numberOfLines: 1, style: DETAIL_STYLES[:name] do
                          c[:author][:displayName]
                        end
                        present Text, numberOfLines: 1, style: DETAIL_STYLES[:handle] do
                          " @#{c[:author][:handle]}"
                        end
                        present Text, style: DETAIL_STYLES[:dot] do
                          '·'
                        end
                        present Text, style: DETAIL_STYLES[:handle] do
                          XApp::Formatter.relative_time(c[:createdAt])
                        end
                      end
                      present Text, style: DETAIL_STYLES[:body_text] do
                        c[:body]
                      end
                    end
                  end
                end
              end
            end
          end

          present View, style: DETAIL_STYLES[:reply_bar] do
            present TextInput,
                    value:                draft,
                    onChangeText:         ->(t) { set_draft.call(t) },
                    placeholder:          'コメントを追加…',
                    placeholderTextColor: COLORS[:textMuted],
                    multiline:            true,
                    style:                DETAIL_STYLES[:reply_input],
                    testID:               'comment-input'
            present Pressable,
                    onPress:  submit_reply,
                    disabled: !can_reply,
                    style:    send_style,
                    testID:   'comment-submit' do
              present Text, style: DETAIL_STYLES[:reply_send_text] do
                '送信'
              end
            end
          end
        end
      end
    end
  end
end
