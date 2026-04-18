module XApp
  module UI
    # Minimal stack-based navigation, Ruby-first:
    #
    #   nav = Nav.new
    #   nav.top                   # => {kind: :tabs, tab: 'home'}
    #   nav.navigate(:post_detail, post_id: 'p1')
    #   nav.back
    #
    # The actual stack lives in React state (use_state) and navigation
    # helpers close over the setter. Components render based on `nav.top`.
    class Nav
      INITIAL = { kind: :tabs, tab: 'home' }.freeze

      def self.use
        stack, set_stack = UI.use_state([INITIAL])
        new(stack, set_stack)
      end

      def initialize(stack, set_stack)
        @stack     = stack
        @set_stack = set_stack
      end

      attr_reader :stack

      def top
        @stack.last
      end

      def depth
        @stack.length
      end

      def in_detail?
        top[:kind] == :post_detail
      end

      def current_tab
        tabs = @stack.find { |r| r[:kind] == :tabs } || INITIAL
        tabs[:tab]
      end

      # `nav.navigate(:post_detail, post_id: 'p1')`
      def navigate(kind, **attrs)
        route = { kind: kind }.merge(attrs)
        @set_stack.call(->(s) { s + [route] })
      end

      def set_tab(tab)
        @set_stack.call(->(s) {
          s.map { |r| r[:kind] == :tabs ? r.merge(tab: tab) : r }
        })
      end

      def back
        @set_stack.call(->(s) { s.length > 1 ? s[0..-2] : s })
      end

      # Pop back to the bottom (tabs) — useful after deleting the post
      # you're currently viewing.
      def reset_to_tabs
        @set_stack.call(->(s) { [s.first || INITIAL] })
      end
    end
  end
end
