# This file is part of : Vague - a GUI frontend for "velvet" a genomic sequence assembler
# Copyright (C) 2012 David R. Powell
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

class Option
  attr_accessor :name, :value, :type, :desc
  def initialize(name,desc,type=nil)
    @name = name
    @desc = desc
    @type = type
  end
end

class Options
  include Enumerable

  def initialize
    @opts=[]
  end

  def add_option(name, desc, type)
    @opts << Option.new(name,desc,type)
  end

  def each
    @opts.each {|o| yield o}
  end

  def get(name)
    @opts.find {|o| o.name == name}
  end

  def concat(opts)
    @opts.concat(opts.entries)
    self
  end

  def +(opts)
    Options.new.concat(self).concat(opts)
  end

  def hide!(names)
    @opts.reject! {|o| names.include?(o.name)}
  end

  def set_defaults!(defaults)
    @opts.each {|o| o.value = defaults[o.name] if defaults[o.name] }
  end

  def expand_opts!(name, wildcard, vals)
    res = Options.new
    each do |opt|
      if opt.name == name
        vals.each do |v|
          res.add_option(opt.name.sub(wildcard, v.to_s), opt.desc, opt.type)
        end
      else
        res.add_option(opt.name, opt.desc, opt.type)
      end
    end
    @opts = res
  end

  def to_command_line
    @opts.map do |opt|
      case opt.type
      when 'flag'
          if opt.value=='yes' then "-#{opt.name}" else nil end
      when 'yes|no'
          if opt.value=='yes' then ["-#{opt.name}", "yes"] else nil end
      else
          if opt.value.nil? || opt.value.empty? then nil else ["-#{opt.name}", opt.value] end
      end
    end.compact.flatten
  end
end
