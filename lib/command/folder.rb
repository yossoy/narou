# -*- coding: utf-8 -*-
#
# Copyright 2013 whiteleaf. All rights reserved.
#

require_relative "../helper"

module Command
  class Folder < CommandBase
    def self.oneline_help
      "小説の保存フォルダを開きます"
    end

    def initialize
      super("<target> [<target2> ...]")
      @opt.separator <<-EOS

  ・指定した小説の保存フォルダを開きます。

  Examples:
    narou folder n9669bk
    narou folder musyoku
    narou folder 0
    narou f 0
      EOS
    end

    def execute(argv)
      super
      if argv.empty?
        puts @opt.help
        return
      end
      tagname_to_ids(argv)
      argv.each do |target|
        dir = Downloader.get_novel_data_dir_by_target(target)
        if dir
          Helper.open_directory(dir)
          puts dir
        else
          error "#{target} は存在しません"
        end
      end
    end
  end
end
