all: JigmoVS.ttf JigmoVS-MJ.ttf JigmoVS-HD.ttf \
	JigmoVS.woff2 JigmoVS-MJ.woff2 JigmoVS-HD.woff2

.SUFFIXES: .ttf .sfd .woff .woff2

.ttf.sfd:
	fontforge -lang=ff -c 'Open("'$<'");Save("'$@'");Quit()"'

.sfd.woff2:
	fontforge -lang=ff -c 'Open("'$<'");Generate("'$@'");Quit()"'

JigmoVS.ttf: JigmoVS.sfd
	fontforge -lang=ff -c 'Open("'$<'");Generate("'$@'");Quit()"'

JigmoVS-MJ.ttf: JigmoVS-MJ.sfd
	fontforge -lang=ff -c 'Open("'$<'");Generate("'$@'");Quit()"'

JigmoVS-HD.ttf: JigmoVS-HD.sfd
	fontforge -lang=ff -c 'Open("'$<'");Generate("'$@'");Quit()"'


JigmoVS.sfd: Jigmo1-VS.sfd Jigmo2-VS.sfd Jigmo3-VS.sfd
	./mergeSFDs.rb --font-name="JigmoVS" --full-name="JigmoVS" $?  > $@

JigmoVS-MJ.sfd: Jigmo1-VS.sfd Jigmo2-VS.sfd Jigmo3-VS.sfd IVD_Sequences.txt
	./mergeSFDs.rb \
		--ivd-txt=IVD_Sequences.txt --ivd-collection=Moji_Joho \
		--font-name="JigmoVS-Moji_Joho" --full-name="JigmoVS-Moji_Joho" \
		Jigmo1-VS.sfd Jigmo2-VS.sfd Jigmo3-VS.sfd > $@

JigmoVS-HD.sfd: Jigmo1-VS.sfd Jigmo2-VS.sfd Jigmo3-VS.sfd IVD_Sequences.txt
	./mergeSFDs.rb \
		--ivd-txt=IVD_Sequences.txt --ivd-collection=Hanyo-Denshi \
		--font-name="JigmoVS-Hanyo-Denshi" --full-name="JigmoVS-Hanyo-Denshi" \
		Jigmo1-VS.sfd Jigmo2-VS.sfd Jigmo3-VS.sfd > $@

Jigmo1-VS.sfd: Jigmo1.sfd
	./filterCJKnonVS.rb < $< > $@

Jigmo2-VS.sfd: Jigmo2.sfd
	./filterCJKnonVS.rb < $< > $@

Jigmo3-VS.sfd: Jigmo3.sfd
	./filterCJKnonVS.rb < $< > $@

Jigmo-20230816.zip:
	wget https://kamichikoichi.github.io/jigmo/Jigmo-20230816.zip

IVD_Sequences.txt:
	wget https://www.unicode.org/ivd/data/2022-09-13/$@

Jigmo-20230816/Jigmo.ttf: Jigmo-20230816.zip
	unzip -x -n $< $@
	touch $@

Jigmo-20230816/Jigmo2.ttf: Jigmo-20230816.zip
	unzip -x -n $< $@
	touch $@

Jigmo-20230816/Jigmo3.ttf: Jigmo-20230816.zip
	unzip -x -n $< $@
	touch $@

Jigmo1.ttf: Jigmo-20230816/Jigmo.ttf
	ln -sf $< $@

Jigmo2.ttf: Jigmo-20230816/Jigmo2.ttf
	ln -sf $< $@

Jigmo3.ttf: Jigmo-20230816/Jigmo3.ttf
	ln -sf $< $@

clean:
	rm -rvf Jigmo-20230816/* Jigmo-20230816.zip IVD_Sequences.txt
	rm -vf *.sfd *.ttf *.woff*

coverage.json:
	wget -O coverage.json \
	"https://gitlab.com/mpsuzuki/mj-shrink-map/-/raw/main/coverage.json?ref_type=heads&inline=false"

Jigmo1-KX-no-MSMin.sfd: Jigmo1.sfd coverage.json
	./filterByUCS.rb \
		--ucs-drop-file=MSTT/msmincho.have.txt \
		--coverage-json=coverage.json \
		--coverage=kKangXi  < Jigmo1.sfd > $@

Jigmo2-KX-no-MSMin.sfd: Jigmo2.sfd coverage.json
	./filterByUCS.rb \
		--ucs-drop-file=MSTT/msmincho.have.txt \
		--coverage-json=coverage.json \
		--coverage=kKangXi  < Jigmo2.sfd > $@

Jigmo-KX-no-MSMin.sfd: Jigmo1-KX-no-MSMin.sfd Jigmo2-KX-no-MSMin.sfd
	./mergeSFDs-noVS.rb \
		$^ > $@

Jigmo-KX-no-MSMin.ttf: Jigmo-KX-no-MSMin.sfd
	fontforge -lang=ff -c 'Open("'$<'");Generate("'$@'");Quit()"'

Jigmo1-Morohashi-no-MSMin.sfd: Jigmo1.sfd coverage.json
	./filterByUCS.rb \
		--ucs-drop-file=MSTT/msmincho.have.txt \
		--coverage-json=coverage.json \
		--coverage=kMorohashi  < Jigmo1.sfd > $@

Jigmo2-Morohashi-no-MSMin.sfd: Jigmo2.sfd coverage.json
	./filterByUCS.rb \
		--ucs-drop-file=MSTT/msmincho.have.txt \
		--coverage-json=coverage.json \
		--coverage=kMorohashi  < Jigmo2.sfd > $@

Jigmo-Morohashi-no-MSMin.sfd: Jigmo1-Morohashi-no-MSMin.sfd Jigmo2-Morohashi-no-MSMin.sfd
	./mergeSFDs-noVS.rb \
		$^ > $@

Jigmo-Morohashi-no-MSMin.ttf: Jigmo-Morohashi-no-MSMin.sfd
	fontforge -lang=ff -c 'Open("'$<'");Generate("'$@'");Quit()"'
