module XApp
  module Feed
    module_function

    PICSUM = 'https://picsum.photos/seed'.freeze

    def me
      User.new(
        id: 'me', handle: 'master_you', display_name: 'マスター',
        avatar_url: "#{PICSUM}/master_you/200/200",
        banner_url: "#{PICSUM}/master_banner/900/300",
        bio: 'Ruby × Opal × React Native の実験中',
        verified: false, followers: 128, following: 42,
        location: 'Localhost', joined_at: '2026年4月から利用'
      )
    end

    # Build a brand-new Post (before persistence). Always attributed to `me`
    # so the compose flow matches X.com's "your tweet appears with your handle".
    def build_new_post(body)
      Post.new(
        id: "local-#{(Time.now.to_f * 1000).to_i}",
        author: me,
        body: body.to_s,
        created_at: 1,
        images: [],
        replies: 0, reposts: 0, likes: 0, views: 1
      )
    end

    def seed_users
      [
        User.new(
          id: 'u1', handle: 'nyancafe', display_name: 'Nyan☕️Cafe',
          avatar_url: "#{PICSUM}/nyancafe/200/200",
          banner_url: "#{PICSUM}/nyancafe_banner/900/300",
          bio: '猫とコーヒーのあるくらし。焙煎士見習い。🐈☕️',
          verified: true, followers: 48_231, following: 312,
          location: 'Tokyo, Japan', joined_at: '2019年4月から利用'
        ),
        User.new(
          id: 'u2', handle: 'matzlab', display_name: 'Matz Lab',
          avatar_url: "#{PICSUM}/matzlab/200/200",
          banner_url: "#{PICSUM}/matzlab_banner/900/300",
          bio: 'Rubyをブラウザに、そしてスマホに。Opalで遊ぶ研究室。',
          verified: true, followers: 12_805, following: 98,
          location: 'Shimane', joined_at: '2012年7月から利用'
        ),
        User.new(
          id: 'u3', handle: 'reactive_gal', display_name: 'リアクティブギャル',
          avatar_url: "#{PICSUM}/reactgal/200/200",
          banner_url: "#{PICSUM}/reactgal_banner/900/300",
          bio: 'RNエンジニア✨ Jotaiとコーヒー☕️とネイル💅が3大栄養素',
          verified: false, followers: 9_421, following: 540,
          location: 'Shibuya', joined_at: '2021年3月から利用'
        ),
        User.new(
          id: 'u4', handle: 'opal_runtime', display_name: 'Opal Runtime',
          avatar_url: "#{PICSUM}/opalrt/200/200",
          banner_url: "#{PICSUM}/opalrt_banner/900/300",
          bio: 'Ruby to JavaScript. Shipping Ruby anywhere JS runs.',
          verified: true, followers: 22_104, following: 12,
          location: 'The Internet', joined_at: '2013年10月から利用'
        ),
        User.new(
          id: 'u5', handle: 'kuro_neko', display_name: '黒猫くろすけ',
          avatar_url: "#{PICSUM}/kuroneko/200/200",
          banner_url: "#{PICSUM}/kuroneko_banner/900/300",
          bio: 'ごはん🍴 ひるね😴 きまぐれツイート',
          verified: false, followers: 304_221, following: 2,
          location: '縁側', joined_at: '2018年9月から利用'
        )
      ]
    end

    def timeline
      users = seed_users
      by_handle = users.each_with_object({}) { |u, h| h[u.handle] = u }

      posts_raw = [
        {
          handle: 'nyancafe', ago: 180,
          body: "新豆入りました☕️ エチオピア シダモ G1。ベリーみたいな甘さで最高〜！\n店頭で焙煎実演やってます🔥 #スペシャルティコーヒー",
          images: %w[nyan_bean1 nyan_bean2],
          replies: 42, reposts: 128, likes: 1_240, views: 28_430, liked: false
        },
        {
          handle: 'matzlab', ago: 1_500,
          body: "Opal 1.8でReact Nativeから呼ぶの、普通に動くな……\nRubyのクラスがそのままJSの `Opal.XApp.Feed.$timeline` で叩ける。",
          images: [],
          replies: 18, reposts: 240, likes: 3_104, views: 58_900, liked: true
        },
        {
          handle: 'reactive_gal', ago: 2_700,
          body: "ねぇこの X クローン、裏側Ruby書いてるってマジ？？ \n{\"engine\": \"Opal\"} って返ってきて、ウケるんだけど🤣💅✨",
          images: %w[reactgal_screen],
          replies: 301, reposts: 880, likes: 12_400, views: 210_800, liked: false, reposted: true
        },
        {
          handle: 'kuro_neko', ago: 5_400,
          body: "にゃーん。（ひざの上から動かない勢）",
          images: %w[kuro_lap],
          replies: 9, reposts: 78, likes: 5_821, views: 98_220, liked: true
        },
        {
          handle: 'opal_runtime', ago: 10_800,
          body: "Ruby's JSON stdlib now available in Opal bundles shipped through Metro.\nYour Ruby `to_h` travels straight into a React Native FlatList. 🚀",
          images: [],
          replies: 54, reposts: 612, likes: 4_820, views: 132_010
        },
        {
          handle: 'nyancafe', ago: 18_000,
          body: "本日のおとも。☕️🐈\n深煎りと黒猫、組み合わせ濃度200%。",
          images: %w[nyan_cat1 nyan_cat2 nyan_cat3 nyan_cat4],
          replies: 120, reposts: 410, likes: 9_210, views: 301_230
        },
        {
          handle: 'reactive_gal', ago: 36_000,
          body: "FlatListのitemがRubyのPostインスタンスのto_h返してる…脳がバグるけど動いてる〜〜〜⭐️",
          images: [],
          replies: 22, reposts: 44, likes: 512, views: 12_030
        },
        {
          handle: 'matzlab', ago: 86_400 * 2,
          body: "Matz曰く「プログラミング言語は楽しくなきゃ意味がない」。\nスマホの上でRuby動かすのも、やっぱり楽しいよね。",
          images: [],
          replies: 140, reposts: 2_200, likes: 28_400, views: 984_200
        }
      ]

      id_seq = 0
      posts_raw.map do |raw|
        id_seq += 1
        author = by_handle[raw[:handle]]
        Post.new(
          id: "p#{id_seq}",
          author: author,
          body: raw[:body],
          created_at: raw[:ago],
          images: raw[:images].map { |seed| "#{PICSUM}/#{seed}/800/600" },
          replies: raw[:replies],
          reposts: raw[:reposts],
          likes: raw[:likes],
          views: raw[:views],
          liked: raw[:liked] || false,
          reposted: raw[:reposted] || false,
          bookmarked: raw[:bookmarked] || false
        )
      end
    end

    def trends
      [
        { category: 'テクノロジー・トレンド', title: '#Opal',       volume: '4,210件' },
        { category: 'プログラミング',          title: 'React Native', volume: '12.4万件' },
        { category: '日本のトレンド',          title: '猫の日',       volume: '38.1万件' },
        { category: 'エンタメ・トレンド',      title: '焙煎',         volume: '2,842件' },
        { category: 'スポーツ・トレンド',      title: '朝ラン',       volume: '6,521件' }
      ]
    end

    def notifications
      [
        { kind: :like,      actor_handle: 'kuro_neko',     body: 'があなたのポストをいいねしました' },
        { kind: :follow,    actor_handle: 'opal_runtime',  body: 'があなたをフォローしました' },
        { kind: :repost,    actor_handle: 'reactive_gal',  body: 'があなたのポストをリポストしました' },
        { kind: :mention,   actor_handle: 'matzlab',       body: '@masterさん、Opal面白いですね' },
        { kind: :like,      actor_handle: 'nyancafe',      body: 'と他47人があなたのポストをいいねしました' }
      ]
    end

    def messages
      [
        { handle: 'kuro_neko',     last: 'にゃ〜〜〜',                        ago: 120 },
        { handle: 'reactive_gal',  last: 'ねぇ今日の夜空いてる？コーヒー☕️', ago: 540 },
        { handle: 'matzlab',       last: 'Opal、次のバージョンで〜',         ago: 3_600 },
        { handle: 'nyancafe',      last: 'ご来店ありがとうございました！',   ago: 86_400 }
      ]
    end
  end
end
