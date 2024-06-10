#!/usr/bin/env ruby

require "./ruby-utils/getOpts.rb"
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

  def to_s()
    return @lines.join("\n")
  end

  def isNULL()
    # p @attr
    return (@attr["Encoding"][1] < 0)
  end

  def isASCII()
    # p @attr
    return (@attr["Encoding"][0] < 0x80)
  end
end

numCodeSpace = nil
numDefinedChars = nil

class SfdFont
  attr_accessor(:rot)
  attr_accessor(:numCodeSpace, :numDefinedChars)
  attr_accessor(:sfdPreamble, :sfdChars, :sfdPostamble)

  def initialize()
    STDERR.printf("+")
    @rot = Rotator.new(1000)
    @sfdPreamble  = []
    @sfdChars     = []
    @sfdPostamble = ["EndChars", "EndSplineFont"]
  end

  def parse(f)
    while (f.gets())
      STDERR.printf(@rot.get())
      $_ = $_.chomp()
      if ($_ =~ /BeginChars/)
        @numCodeSpace, @numDefinedChars, = $_.split(/:\s+/).last.split(/\s+/).map{|t| t.to_i()}
        break
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

sfdFonts = []
Opts.args.each do |sfd|
  # p sfd
  f = File::open(sfd, "r")
  sfdFont = SfdFont.new().parse(f)  
  sfdFonts << sfdFont
  f.close()
end

numCodeSpace    = sfdFonts.map{|sfdFont| sfdFont.numCodeSpace}.max()
numDefinedChars = sfdFonts.map{|sfdFont| sfdFont.numDefinedChars}.inject("+")

puts sfdFonts.first.sfdPreamble.join("\n")
printf("BeginChars: %d %d\n", numCodeSpace, numDefinedChars)

sfdFonts.each do |sfdFont|
  sfdFont.sfdChars.each do |sc|
    puts()
    puts sc.to_s()
  end
end

puts()
puts sfdFonts.first.sfdPostamble.join("\n")
