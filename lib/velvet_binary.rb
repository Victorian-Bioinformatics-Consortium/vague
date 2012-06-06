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
