#!/usr/bin/env ruby
require "set"
require "./ruby-utils/getOpts.rb"
require "./ruby-utils/rotator.rb"

require "./sfd.rb"

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

numCodeSpace = nil
numDefinedChars = nil

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
