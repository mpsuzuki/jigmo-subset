#!/usr/bin/env ruby
require "set"
require "./ruby-utils/getOpts.rb"
require "./ruby-utils/rotator.rb"


rot = Rotator.new(1000)
STDERR.printf("+")
ivd = Hash.new()
if (Opts.include?("ivd-txt"))
  f = File::open(Opts.ivd_txt, "r")
  while (f.gets())
    STDERR.printf(rot.get())
    toks = $_.chomp().gsub(/#.*/, "").split(/;\s*/)
    next if (toks.length < 3)
    hex_with_vs, collection_name, glyph_name, =  toks
    hex_with_vs = hex_with_vs.split(/\s+/).map{|t| t.hex()}
    alt_uni2 = sprintf("%06x.%06x", hex_with_vs.first, hex_with_vs.last)
    ivd[collection_name] = Set.new() unless (ivd.include?(collection_name))
    ivd[collection_name].add(alt_uni2)
  end
  f.close()
end
STDERR.puts()

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

  def ivdCollection(coll_name, ivd)
    return false unless (@attr.include?("AltUni2"))

    alt_uni2s = @attr["AltUni2"].map{|t| t.split(".")[0..1].join(".")}
    # STDERR.puts( "# alt_uni2s: " + alt_uni2s.join(" ") )
    return alt_uni2s.any?{|a| ivd[coll_name].include?(a)}
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

  def name()
    return @lines.select{|l| l =~ /StartChar: /}.first.gsub(/StartChar:\s+/, "")
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

puts sfdFonts.first.sfdPreamble.map{|l|
  if (l =~ /^FontName: / && Opts.include?("font-name"))
    ["FontName", Opts.font_name].join(": ")
  elsif (l =~ /^FullName: / && Opts.include?("full-name"))
    ["FullName", Opts.full_name].join(": ")
  else
    l
  end
}.join("\n")
printf("BeginChars: %d %d\n", numCodeSpace, numDefinedChars)

encoding_done = Set.new()
sfdFonts.each_with_index do |sfdFont, fi|
  baseUcss = Set.new()
  sfdFont.sfdChars.each_with_index do |sc, gi|
    next if (!sc.hasAltUni2())
    if (0 < ivd.length && Opts.include?("ivd-collection"))
      next if (!sc.ivdCollection(Opts.ivd_collection, ivd))
    end
    baseUcss += sc.attr["AltUni2"].map{|t| t.split(".").first.hex()}.sort().uniq().map{|i| sprintf("uni%04X", i)}
  end
  sfdFont.sfdChars.each do |sc|
    if (!sc.hasAltUni2())
      uniHex = sprintf("uni%04X", sc.attr["Encoding"].first)
      if (!baseUcss.include?(uniHex)) 
        STDERR.printf("# discard : %s with no IVS, and not base glyph for VS instances\n", sc.attr["StartChar"])
        next
      end
      STDERR.printf("%s has no UVS, but include as a base character\n", uniHex)
    elsif (0 < ivd.length && Opts.include?("ivd-collection"))
      if (!sc.ivdCollection(Opts.ivd_collection, ivd))
        STDERR.printf("# discard AltUni2: %s\n", sc.attr["AltUni2"].join(" "))
        next
      end
    end

    enc = sc.attr["Encoding"].first
    if (0 < fi)
      if (encoding_done.include?(enc))
        STDERR.printf("# character \"%s\" @ 0x%04X is already emitted by previous font, skip this\n", sc.name(), enc)
        next
      else
        STDERR.printf("# character \"%s\" @ 0x%04X is not emitted yet, include this\n", sc.name(), enc)
      end
    end
    next if (sc.isASCII() && encoding_done.include?(enc))

    puts()
    puts sc.to_s()
    encoding_done << enc
  end
end

puts()
puts sfdFonts.first.sfdPostamble.join("\n")
