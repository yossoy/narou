# -*- coding: utf-8 -*-
#
# Copyright 2013 whiteleaf. All rights reserved.
#

require "yaml"
require_relative "narou"

#
# Narou.rbのシステムが記録するデータ単位
#
# .narou ディレクトリにYAMLファイルとして保存される
# scope に :global を指定するとユーザーディレクトリ/.narousetting に保存される
#
module Inventory
  def self.load(name, scope = :local)
    @@cache ||= {}
    return @@cache[name] if @@cache[name]
    {}.tap { |h|
      h.extend(Inventory)
      h.init(name, scope)
      @@cache[name] = h
    }
  end

  def self.clear
    @@cache = {}
  end

  def init(name, scope)
    dir = case scope
          when :local
            Narou.get_local_setting_dir
          when :global
            Narou.get_global_setting_dir
          else
            raise "Unknown scope"
          end
    return nil unless dir
    @mutex = Mutex.new
    @inventory_file_path = File.join(dir, name + ".yaml")
    if File.exist?(@inventory_file_path)
      self.merge!(Helper::CacheLoader.memo(@inventory_file_path) { |yaml|
        YAML.load(yaml)
      })
    end
  end

  def save
    unless @inventory_file_path
      raise "not initialized setting dir yet"
    end
    @mutex.synchronize do
      File.write(@inventory_file_path, YAML.dump(self))
    end
  end
end

