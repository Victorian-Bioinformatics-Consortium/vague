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

require 'options'

class VelvetBinary
  attr_reader :comp_options, :std_options, :version, :found, :path
  def initialize(path, binary)
    @binary = binary
    @path = (path.nil? || path.length==0) ? nil : path
    @comp_options ||= {}
    @std_options = Options.new
    parse_options
    #puts "For #{binary}, version=#{@version}\n  comp_options=#{@comp_options.inspect}\n  std_options=#{@std_options.inspect}"
  end

  def exe
    @path ? File.join(@path, @binary) : @binary
  end

  def parse_options
    IO.popen(exe) do |pipe|
      info = pipe.read
      info.scan(/^Version (\S+)/m) { |m| @version=m.first }
      info.scan(/^Compilation settings:(.*?\n)\n/m) { |m| parse_config_options m.first }
      info.scan(/^Options:(.*?\n)\n/m) { |m| parse_standard_options m.first }
      info.scan(/^Standard options:(.*?\n)\n/m) { |m| parse_standard_options m.first }
      info.scan(/^Advanced options:(.*?\n)\n/m) { |m| parse_standard_options m.first }
      @found = true
    end
  rescue => e
    @found = false
    puts "Cannot run binary : #{e}"
  end

  def parse_config_options(str)
    str.scan(/^(\S+) = (.*?)$/m) {|k| @comp_options[k[0]] = k[1] }
  end

  def parse_standard_options(str)
    str.scan(/^\s+-(\S+)(?: <(.*?)>)?\s+: (.*?)$/m) {|k| @std_options.add_option(k[0], k[2], k[1]) }
  end

  def max_kmer
    comp_options['MAXKMERLENGTH'].to_i
  end

  def max_categories
    comp_options["CATEGORIES"].to_i
  end


end
