.NULL: .out

LDLIBS=-ll -ly
CXXFLAGS=-g

OBJS=grap.o grap_lex.o grap_draw.o

.o.out:
	$(CXX) $(CXXFLAGS) $(LDFLAGS) $(.ALLSRC) $(LDLIBS) -o $(.TARGET)
.y.cc:
	$(YACC) -d $(.IMPSRC)
	mv y.tab.c $(.TARGET)

.l.cc:
	$(LEX) -o$(.TARGET) $(.IMPSRC) 

grap:	$(OBJS)

y.tab.h:	grap.cc

grap_lex.o:	grap_lex.cc grap.h y.tab.h grap_data.h grap_draw.h

grap.cc grap_lex.cc:	grap.y grap.h grap_data.h grap_draw.h
grap.cc:	grap.y
grap_lex.cc:	grap_lex.l

grap_draw.o: grap_draw.cc grap.h grap_data.h grap_draw.h

pic.h:	pic.macros
	perl ./pic2c.pl < pic.macros > $@

y.output:	grap.y
	$(YACC) -v $(.ALLSRC)

clean:
	rm -f grap $(OBJS) grap_lex.cc grap.cc  *.o y.tab.h pic.h