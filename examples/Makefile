# This file is (c) 1998 Ted Faber (faber@lunabase.org) see COPYRIGHT
# for the full copyright and limitations of liabilities.
MACROS=-ms 

example.ps:	example.ms
	grap example.ms | groff -pe $(MACROS) > example.ps

local.example.ps:	example.ms
	../grap -d ../grap.defines example.ms | groff -pe $(MACROS) > local.example.ps

clean:
	rm -f *.ps *.pdf *.ps.gz *core
