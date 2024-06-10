all: Jigmo1.ttf Jigmo2.ttf Jigmo3.ttf
.SUFFIXES: .ttf .sfd .woff .woff2

.ttf.sfd:
	fontforge -lang=ff -c 'Open("'$<'");Save("'$@'");Quit()"'

.sfd.woff:
	fontforge -lang=ff -c 'Open("'$<'");Generate("'$@'");Quit()"'

all: JigmoVS.ttf

JigmoVS.ttf: JigmoVS.sfd
	fontforge -lang=ff -c 'Open("'$<'");Generate("'$@'");Quit()"'

JigmoVS.sfd: Jigmo1-VS.sfd Jigmo2-VS.sfd Jigmo3-VS.sfd
	./mergeSFDs.rb $?  > $@

Jigmo1-VS.sfd: Jigmo1.sfd
	./filterCJKnonVS.rb < $< > $@

Jigmo2-VS.sfd: Jigmo2.sfd
	./filterCJKnonVS.rb < $< > $@

Jigmo3-VS.sfd: Jigmo3.sfd
	./filterCJKnonVS.rb < $< > $@

Jigmo-20230816.zip:
	wget https://kamichikoichi.github.io/jigmo/Jigmo-20230816.zip

Jigmo.ttf: Jigmo-20230816.zip
	unzip -x $<

Jigmo1.ttf: Jigmo-20230816/Jigmo.ttf
	ln -s $< $@

Jigmo2.ttf: Jigmo-20230816/Jigmo2.ttf
	ln -s $< $@

Jigmo3.ttf: Jigmo-20230816/Jigmo3.ttf
	ln -s $< $@

