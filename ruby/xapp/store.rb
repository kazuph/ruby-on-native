# backtick_javascript: true
module XApp
  # Persistence for user-authored posts. Seed timeline (Feed.timeline) stays
  # in-memory so the "feel" of the X clone is populated immediately, while
  # anything the user composes via the FAB is written to SQLite so it
  # survives app restarts.
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
    SQL

    def db
      @db ||= begin
        handle = DB.open('xapp.db')
        handle.exec(SCHEMA)
        handle
      end
    end

    # All user posts, newest first.
    def user_posts
      now = epoch_now
      rows = db.all('SELECT * FROM user_posts ORDER BY inserted_at DESC')
      author = Feed.me.to_h
      rows.map do |r|
        seconds_ago = now - r[:created_at].to_i
        {
          id:         r[:id],
          author:     author,
          body:       r[:body],
          createdAt:  [seconds_ago, 1].max,
          images:     [],
          replyTo:    nil,
          replies:    r[:replies].to_i,
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
      id   = "local-#{epoch_ms}"
      now  = epoch_now
      ins  = epoch_ms
      db.run(
        'INSERT INTO user_posts (id, body, created_at, inserted_at) VALUES (?, ?, ?, ?)',
        id, body.to_s, now, ins
      )
      user_posts.first   # return the freshly-inserted row shaped like a Post hash
    end

    def toggle_like(id)
      db.run('UPDATE user_posts SET liked = CASE liked WHEN 0 THEN 1 ELSE 0 END, ' \
             'likes = CASE liked WHEN 0 THEN likes + 1 ELSE MAX(likes - 1, 0) END ' \
             'WHERE id = ?', id)
    end

    def count
      db.scalar('SELECT COUNT(*) FROM user_posts').to_i
    end

    # --- time helpers ---------------------------------------------------

    def epoch_ms
      `return Date.now()`
    end

    def epoch_now
      `return Math.floor(Date.now() / 1000)`
    end
  end
end
