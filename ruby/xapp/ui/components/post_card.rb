module XApp
  module UI
    module Components
      POST_CARD_STYLES = UI.stylesheet(
        card: {
          flexDirection: 'row',
          paddingHorizontal: SPACING[:lg],
          paddingVertical: SPACING[:md],
          borderBottomColor: COLORS[:borderSoft],
          borderBottomWidth: HAIRLINE,
          backgroundColor: COLORS[:background]
        },
        avatar:     { width: 40, height: 40, borderRadius: 20, backgroundColor: COLORS[:border] },
        body:       { marginLeft: SPACING[:md], flex: 1 },
        header_row: { flexDirection: 'row', alignItems: 'center', marginBottom: 2 },
        name:       { color: COLORS[:text], fontWeight: '700', fontSize: 15, maxWidth: 160 },
        verified:   { marginLeft: 2 },
        handle:     { color: COLORS[:textMuted], fontSize: 14 },
        dot:        { color: COLORS[:textMuted], marginHorizontal: 4 },
        grow:       { flex: 1 },
        body_text:  { color: COLORS[:text], fontSize: 15, lineHeight: 20, marginTop: 2 },
        media:      { marginTop: SPACING[:sm], borderRadius: 16, overflow: 'hidden', backgroundColor: COLORS[:border] },
        media_one:  { aspectRatio: 16.0 / 10.0 },
        media_grid: { flexDirection: 'row', flexWrap: 'wrap', aspectRatio: 16.0 / 10.0 },
        media_img:  { backgroundColor: COLORS[:border] },
        action_row: { marginTop: SPACING[:sm], flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
        action:     { flexDirection: 'row', alignItems: 'center', paddingVertical: 4, paddingHorizontal: 2 },
        action_text: { marginLeft: 6, fontSize: 13 }
      )

      def self.media_cell(count, idx)
        return { width: '100%', height: '100%' } if count == 1
        return { width: '50%',  height: '100%' } if count == 2
        if count == 3
          return idx.zero? ? { width: '100%', height: '50%' } : { width: '50%', height: '50%' }
        end
        { width: '50%', height: '50%' }
      end

      ActionButton = UI.component 'ActionButton' do |props|
        icon    = props[:icon]
        label   = props[:label]
        color   = props[:color]
        on_tap  = props[:on_tap]
        test_id = props[:test_id]

        present Pressable,
                onPress:  on_tap,
                hitSlop:  6,
                style:    POST_CARD_STYLES[:action],
                testID:   test_id do
          present Ionicons, name: icon, size: 18, color: color
          if label && label != ''
            present Text,
                    numberOfLines: 1,
                    style: [POST_CARD_STYLES[:action_text], { color: color }] do
              label
            end
          end
        end
      end

      PostCard = UI.component 'PostCard' do |props|
        post         = props[:post]
        on_change    = props[:on_change]
        on_open      = props[:on_open]         # optional: tap on card → navigate
        on_delete    = props[:on_delete]       # optional: tap trash on own posts
        on_open_user = props[:on_open_user]    # optional: tap avatar / handle
        is_mine      = props[:is_mine]         # pre-computed by parent (nil/false for seed)
        prefix       = props[:test_id_prefix] || "post-#{post[:id]}"

        like_color      = post[:liked]      ? COLORS[:like]   : COLORS[:textMuted]
        repost_color    = post[:reposted]   ? COLORS[:repost] : COLORS[:textMuted]
        bookmark_color  = post[:bookmarked] ? COLORS[:accent] : COLORS[:textMuted]

        handle_like     = -> { on_change.call(XApp::Engagement.toggle_like(post)) }
        handle_repost   = -> { on_change.call(XApp::Engagement.toggle_repost(post)) }
        handle_bookmark = -> { on_change.call(XApp::Engagement.toggle_bookmark(post)) }
        handle_open     = -> { on_open&.call(post) }
        handle_delete   = -> { on_delete&.call(post) }
        handle_author   = -> { on_open_user&.call(post[:author][:handle]) }

        present Pressable,
                onPress:    handle_open,
                # Let Maestro (and VoiceOver) still see every child node;
                # otherwise the outer Pressable swallows the tree into one
                # button-style accessible element and text assertions fail.
                accessible: false,
                style:      POST_CARD_STYLES[:card],
                testID:     prefix do
          present Pressable,
                  onPress: handle_author,
                  hitSlop: 6,
                  testID:  "#{prefix}-avatar" do
            present Image, source: { uri: post[:author][:avatarUrl] }, style: POST_CARD_STYLES[:avatar]
          end

          present View, style: POST_CARD_STYLES[:body] do
            present View, style: POST_CARD_STYLES[:header_row] do
              present Pressable,
                      onPress: handle_author,
                      hitSlop: 4,
                      testID:  "#{prefix}-author" do
                present Text, numberOfLines: 1, style: POST_CARD_STYLES[:name] do
                  post[:author][:displayName]
                end
              end
              if post[:author][:verified]
                present Ionicons, name: 'checkmark-circle', size: 16,
                                  color: COLORS[:accent], style: POST_CARD_STYLES[:verified]
              end
              present Pressable,
                      onPress: handle_author,
                      hitSlop: 4,
                      testID:  "#{prefix}-handle" do
                present Text, numberOfLines: 1, style: POST_CARD_STYLES[:handle] do
                  "  @#{post[:author][:handle]}"
                end
              end
              present Text, style: POST_CARD_STYLES[:dot] do
                '·'
              end
              present Text, style: POST_CARD_STYLES[:handle] do
                XApp::Formatter.relative_time(post[:createdAt])
              end
              present View, style: POST_CARD_STYLES[:grow]
              if is_mine
                present Pressable,
                        onPress: handle_delete,
                        hitSlop: 8,
                        testID:  "#{prefix}-delete" do
                  present Ionicons, name: 'trash-outline', size: 16, color: COLORS[:textMuted]
                end
              else
                present Ionicons, name: 'ellipsis-horizontal', size: 16, color: COLORS[:textMuted]
              end
            end

            present Text, style: POST_CARD_STYLES[:body_text] do
              post[:body]
            end

            images = post[:images] || []
            if images.any?
              media_style = [
                POST_CARD_STYLES[:media],
                images.length == 1 ? POST_CARD_STYLES[:media_one] : POST_CARD_STYLES[:media_grid]
              ]
              present View, style: media_style do
                images.first(4).each_with_index do |uri, idx|
                  cell = Components.media_cell(images.length, idx)
                  present Image,
                          key:        "#{post[:id]}-img-#{idx}",
                          source:     { uri: uri },
                          style:      [POST_CARD_STYLES[:media_img], cell],
                          resizeMode: 'cover'
                end
              end
            end

            present View, style: POST_CARD_STYLES[:action_row] do
              present ActionButton, icon: 'chatbubble-outline',
                      label: XApp::Formatter.compact_count(post[:replies]),
                      color: COLORS[:textMuted], test_id: "#{prefix}-reply"
              present ActionButton, icon: 'repeat',
                      label: XApp::Formatter.compact_count(post[:reposts]),
                      color: repost_color, on_tap: handle_repost,
                      test_id: "#{prefix}-repost"
              present ActionButton, icon: (post[:liked] ? 'heart' : 'heart-outline'),
                      label: XApp::Formatter.compact_count(post[:likes]),
                      color: like_color, on_tap: handle_like,
                      test_id: "#{prefix}-like"
              present ActionButton, icon: 'stats-chart-outline',
                      label: XApp::Formatter.compact_count(post[:views]),
                      color: COLORS[:textMuted], test_id: "#{prefix}-views"
              present ActionButton, icon: (post[:bookmarked] ? 'bookmark' : 'bookmark-outline'),
                      label: '', color: bookmark_color, on_tap: handle_bookmark,
                      test_id: "#{prefix}-bookmark"
            end
          end
        end
      end
    end
  end
end
