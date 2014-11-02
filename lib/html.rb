# -*- coding: utf-8 -*-
#
# Copyright 2013 whiteleaf. All rights reserved.
#

class HTML
  attr_accessor :string

  def initialize(string = "")
    @string = string
    @illust_current_url = nil
    @illust_grep_pattern = /<img.+?src=\"(?<src>.+?)\".*?>/i
  end

  #
  # 挿絵を置換するための設定を変更する
  #
  def set_illust_setting(options)
    unless options.kind_of?(Hash)
      raise ArgumentError, "invalid parameter(s), need Hash"
    end
    @illust_current_url = options[:current_url] if options[:current_url]
    if grep_pattern = options[:grep_pattern]
      @illust_grep_pattern = grep_pattern.kind_of?(Regexp) ? grep_pattern : /#{grep_pattern}/m
    end
  end

  #
  # 青空文庫形式に変換
  #
  def to_aozora
    @string = br_to_aozora
    @string = ruby_to_aozora
    @string = b_to_aozora
    @string = i_to_aozora
    @string = s_to_aozora
    @string = img_to_aozora
    @string = delete_tag
    @string
  end

  def delete_tag(text = @string)
    text.gsub(/<.+?>/, "")
  end

  def br_to_aozora(text = @string)
    text.gsub(/[\r\n]+/, "").gsub(/<br.*?>/i, "\n")
  end

  def ruby_to_aozora(text = @string)
    text.tr("《》", "≪≫")
        .gsub(/<ruby>(.+?)<\/ruby>/i) do
      splited_ruby = $1.split(/<rt>/i)
      next delete_tag(splited_ruby[0]) unless splited_ruby[1]
      ruby_base = delete_tag(splited_ruby[0].split(/<rp>/i)[0])
      ruby_text = delete_tag(splited_ruby[1].split(/<rp>/i)[0])
      "｜#{ruby_base}《#{ruby_text}》"
    end
  end

  def b_to_aozora(text = @string)
    text.gsub(/<b>/i, "［＃太字］").gsub(/<\/b>/i, "［＃太字終わり］")
  end

  def i_to_aozora(text = @string)
    text.gsub(/<i>/i, "［＃斜体］").gsub(/<\/i>/i, "［＃斜体終わり］")
  end

  def s_to_aozora(text = @string)
    text.gsub(/<s>/i, "［＃取消線］").gsub(/<\/s>/i, "［＃取消線終わり］")
  end

  def img_to_aozora(text = @string)
    if @illust_grep_pattern
      text.gsub(@illust_grep_pattern) do
        url = @illust_current_url ? URI.join(@illust_current_url, $~[:src]) : $~[:src]
        "［＃挿絵（#{url}）入る］"
      end
    else
      text
    end
  end
end
