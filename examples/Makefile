COLOR=-mcolor
MACROS=-ms 

example.ps:	example.ms
	grap example.ms | groff -pe $(MACROS) > example.ps

local.example.ps:	example.ms
	../grap -d ../grap.defines example.ms | groff -pe $(MACROS) > local.example.ps

color_example.ps:	color_example.ms
	grap color_example.ms | groff -pe $(MACROS) $(COLOR) > color_example.ps

local.color_example.ps:	color_example.ms
	../grap -d ../grap.defines color_example.ms | groff -pe $(MACROS) $(COLOR) > local.color_example.ps

clean:
	rm -f *.ps

