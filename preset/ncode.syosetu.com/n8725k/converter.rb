# -*- coding: utf-8 -*-

#
# 対象小説情報
# タイトル: ログ・ホライズン
# 作者: 橙乃ままれ
# URL: http://ncode.syosetu.com/n8725k/
#
converter "ログ・ホライズン" do
  def before(io, element_type)
    data = io.string
    if element_type == "body"
      if data =~ /[｜|]([^《]+)《(、+)》/
        if $1.length == $2.length
          data.gsub!(/[｜|]([^《]+)《(、+)》/) do |match|
            "［＃傍点］" + $1 + "［＃傍点終わり］"
          end
        end
      end
    end
    io
  end

  def after(io, text_type)
    data = io.string
    if text_type == "subtitle"
      data.gsub!(/^[#{ConverterBase::KANJI_NUM}]+/) do |match|
        match.tr(ConverterBase::KANJI_NUM, "０-９")
      end
    end
    io
  end
end
