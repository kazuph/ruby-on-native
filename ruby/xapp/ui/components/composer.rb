module XApp
  module UI
    module Components
      COMPOSER_STYLES = UI.stylesheet(
        overlay: {
          position: 'absolute',
          top: 0, left: 0, right: 0, bottom: 0,
          backgroundColor: COLORS[:background],
          zIndex: 100
        },
        shell:    { flex: 1, backgroundColor: COLORS[:background], paddingTop: SPACING[:xl] },
        header:   {
          flexDirection: 'row', alignItems: 'center',
          paddingHorizontal: SPACING[:md], paddingVertical: SPACING[:sm],
          borderBottomColor: COLORS[:borderSoft], borderBottomWidth: HAIRLINE
        },
        cancel_hit:  { paddingVertical: 6, paddingRight: SPACING[:md] },
        cancel_text: { color: COLORS[:text], fontSize: 15 },
        flex1:       { flex: 1 },
        post_btn:    {
          backgroundColor: COLORS[:accent],
          paddingHorizontal: SPACING[:md],
          paddingVertical: 8,
          borderRadius: 999
        },
        post_btn_off:  { backgroundColor: '#0b4a75' },
        post_btn_text: { color: '#ffffff', fontWeight: '700', fontSize: 14 },
        body:          { flexDirection: 'row', padding: SPACING[:md], flex: 1 },
        avatar:        {
          width: 40, height: 40, borderRadius: 20,
          backgroundColor: COLORS[:border],
          marginRight: SPACING[:sm]
        },
        input_wrap:  { flex: 1 },
        handle_text: { color: COLORS[:textMuted], fontSize: 13, marginBottom: 4 },
        input:       { color: COLORS[:text], fontSize: 18, minHeight: 120, textAlignVertical: 'top' },
        footer:      {
          flexDirection: 'row', alignItems: 'center', padding: SPACING[:md],
          borderTopColor: COLORS[:borderSoft], borderTopWidth: HAIRLINE
        },
        footer_hint: { color: COLORS[:textMuted], fontSize: 13 }
      )

      Composer = UI.component 'Composer' do |props|
        visible   = props[:visible]
        me        = props[:me]
        on_cancel = props[:on_cancel]
        on_submit = props[:on_submit]

        draft, set_draft = use_state('')

        trimmed  = draft.to_s.strip
        can_post = !trimmed.empty?

        submit = lambda do
          if can_post
            on_submit.call(trimmed)
            set_draft.call('')
          end
        end

        cancel = lambda do
          set_draft.call('')
          on_cancel.call
        end

        # Early-out after the hook so the Rules of Hooks are respected even
        # when the composer is closed.
        if !visible
          nil
        else
          kav_behavior = PLATFORM_OS == 'ios' ? 'padding' : 'height'
          post_style   = can_post ? COMPOSER_STYLES[:post_btn] : [COMPOSER_STYLES[:post_btn], COMPOSER_STYLES[:post_btn_off]]

          present View, style: COMPOSER_STYLES[:overlay] do
            present KeyboardAvoidingView,
                    style:    COMPOSER_STYLES[:shell],
                    behavior: kav_behavior,
                    testID:   'composer-root' do

              present View, style: COMPOSER_STYLES[:header] do
                present Pressable,
                        onPress: cancel, hitSlop: 8,
                        style:   COMPOSER_STYLES[:cancel_hit],
                        testID:  'composer-cancel' do
                  present Text, style: COMPOSER_STYLES[:cancel_text] do
                    'キャンセル'
                  end
                end
                present View, style: COMPOSER_STYLES[:flex1]
                present Pressable,
                        onPress:  submit,
                        disabled: !can_post,
                        style:    post_style,
                        testID:   'composer-submit' do
                  present Text, style: COMPOSER_STYLES[:post_btn_text] do
                    'ポストする'
                  end
                end
              end

              present View, style: COMPOSER_STYLES[:body] do
                present Image,
                        source: { uri: me[:avatarUrl] },
                        style:  COMPOSER_STYLES[:avatar]

                present View, style: COMPOSER_STYLES[:input_wrap] do
                  present Text, style: COMPOSER_STYLES[:handle_text] do
                    "#{me[:displayName]}  @#{me[:handle]}"
                  end
                  present TextInput,
                          value:                draft,
                          onChangeText:         ->(t) { set_draft.call(t) },
                          placeholder:          'いまどうしてる？',
                          placeholderTextColor: COLORS[:textMuted],
                          multiline:            true,
                          autoFocus:            true,
                          style:                COMPOSER_STYLES[:input],
                          testID:               'composer-input'
                end
              end

              present View, style: COMPOSER_STYLES[:footer] do
                present Text, style: COMPOSER_STYLES[:footer_hint] do
                  "#{trimmed.length} / 280  (Ruby でハンドリング)"
                end
              end
            end
          end
        end
      end
    end
  end
end
