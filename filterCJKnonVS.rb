#!/usr/bin/env ruby

require "./ruby-utils/getOpts.rb"
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

  def charName()
    return (@attr["StartChar"])
  end
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

novs_uniHex2char = Hash.new()
sfdChars.select{|sc| !sc.hasAltUni2()}.each do |sc|
  novs_uniHex2char[ sprintf("uni%04X", sc.attr["Encoding"].first) ] = sc
end

# p novs_uniHex2char.keys()

sfdChars_vsglyph  = sfdChars.select{|sc| sc.isNULL() || sc.isASCII() || sc.hasAltUni2()}

sfdChars_baseChar = []
sfdChars_vsglyph.select{|sc| sc.hasAltUni2()}
                .map{|sc| sc.attr["AltUni2"].map{|t| t.split(".").first.hex()}.sort().uniq()}
                .flatten().sort().uniq().each do |ucsInt|
  uniHex = sprintf("uni%04X", ucsInt)
  if (novs_uniHex2char.include?(uniHex))
    # printf("cannot find (non-VS) base glyph for %s\n", uniHex)
    sfdChars_baseChar << novs_uniHex2char[uniHex]
  end
end

# p sfdChars_baseChar.map{|sc| sc.charName()}

# printf("%d glyphs without UVS are added for Firefox workaround\n", sfdChars_baseChar.length)

# p sfdChars_baseChar
sfdChars_subset = sfdChars_baseChar + sfdChars_vsglyph

puts sfdPreamble.join("\n")
printf("BeginChars: %d %d\n", numCodeSpace, sfdChars_subset.length)

sfdChars_subset.each do |sc|
  puts()
  puts sc.to_s()
end

puts()
puts sfdPostamble.join("\n")
