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
    #
    # Comment counts are fetched in one `GROUP BY` query (see
    # `Store.comment_counts`) to avoid an N+1 on every render.
    def timeline
      seed_hashes = Feed.timeline.map(&:to_h)
      counts = Store.comment_counts(seed_hashes.map { |h| h[:id] })
      seed = seed_hashes.map do |h|
        h.merge(replies: h[:replies] + counts.fetch(h[:id], 0))
      end
      Store.user_posts + seed
    end

    def me
      Feed.me.to_h
    end

    # Persist a new post and return it shaped like a timeline entry.
    def build_new_post(body)
      Store.insert_user_post(body)
    end

    # Remove a user-composed post (seed posts are immutable). Returns true
    # when a row was actually deleted.
    def delete_post(id)
      Store.delete_user_post(id)
    end

    def find_post(id)
      timeline.find { |p| p[:id] == id }
    end

    def comments(post_id)
      Store.comments(post_id)
    end

    def add_comment(post_id, body)
      Store.insert_comment(post_id, body)
    end

    # Case-insensitive substring match over body / handle / displayName.
    # Lives in the API layer (not Store) so the search set stays "whatever
    # the user sees on the feed" — we filter the same list `timeline`
    # returns.
    def search(query)
      q = query.to_s.strip
      return [] if q.empty?
      needle = q.downcase
      timeline.select do |p|
        body   = p[:body].to_s.downcase
        handle = p[:author][:handle].to_s.downcase
        name   = p[:author][:displayName].to_s.downcase
        body.include?(needle) || handle.include?(needle) || name.include?(needle)
      end
    end

    def reset_my_data
      Store.delete_all_user_posts
    end

    def user(handle)
      u = Feed.seed_users.find { |x| x.handle == handle }
      u && u.to_h
    end

    def user_posts(handle)
      seed = Feed.timeline.select { |p| p.author.handle == handle }.map(&:to_h)
      # `master_you` (me) has SQLite-persisted posts too — merge them in.
      mine = handle == Feed.me.handle ? Store.user_posts : []
      mine + seed
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
