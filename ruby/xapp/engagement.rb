module XApp
  # Pure-Ruby like / repost / bookmark state transitions. Operates on Post
  # Hashes keyed by symbols — the same shape the API layer hands to the UI.
  module Engagement
    module_function

    def toggle_like(post)
      flipped = !post[:liked]
      delta   = flipped ? 1 : -1
      post.merge(liked: flipped, likes: [post[:likes].to_i + delta, 0].max)
    end

    def toggle_repost(post)
      flipped = !post[:reposted]
      delta   = flipped ? 1 : -1
      post.merge(reposted: flipped, reposts: [post[:reposts].to_i + delta, 0].max)
    end

    def toggle_bookmark(post)
      post.merge(bookmarked: !post[:bookmarked])
    end
  end
end
