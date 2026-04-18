# backtick_javascript: true
require 'native'

module XApp
  # Tiny Ruby DSL around React.createElement. Inspired by
  # zetachang/opal-native's `present(View) do ... end` but aimed at React 19
  # function components + hooks.
  #
  # Component authors never touch the JS side: they just write
  #
  #   module XApp
  #     module UI
  #       HomeScreen = component 'HomeScreen' do |props|
  #         tab, set_tab = use_state('foryou')
  #         present View, style: styles[:wrap] do
  #           present TopBar, active_tab: tab, on_change_tab: set_tab
  #           present Text, style: styles[:hello] do
  #             'こんにちは、マスター'
  #           end
  #         end
  #       end
  #     end
  #   end
  #
  # No `XApp::UI.` prefix, no `Native()` wrapping, no explicit JS glue —
  # `_call_component` instance_exec's the block inside UI so bare method
  # calls (present / use_state / stylesheet / etc.) Just Work. We translate
  # Ruby ⇄ JS at the boundary (see `__deep_to_native__` / `__walk_js_to_rb__`)
  # so authors don't see the friction.
  module UI
    `var React = __RN__.React`
    `var RN = __RN__.RN`
    `var Expo = __RN__.Expo`

    # --- React / Native primitives as Ruby constants ---------------------

    React                = `React`
    Fragment             = `React.Fragment`

    View                 = `RN.View`
    Text                 = `RN.Text`
    Image                = `RN.Image`
    FlatList             = `RN.FlatList`
    ScrollView           = `RN.ScrollView`
    Pressable            = `RN.Pressable`
    TextInput            = `RN.TextInput`
    StyleSheet           = `RN.StyleSheet`
    Modal                = `RN.Modal`
    KeyboardAvoidingView = `RN.KeyboardAvoidingView`
    PLATFORM_OS          = `RN.platformOS`

    StatusBar            = `Expo.StatusBar`
    SafeAreaProvider     = `Expo.SafeAreaProvider`
    Ionicons             = `Expo.Ionicons`

    HAIRLINE = `RN.StyleSheet.hairlineWidth`

    module_function

    # --- Ruby ⇄ JS bridge (installed as plain JS functions on UI module
    # itself to avoid Opal's `$def` re-entrancy quirks when recursing) ----

    %x{
      var uiModule = #{self};
      var ObjProto = Object.prototype;

      uiModule.__deep_to_native__ = function(value) {
        var nilRef = #{nil};
        function wrapProc(p) {
          return function() {
            var args = [];
            for (var i = 0; i < arguments.length; i++) {
              args.push(uiModule.__walk_js_to_rb__(arguments[i]));
            }
            var out = p.$call.apply(p, args);
            return out === nilRef ? null : out;
          };
        }
        function convert(v) {
          if (v == null || v === nilRef) return null;
          if (typeof v === 'function') {
            if (v.$$is_proc || v.$$is_lambda) return wrapProc(v);
            return v;
          }
          var t = typeof v;
          if (t !== 'object') {
            if (t === 'symbol') return v.description;
            return v;
          }
          if (v.$$is_proc) return wrapProc(v);
          if (v.$$typeof) return v;
          if (v instanceof Map) {
            var obj = {};
            v.forEach(function(val, key){ obj[String(key)] = convert(val); });
            return obj;
          }
          if (Array.isArray(v)) {
            var out = [];
            for (var i = 0; i < v.length; i++) out.push(convert(v[i]));
            return out;
          }
          var proto = Object.getPrototypeOf(v);
          if (proto === ObjProto || proto === null) {
            var o2 = {};
            for (var k in v) {
              if (Object.prototype.hasOwnProperty.call(v, k)) {
                o2[k] = convert(v[k]);
              }
            }
            return o2;
          }
          return v;
        }
        return convert(value);
      };

      uiModule.__walk_js_to_rb__ = function(value) {
        var nilRef = #{nil};
        function isPlainObject(v) {
          if (v === null || typeof v !== 'object') return false;
          if (Array.isArray(v)) return false;
          if (v instanceof Map || v instanceof Set) return false;
          var proto = Object.getPrototypeOf(v);
          return proto === ObjProto || proto === null;
        }
        function walk(v) {
          if (v == null) return nilRef;
          if (typeof v !== 'object') return v;
          if (v.$$typeof) return v;
          if (Array.isArray(v)) {
            var arr = [];
            for (var i = 0; i < v.length; i++) arr.push(walk(v[i]));
            return arr;
          }
          if (!isPlainObject(v)) return v;
          var h = new Map();
          for (var k in v) {
            if (Object.prototype.hasOwnProperty.call(v, k)) {
              h.$store(k.$to_sym(), walk(v[k]));
            }
          }
          return h;
        }
        return walk(value);
      };
    }

    def deep_to_native(value)
      `return #{self}.__deep_to_native__(value)`
    end

    def js_to_rb(value)
      `return #{self}.__walk_js_to_rb__(value)`
    end

    # --- Stack-based children collection --------------------------------

    @frames = []

    class << self
      attr_reader :frames
    end

    def push_frame
      f = []
      UI.frames.push(f)
      f
    end

    def pop_frame
      UI.frames.pop
    end

    def current_frame
      UI.frames.last
    end

    # --- el / present / node --------------------------------------------

    def _merge_props(positional, rest)
      return (rest.empty? ? nil : rest) if positional.nil?
      rest.empty? ? positional : positional.merge(rest)
    end

    def _collect_children(&block)
      return [] unless block
      frame  = push_frame
      result = begin
                 block.call
               ensure
                 pop_frame
               end
      children = frame.dup
      children << result if children.empty? && !result.nil? && result != false
      children
    end

    def _build_element(type, props, children)
      native_props = props ? deep_to_native(props) : `null`
      `return React.createElement.apply(React, [#{type}, #{native_props}].concat(#{children}))`
    end

    # `present View, style: ..., testID: ... do ... end`
    # Builds a React element and attaches it to the parent block's children.
    def present(type, props = nil, **rest, &block)
      final_props = _merge_props(props, rest)
      children    = _collect_children(&block)
      element     = _build_element(type, final_props, children)
      current_frame&.push(element)
      element
    end

    # Like `present` but does not auto-attach to the surrounding children
    # frame. Use when you need a subtree to hand off as a prop (e.g.
    # ListHeaderComponent).
    def node(type, props = nil, **rest, &block)
      final_props = _merge_props(props, rest)
      children    = _collect_children(&block)
      _build_element(type, final_props, children)
    end

    # Push a plain text / number child into the current frame. Usually you
    # don't need this — `present(Text) { 'hi' }` handles the common case.
    def t(value)
      current_frame&.push(value)
      value
    end

    # --- Hooks -----------------------------------------------------------

    def wrap_proc(p)
      `return #{self}.__deep_to_native__(p)`
    end

    def use_state(initial)
      pair = if initial.is_a?(Proc)
               init_fn = wrap_proc(initial)
               `React.useState(#{init_fn})`
             else
               `React.useState(#{initial})`
             end
      value    = `#{pair}[0]`
      js_setter = `#{pair}[1]`
      setter   = lambda do |next_value|
        nv = next_value.is_a?(Proc) ? wrap_proc(next_value) : next_value
        `#{js_setter}(#{nv})`
        nil
      end
      [value, setter]
    end

    # `use_memo(a, b) { expensive_compute(a, b) }`
    # Deps are required — React's stale-closure gotchas aren't worth hiding.
    # For "compute once on mount, never again", use `use_constant`.
    def use_memo(*deps, &block)
      fn  = wrap_proc(block)
      arr = deep_to_native(deps)
      `React.useMemo(#{fn}, #{arr})`
    end

    def use_callback(*deps, &block)
      fn  = wrap_proc(block)
      arr = deep_to_native(deps)
      `React.useCallback(#{fn}, #{arr})`
    end

    def use_effect(*deps, &block)
      fn  = wrap_proc(block)
      arr = deep_to_native(deps)
      `React.useEffect(#{fn}, #{arr})`
      nil
    end

    # `use_constant { XApp::API.timeline }`
    # Explicitly memoise with an empty deps array — clearly signals
    # "this value never recomputes after mount".
    def use_constant(&block)
      fn = wrap_proc(block)
      `React.useMemo(#{fn}, [])`
    end

    def use_safe_area_insets
      Native(`__RN__.Expo.useSafeAreaInsets()`)
    end

    # --- OS-level UI ----------------------------------------------------

    # `confirm '削除しますか？', 'このポストを削除します', ok: '削除' do; ... end`
    # Shows an OS confirmation dialog and runs the block iff the user
    # taps OK. Cancel is a silent no-op.
    def confirm(title, message, ok: 'OK', cancel: 'キャンセル', &on_ok)
      cb = on_ok ? wrap_proc(on_ok) : `function(){}`
      `__RN__.UI.confirm(#{title}, #{message}, #{ok}, #{cancel}, #{cb})`
      nil
    end

    # --- Component factory ----------------------------------------------

    # `component 'Name' do |props| ... end`
    # The block runs inside UI's context (via instance_exec) so authors can
    # write `present`, `use_state`, `styles`, etc. without any prefix.
    def component(name = nil, &block)
      ruby_fn = block
      self_ref = self
      `return (function(){
        var fn = function(props) {
          return #{self_ref}.$_call_component(props, #{ruby_fn});
        };
        if (#{name}) fn.displayName = #{name};
        return fn;
      })()`
    end

    def _call_component(js_props, block)
      rb     = js_to_rb(js_props) || {}
      result = instance_exec(rb, &block)
      # React rejects Opal's nil object (has $$id/$call). Coerce to JS null.
      `return #{result} === #{nil} ? null : #{result}`
    end

    # --- Styling ---------------------------------------------------------

    # `stylesheet(card: {...}, body: {...})`
    # Runs the table through RN's StyleSheet.create for RN's native
    # optimisation and returns a Ruby Hash `{ :card => 1, :body => 2 }` of
    # numeric style IDs. The Ruby Hash lets authors still write
    # `styles[:card]` naturally.
    def stylesheet(hash)
      converted = deep_to_native(hash)
      created   = `RN.StyleSheet.create(#{converted})`
      hash.each_key.each_with_object({}) do |k, out|
        out[k] = `#{created}[#{k.to_s}]`
      end
    end

    # --- Theme -----------------------------------------------------------

    COLORS = {
      background:    '#000000',
      surface:       '#16181c',
      border:        '#2f3336',
      borderSoft:    '#1f2327',
      text:          '#e7e9ea',
      textMuted:     '#71767b',
      textSecondary: '#a9b0b5',
      accent:        '#1d9bf0',
      accentDim:     '#1a8cd8',
      like:          '#f91880',
      repost:        '#00ba7c',
      warning:       '#ffd400'
    }.freeze

    SPACING = { xs: 4, sm: 8, md: 12, lg: 16, xl: 24 }.freeze
  end
end
