# backtick_javascript: true
module XApp
  # Persistence for user-authored posts and every comment in the app.
  # Seed timeline (Feed.timeline) stays in-memory so the "feel" is populated
  # immediately, but anything the user composes or replies with is written
  # to SQLite so it survives app restarts.
  module Store
    module_function

    SCHEMA = <<~SQL
      CREATE TABLE IF NOT EXISTS user_posts (
        id           TEXT PRIMARY KEY,
        body         TEXT NOT NULL,
        created_at   INTEGER NOT NULL,   -- unix seconds since epoch
        likes        INTEGER NOT NULL DEFAULT 0,
        reposts      INTEGER NOT NULL DEFAULT 0,
        replies      INTEGER NOT NULL DEFAULT 0,
        views        INTEGER NOT NULL DEFAULT 0,
        liked        INTEGER NOT NULL DEFAULT 0,
        reposted     INTEGER NOT NULL DEFAULT 0,
        bookmarked   INTEGER NOT NULL DEFAULT 0,
        inserted_at  INTEGER NOT NULL    -- monotonic for sort order
      );
      CREATE TABLE IF NOT EXISTS post_comments (
        id           TEXT PRIMARY KEY,
        post_id      TEXT NOT NULL,
        handle       TEXT NOT NULL,
        body         TEXT NOT NULL,
        created_at   INTEGER NOT NULL,
        inserted_at  INTEGER NOT NULL
      );
      CREATE INDEX IF NOT EXISTS idx_comments_post ON post_comments(post_id, inserted_at);
    SQL

    def db
      @db ||= begin
        handle = DB.open('xapp.db')
        handle.exec(SCHEMA)
        seed_comments!(handle)
        handle
      end
    end

    # --- User posts -----------------------------------------------------

    def user_posts
      now    = epoch_now
      author = Feed.me.to_h
      db.all('SELECT * FROM user_posts ORDER BY inserted_at DESC').map do |r|
        seconds_ago = now - r[:created_at].to_i
        {
          id:         r[:id],
          author:     author,
          body:       r[:body],
          createdAt:  [seconds_ago, 1].max,
          images:     [],
          replyTo:    nil,
          replies:    comment_count(r[:id]),
          reposts:    r[:reposts].to_i,
          likes:      r[:likes].to_i,
          views:      r[:views].to_i,
          liked:      r[:liked].to_i      != 0,
          reposted:   r[:reposted].to_i   != 0,
          bookmarked: r[:bookmarked].to_i != 0
        }
      end
    end

    def insert_user_post(body)
      id = "local-#{epoch_ms}"
      db.run(
        'INSERT INTO user_posts (id, body, created_at, inserted_at) VALUES (?, ?, ?, ?)',
        id, body.to_s, epoch_now, epoch_ms
      )
      user_posts.first
    end

    # Delete a user-authored post (seed posts are read-only and won't match).
    # Returns true if a row was actually removed.
    def delete_user_post(id)
      res = db.run('DELETE FROM user_posts WHERE id = ?', id)
      db.run('DELETE FROM post_comments WHERE post_id = ?', id)
      res[:changes].to_i > 0
    end

    def count_user_posts
      db.scalar('SELECT COUNT(*) FROM user_posts').to_i
    end

    # Wipe every user-authored row (used by the Settings sheet's "reset"
    # button). Seed posts come from Feed in-memory so they stay put.
    def delete_all_user_posts
      db.run('DELETE FROM post_comments WHERE post_id IN (SELECT id FROM user_posts)')
      db.run('DELETE FROM user_posts')
      nil
    end

    # --- Comments -------------------------------------------------------

    def comments(post_id)
      users = Feed.seed_users.each_with_object({}) { |u, h| h[u.handle] = u.to_h }
      users['master_you'] = Feed.me.to_h
      now = epoch_now
      db.all('SELECT * FROM post_comments WHERE post_id = ? ORDER BY inserted_at ASC', post_id).map do |r|
        seconds_ago = now - r[:created_at].to_i
        {
          id:         r[:id],
          post_id:    r[:post_id],
          author:     users[r[:handle]] || users['master_you'],
          body:       r[:body],
          createdAt:  [seconds_ago, 1].max
        }
      end
    end

    def insert_comment(post_id, body, handle: 'master_you')
      id = "cmt-#{epoch_ms}"
      db.run(
        'INSERT INTO post_comments (id, post_id, handle, body, created_at, inserted_at) ' \
        'VALUES (?, ?, ?, ?, ?, ?)',
        id, post_id, handle, body.to_s, epoch_now, epoch_ms
      )
      comments(post_id).last
    end

    def comment_count(post_id)
      db.scalar('SELECT COUNT(*) FROM post_comments WHERE post_id = ?', post_id).to_i
    end

    # --- Bulk helpers ---------------------------------------------------

    # `Store.comment_counts(%w[p1 p2 p3])` → `{ 'p1' => 2, 'p3' => 2 }`
    # One `GROUP BY` query instead of N round-trips — used by the timeline
    # facade to avoid the N+1 pattern for reply counts.
    def comment_counts(post_ids)
      ids = Array(post_ids).uniq
      return {} if ids.empty?
      placeholders = (['?'] * ids.length).join(',')
      rows = db.all(
        "SELECT post_id, COUNT(*) AS c FROM post_comments " \
        "WHERE post_id IN (#{placeholders}) GROUP BY post_id",
        *ids
      )
      rows.each_with_object({}) { |r, out| out[r[:post_id]] = r[:c].to_i }
    end

    # --- Seed comments --------------------------------------------------

    SEED_COMMENTS = {
      'p1' => [
        { handle: 'reactive_gal', body: 'あ〜飲みたい☕️ 今日行きます！' },
        { handle: 'kuro_neko',    body: 'にゃーん (一緒に寝てる黒猫)' }
      ],
      'p3' => [
        { handle: 'matzlab',  body: 'Opal on Native、本当に実現するとは……胸熱。' },
        { handle: 'nyancafe', body: 'コーヒー片手に試してるけどサクサクだね☕️' }
      ],
      'p6' => [
        { handle: 'reactive_gal', body: '4枚とも可愛すぎる🐈 うちの子にも見せたい' }
      ]
    }.freeze

    def seed_comments!(handle)
      return if handle.scalar('SELECT COUNT(*) FROM post_comments').to_i > 0
      now = epoch_now
      seq = 0
      SEED_COMMENTS.each do |post_id, list|
        list.each do |c|
          seq += 1
          handle.run(
            'INSERT INTO post_comments (id, post_id, handle, body, created_at, inserted_at) ' \
            'VALUES (?, ?, ?, ?, ?, ?)',
            "seed-cmt-#{seq}", post_id, c[:handle], c[:body], now - seq * 120, seq
          )
        end
      end
    end

    # --- Time helpers ---------------------------------------------------

    def epoch_ms
      `return Date.now()`
    end

    def epoch_now
      `return Math.floor(Date.now() / 1000)`
    end
  end
end
