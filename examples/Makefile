COLOR=-mcolor

example.ps:	example.ms
	grap example.ms | groff -pe -ms $(COLOR) > example.ps

local.example.ps:	example.ms
	../grap -d ../grap.defines example.ms | groff -pe -ms $(COLOR) > local.example.ps

clean:
	rm -f *.ps

