module XApp
  # Pure-Ruby facade the UI layer calls. Everything returns Ruby Hashes
  # with *symbol* keys — so screens can write `post[:author][:handle]`
  # naturally. The UI↔RN bridge (see `UI#deep_to_native`) handles the
  # symbol → string conversion when values cross into JS.
  module API
    module_function

    def engine_info
      {
        engine:       'Opal',
        rubyPlatform: (defined?(RUBY_PLATFORM) ? RUBY_PLATFORM : 'opal'),
        rubyEngine:   (defined?(RUBY_ENGINE)   ? RUBY_ENGINE   : 'opal'),
        note:         'このデータはすべて Ruby ソースから来ています。UI ツリー ' \
                      '(present DSL) も Ruby、見た目の 100% は Opal でコンパイル ' \
                      'された JavaScript がレンダリングしています。'
      }
    end

    # User-composed posts (persisted in SQLite) come first, then seed posts
    # from `Feed.timeline` — matches the X feed mental model where your own
    # just-posted tweet appears at the top.
    def timeline
      Store.user_posts + Feed.timeline.map(&:to_h)
    end

    def me
      Feed.me.to_h
    end

    # Persist a new post and return it shaped like a timeline entry.
    def build_new_post(body)
      Store.insert_user_post(body)
    end

    def user(handle)
      u = Feed.seed_users.find { |x| x.handle == handle }
      u && u.to_h
    end

    def user_posts(handle)
      Feed.timeline.select { |p| p.author.handle == handle }.map(&:to_h)
    end

    def trends
      Feed.trends
    end

    def notifications
      users = Feed.seed_users.each_with_object({}) { |u, h| h[u.handle] = u.to_h }
      Feed.notifications.map do |n|
        { kind: n[:kind].to_s, actor: users[n[:actor_handle]], body: n[:body] }
      end
    end

    def messages
      users = Feed.seed_users.each_with_object({}) { |u, h| h[u.handle] = u.to_h }
      Feed.messages.map do |m|
        {
          peer:         users[m[:handle]],
          last:         m[:last],
          relativeTime: Formatter.relative_time(m[:ago])
        }
      end
    end
  end
end
