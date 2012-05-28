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
