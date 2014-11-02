# -*- coding: utf-8 -*-
#
# Copyright 2013 whiteleaf. All rights reserved.
#

require "open3"

#
# 雑多なお助けメソッド群
#
module Helper
  module_function

  HOST_OS = RbConfig::CONFIG["host_os"]

  def os_windows?
    @@os_is_windows ||= HOST_OS =~ /mswin(?!ce)|mingw|bccwin/i
  end

  def os_mac?
    @@os_is_mac ||= HOST_OS =~ /darwin/i
  end

  def os_cygwin?
    @@os_is_cygwin ||= HOST_OS =~ /cygwin/i
  end

  def determine_os
    case
    when os_windows?
      :windows
    when os_mac?
      :mac
    when os_cygwin?
      :cygwin
    else
      :other
    end
  end

  def engine_jruby?
    @@engine_is_jruby ||= RUBY_ENGINE == "jruby"
  end
  
  if engine_jruby? && os_windows?
    require_relative "extensions/windows"
    def $stdin.getch
      WinAPI._getch.chr
    end
  else
    require "io/console"
  end

  #
  # キーボード入力による確認をする
  #
  # :default: エンターを押した場合に返ってくる値
  # :nontty_default: pipe等から接続された場合に返ってくる値
  #
  def confirm(message, default = false, nontty_default = true)
    return nontty_default unless STDIN.tty?
    confirm_msg = "#{message} (y/n)?: "
    STDOUT.print confirm_msg   # Logger でロギングされないように直接標準出力に表示
    while input = $stdin.getch
      STDOUT.puts input
      case input.downcase
      when "y"
        return true
      when "n"
        return false
      else
        return default if input.strip == ""
        STDOUT.print confirm_msg
      end
    end
  end

  def open_browser_linux(address, error_message)
    %w(xdg-open firefox w3m).each do |browser|
      system(%!#{browser} "#{address}"!)
      return if $?.success?
    end
    error error_message
  end

  def open_directory(path, confirm_message = nil)
    if confirm_message
      return unless confirm(confirm_message, false, false)
    end
    case determine_os
    when :windows
      system(%!explorer "file:///#{path.encode(Encoding::Windows_31J)}"!)
    when :cygwin
      system(%!cygstart "#{path}"!)
    when :mac
      system(%!open "#{path}"!)
    else
      open_browser_linux(path, "フォルダが開けませんでした")
    end
  end

  def open_browser(url)
    case determine_os
    when :windows
      escaped_url = url.gsub("%", "%^").gsub("&", "^&")
      # MEMO: start の引数を "" で囲むと動かない
      system(%!start #{escaped_url}!)
    when :cygwin
      system(%!cygstart #{url}!)
    when :mac
      system(%!open "#{url}"!)
    else
      open_browser_linux(url, "ブラウザが見つかりませんでした")
    end
  end

  def print_horizontal_rule
    puts "―" * 35
  end

  def replace_filename_special_chars(str, invalid_replace = false)
    result = str.tr("/:*?\"<>|.", "／：＊？”〈〉｜．").gsub("\\", "￥").gsub("\t", "").gsub("\n", "")
    if invalid_replace
      org_encoding = result.encoding
      result = result.encode(Encoding::Windows_31J, invalid: :replace, undef: :replace, replace: "_")
                     .encode(org_encoding)
    end
    result
  end

  #
  # ダウンロードしてきたデータを使いやすいように処理
  #
  def pretreatment_source(src, encoding = Encoding::UTF_8)
    restor_entity(src.force_encoding(encoding)).gsub("\r", "")
  end

  ENTITIES = { quot: '"', amp: "&", nbsp: " ", lt: "<", gt: ">", copy: "(c)", "#39" => "'" }
  #
  # エンティティ復号
  #
  def restor_entity(str)
    result = str.encode("UTF-16BE", "UTF-8", :invalid => :replace, :undef => :replace, :replace => "?").encode("UTF-8")
    ENTITIES.each do |key, value|
      result.gsub!("&#{key};", value)
    end
    result
  end

  #
  # CYGWINのパスからwindowsのパスへと変換(cygpathを呼び出すだけ)
  #
  def convert_to_windows_path(path)
    `cygpath -aw \"#{path}\"`.strip
  end

  #
  # アンパサンドをエンティティに変換
  #
  def ampersand_to_entity(str)
    str.gsub(/&(?!amp;)/mi, "&amp;")
  end

  #
  # 文章の中から挿絵注記を分離する
  #
  def extract_illust_chuki(str)
    illust_chuki_array = []
    extracted_str = str.gsub(/[ 　\t]*?(［＃挿絵（.+?）入る］)\n?/) do
      illust_chuki_array << $1
      ""
    end
    [extracted_str, illust_chuki_array]
  end

  #
  # 外部コマンド実行中の待機ループの処理を書けるクラス
  #
  # response = Helper::AsyncCommand.exec("処理に時間がかかる外部コマンド") do
  #   print "*"
  # end
  # if response[2].success?
  #   puts "成功しました"
  # end
  #
  class AsyncCommand
    def self.exec(command, sleep_time = 0.5, &block)
      Thread.new {
        loop do
          block.call if block
          sleep(sleep_time)
        end
      }.tap { |th|
        if Helper.engine_jruby?
          # MEMO:
          #   Open3.capture3 - 全く動かない
          #   `` バッククウォート - 出力が文字化けする
          res = Open3.popen3(command) { |i, o, e|
            i.close
            `cd`   # create dummy Process::Status object to $?
            [o.read, e.read, $?]
          }
        else
          res = Open3.capture3(command)
        end
        th.kill
        return res
      }
    end
  end
end

