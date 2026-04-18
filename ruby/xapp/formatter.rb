module XApp
  module Formatter
    module_function

    # 12_345 -> "12.3K", 1_200_000 -> "1.2M"
    def compact_count(n)
      return '' if n.nil?
      n = n.to_i
      return n.to_s if n < 1_000
      return format_fixed(n / 1_000.0, 'K') if n < 1_000_000
      return format_fixed(n / 1_000_000.0, 'M') if n < 1_000_000_000
      format_fixed(n / 1_000_000_000.0, 'B')
    end

    def relative_time(seconds_ago)
      seconds_ago = seconds_ago.to_i
      return "#{seconds_ago}s" if seconds_ago < 60
      return "#{(seconds_ago / 60).to_i}m" if seconds_ago < 3_600
      return "#{(seconds_ago / 3_600).to_i}h" if seconds_ago < 86_400
      return "#{(seconds_ago / 86_400).to_i}d" if seconds_ago < 604_800
      "#{(seconds_ago / 604_800).to_i}w"
    end

    def format_fixed(value, suffix)
      rounded = (value * 10).floor / 10.0
      if rounded == rounded.to_i
        "#{rounded.to_i}#{suffix}"
      else
        "#{rounded}#{suffix}"
      end
    end
  end
end
