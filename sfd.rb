require "./ruby-utils/rotator.rb"

class SfdChar
  attr_accessor(:lines, :attr)

  def initialize()
    @attr  = Hash.new()
    @lines = Array.new()
  end

  def append_line(l)
    @lines.push(l)
    if (l =~ /^[A-Za-z0-9]+:\s/)
      toks = l.split(/:\s+/, 2)
      k = toks.first
      @attr[k] = toks.last.split(/\s+/)
      case k
      when /Encoding/
        @attr[k] = @attr[k].map{|t| t.to_i()}
      else
        if (@attr[k].length == 1 && @attr[k].first =~ /^[0-9]+$/)
          @attr[k] = @attr[k][0].to_i()
        elsif (@attr[k].all?{|t| t =~ /^[0-9]+$/})
          @attr[k] = @attr[k].map{|t| t.to_i()}
        elsif (@attr[k].length == 1)
          @attr[k] = @attr[k].first
        end
      end
      # p @attr
    end
  end

  def hasAltUni2()
    return @attr.include?("AltUni2")
  end

  def name()
    return @lines.select{|l| l =~ /StartChar: /}.first.gsub(/StartChar:\s+/, "")
  end

  def ivdCollection(coll_name, ivd)
    return false unless (@attr.include?("AltUni2"))

    alt_uni2s = @attr["AltUni2"].map{|t| t.split(".")[0..1].join(".")}
    # STDERR.puts( "# alt_uni2s: " + alt_uni2s.join(" ") )
    return alt_uni2s.any?{|a| ivd[coll_name].include?(a)}
  end

  def to_s()
    return @lines.join("\n")
  end

  def isPUA()
    return (0x100000 <= @attr["Encoding"].first)
  end

  def shiftPUA(delta_enc)
    return self if (!self.isPUA())

    @attr["Encoding.original"] = @attr["Encoding"]
    @attr["Encoding"] = @attr["Encoding.original"].map.with_index do |v, i|
      if (i < 2)
        v + delta_enc
      else
        v
      end
    end

    idx_Encoding = lines.find_index{|l| l=~ /Encoding:/}
    lines[idx_Encoding] = ["Encoding:", @attr["Encoding"].map{|v| v.to_s()}].flatten().join(" ")
    return self
  end

  def renameByPUA()
    return self if (!self.isPUA())
    idx_StartChar = lines.find_index{|l| l =~ /^StartChar:/}
    lines[idx_StartChar] = sprintf("StartChar: u%06X", @attr["Encoding"].first)
    return self
  end

  def suffixToPUA(s)
    return self if (!self.isPUA())

    idx_StartChar = lines.find_index{|l| l =~ /^StartChar:/}
    lines[idx_StartChar] = lines[idx_StartChar] + s
    return self
  end

  def isNULL()
    # p @attr
    return (@attr["Encoding"][1] < 0)
  end

  def codepoint()
    return (@attr["Encoding"][0])
  end

  def isASCII()
    # p @attr
    return (self.codepoint() < 0x80)
  end

  def isDIGIT()
    # p @attr
    return (0x2F < self.codepoint() && self.codepoint() < 0x3A)
  end
end

class SfdFont
  attr_accessor(:rot)
  attr_accessor(:numCodeSpace, :numDefinedChars)
  attr_accessor(:sfdPreamble, :sfdChars, :sfdPostamble)
  attr_accessor(:fullname)

  def initialize()
    STDERR.printf("+")
    @rot = Rotator.new(1000)
    @sfdPreamble  = []
    @sfdChars     = []
    @sfdPostamble = ["EndChars", "EndSplineFont"]
  end

  def maxPUA()
    return @sfdChars.select{|sc| sc.isPUA()}.map{|sc| sc.attr["Encoding"].first}.sort().last
  end

  def parse(f)
    while (f.gets())
      STDERR.printf(@rot.get())
      $_ = $_.chomp()
      if ($_ =~ /BeginChars/)
        @numCodeSpace, @numDefinedChars, = $_.split(/:\s+/).last.split(/\s+/).map{|t| t.to_i()}
        break
      elsif ($_ =~ /^FullName: /)
        toks = $_.chomp().split(/\s+/)
        toks.shift()
        if (!@fullname)
          @fullname = toks.join("_")
        end
      end
  
      @sfdPreamble << $_
    end

    while (f.gets())
      $_ = $_.chomp()
      if ($_ =~ /EndChars/)
        break
      elsif ($_ =~ /StartChar/)
        STDERR.printf(@rot.get())
        # p @sfdChars.last if (0 < @sfdChars.length)
        @sfdChars.push(SfdChar.new())
      end
      if (0 < @sfdChars.length)
        @sfdChars.last.append_line($_)
      end
    end

    return self
  end
end
