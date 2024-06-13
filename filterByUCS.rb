#!/usr/bin/env ruby
Encoding.default_internal = "utf-8"
Encoding.default_external = "utf-8"
require "set"
require "json"
require "./ruby-utils/getOpts.rb"
require "./ruby-utils/utils.rb"
require "./ruby-utils/rotator.rb"

rot = Rotator.new(1000)

sfdPreamble  = []
sfdChars     = []
sfdPostamble = ["EndChars", "EndSplineFont"]

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
    # return @lines.join("\n")
    return @lines.select{|l| l !~ /AltUni2/}.join("\n")
  end

  def getCodePoint()
    return @attr["Encoding"].first
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

if (Opts.include?("ucs-keep-file"))
  ucsKeep = Set.new()
  f = File::open(Opts.ucs_keep_file, "r")
  while (f.gets())
    toks = $_.chomp().split(",")
    base = toks.shift().gsub("U+", "").hex()
    if (toks.length > 0)
      delta = toks.pop().to_i()
      (base..(base + delta)).to_a().each do |u|
        ucsKeep << u
      end
    else
      ucsKeep << base
    end
  end
  f.close()
end

if (Opts.include?("coverage-json") && Opts.include?("coverage"))
  ucsKeep = Set.new() if (!ucsKeep)
  f = File::open(Opts.coverage_json, "r")
  # _js = JSON.parse(f.read())
  # p _js
  # _js[Opts.coverage].each do |t|
  JSON.parse(f.read())[Opts.coverage].each do |t|
    b, d, = t.split(",")
    b = b[2..-1].hex()
    if (d) 
      d = d.to_i()
      (0..d).to_a().each{|d2| ucsKeep << (b + d2)}
    else
      ucsKeep << b
    end
  end
  f.close()
end

if (Opts.include?("ucs-drop-file"))
  ucsDrop = Set.new()
  f = File::open(Opts.ucs_drop_file, "r")
  while (f.gets())
    toks = $_.chomp().split(",")
    base = toks.shift().gsub("U+", "").hex()
    if (toks.length > 0)
      delta = toks.pop().to_i()
      (base..(base + delta)).to_a().each do |u|
        ucsDrop << u
      end
    else
      ucsDrop << base
    end
  end
  f.close()
end

numCodeSpace = nil
numDefinedChars = nil
STDERR.printf("+")
while (STDIN.gets())
  STDERR.printf(rot.get())
  $_ = $_.chomp()
  if ($_ =~ /BeginChars/)
    numCodeSpace, numDefinedChars, = $_.split(/:\s+/).last.split(/\s+/).map{|t| t.to_i()}
    break;
  end
  
  sfdPreamble << $_
end

while (STDIN.gets())
  $_ = $_.chomp()
  if ($_ =~ /EndChars/)
    break
  elsif ($_ =~ /StartChar/)
    STDERR.printf(rot.get())
    # p sfdChars.last if (0 < sfdChars.length)
    sfdChars.push(SfdChar.new())
  end
  if (0 < sfdChars.length)
    sfdChars.last.append_line($_)
  end
end

#sfdChars_subset = sfdChars.select{|sc| sc.isNULL() || sc.isASCII() || sc.hasAltUni2()}
sfdChars_subset = sfdChars.select{|sc|
  r = false
  cp = sc.getCodePoint()
  begin
    utf8 = [cp].pack("N").encode("utf-8", "ucs-4be")
  rescue
    STDERR.printf("# include U+%04X (cannot encode as UTF-8)\n", cp)
    r = true
  end
  if (!r)
    # p [cp, utf8]
    if (!utf8.isCJKIdeograph())
      STDERR.printf("# exclude U+%04X (not CJK ideograph)\n", cp)
    end
    r = utf8.isCJKIdeograph()
  end
  if (r && ucsKeep && !ucsKeep.include?(cp))
    STDERR.printf("# exclude U+%04X (not included in keep set)\n", cp)
    r = false
  end
  if (r && ucsDrop && ucsDrop.include?(cp))
    STDERR.printf("# exclude U+%04X (included in drop set)\n", cp)
    r = false
  end
  #if (0x2F < cp && cp < 0x3A)
  #  STDERR.printf("# include U+%04X (digits)\n", cp)
  if (0x20 == cp)
    STDERR.printf("# include U+%04X (ASCII space)\n", cp)
    r = true
  end
  r
}

puts sfdPreamble.join("\n")
printf("BeginChars: %d %d\n", numCodeSpace, sfdChars_subset.length)

sfdChars_subset.each do |sc|
  puts()
  puts sc.to_s()
end

puts()
puts sfdPostamble.join("\n")
