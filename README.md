Jigmo-Subset
============

These are subsetting tool of [Jigmo fonts](https://kamichikoichi.github.io/jigmo/),
which cover CJK Unified Ideographs Extension G, H, I, and all IVD registered by 2023.

# Prerequests

* fontforge-nox
* GNU Make
* wget
* Ruby
* unzip (or PKZip)

# How to generate subset fonts

```
git clone https://github.com/mpsuzuki/jigmo-subset.git
cd jigmo-subset
git submodule update --init
make
```

# Background

The intention of the subsetting is primarily for the CC0 implementation of Moji_Joho.
Although IPAmj font is officially provided under OFL, the current owner of IPAmj
seems to discourage the subsetting and format conversion for the web by the third
parties. Considering that there is no official web font publishing (no only subset,
but also complete one), we have to use other implementation for subsetted Moji_Joho
resource.

This kit has small Ruby scripts and GNUmakefile, which download the original
Jigmo font package, unpack it, convert TTFs to SFDs by fontforge, and filter
their non-IVS glyphs, and concatenate to single SFD, then generate a subset
Jigmo.

* JigmoVS.woff2

A font covering all IVS, but no glyph for IVS-less code points.

* JigmoVS-MJ.woff2

A font covering all IVS for Moji_Joho collection, but no glyph for IVS-less
codepoints in Moji_Joho.

* JigmoVS-HD.woff2

A font covering all IVS for Hanyo-Denshi collection, but no glyph for IVS-less
codepoints in Hanyo-Denshi.

# LICENSE

* Jigmo fonts, and their subets converted by this kit.

These are licensed under CC0.

See detailed license packaged in the downloaded zip archive.

* IVD_Sequences.txt are licensed under [UNICODE LICENSE V3](https://www.unicode.org/license.txt)

* Subsetted JigmoVS-XXX.files

Same with original Jigmo fonts, CC0.

* Ruby scripts in this kit

Written by suzuki toshiya, licensed under GNU GPL Version 2.

# ACKNOWLEDGEMENT

The files written by mpsuzuki are supported by JSPS KAKENHI Grant Number 22K12719.
