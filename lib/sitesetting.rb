# -*- coding: utf-8 -*-
#
# Copyright 2013 whiteleaf. All rights reserved.
#

require "yaml"

class SiteSetting
  def self.load_file(path)
    new(path)
  end

  def [](key)
    replace_group_values(key)
  end

  def []=(key, value)
    @match_values[key] = value
  end

  def clear
    @match_values.clear
  end

  def initialize(path)
    @match_values = {}
    @yaml_setting = YAML.load_file(path)
  end

  def matched?(key)
    @match_values[key]
  end

  def multi_match(source, *keys)
    match_data = nil
    keys.each do |key|
      setting_value = self[key] or next
      [*setting_value].each do |value|
        match_data = source.match(/#{value}/m)
        if match_data
          @match_values[key] = value       # yamlのキーでもmatch_valuesに設定しておくが、
          update_match_values(match_data)  # ←ここで同名のグループ名が定義されていたら上書きされるので注意
                                           # 例えば、title: <title>(?<title>.+?)</title> と定義されていた場合、
                                           # @match_values["title"] には (?<title>.+?) 部分の要素が反映される
          break
        end
      end
    end
    match_data
  end

  def update_match_values(match_data)
    match_data.names.each do |name|
      @match_values[name] = match_data[name] || ""
    end
  end

  def is_container?(value)
    value.kind_of?(Hash) || value.kind_of?(Array)
  end

  def replace_group_values(key, option_values = {})
    dest = option_values[key] || @match_values[key] || @yaml_setting[key]
    return dest if is_container?(dest)
    begin
      result = dest.dup
    rescue TypeError
      return dest
    end
    values = @yaml_setting.merge(@match_values).merge(option_values)
    result.gsub!(/\\\\k<(.+?)>/) do |match|
      value = values[$1]
      if value
        value.gsub(/\\\\k<(.+?)>/) do
          replace_group_values($1, option_values)
        end
      else
        match
      end
    end
    result
  end
end
