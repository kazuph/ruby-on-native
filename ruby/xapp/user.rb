module XApp
  class User
    attr_reader :id, :handle, :display_name, :avatar_url, :bio, :verified,
                :followers, :following, :location, :joined_at, :banner_url

    def initialize(id:, handle:, display_name:, avatar_url:, bio: '', verified: false,
                   followers: 0, following: 0, location: '', joined_at: '', banner_url: '')
      @id = id
      @handle = handle
      @display_name = display_name
      @avatar_url = avatar_url
      @bio = bio
      @verified = verified
      @followers = followers
      @following = following
      @location = location
      @joined_at = joined_at
      @banner_url = banner_url
    end

    def to_h
      {
        id: @id,
        handle: @handle,
        displayName: @display_name,
        avatarUrl: @avatar_url,
        bio: @bio,
        verified: @verified,
        followers: @followers,
        following: @following,
        location: @location,
        joinedAt: @joined_at,
        bannerUrl: @banner_url
      }
    end
  end
end
