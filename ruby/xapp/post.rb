module XApp
  class Post
    attr_reader :id, :author, :body, :created_at, :images, :reply_to,
                :replies, :reposts, :likes, :views, :liked, :reposted, :bookmarked

    def initialize(id:, author:, body:, created_at:, images: [], reply_to: nil,
                   replies: 0, reposts: 0, likes: 0, views: 0,
                   liked: false, reposted: false, bookmarked: false)
      @id = id
      @author = author
      @body = body
      @created_at = created_at
      @images = images
      @reply_to = reply_to
      @replies = replies
      @reposts = reposts
      @likes = likes
      @views = views
      @liked = liked
      @reposted = reposted
      @bookmarked = bookmarked
    end

    def to_h
      {
        id: @id,
        author: @author.to_h,
        body: @body,
        createdAt: @created_at,
        images: @images,
        replyTo: @reply_to,
        replies: @replies,
        reposts: @reposts,
        likes: @likes,
        views: @views,
        liked: @liked,
        reposted: @reposted,
        bookmarked: @bookmarked
      }
    end
  end
end
