.NULL: .out

BINDIR=/usr/local/bin
DEFINESDIR=/usr/share/grap
MANDIR=/usr/local/man/man1
INSTALL=install
RM=rm
RMDIR=rmdir
MKDIR=mkdir

LDLIBS=-ll -ly
CXXFLAGS=-g
#CXXFLAGS += -DLEX_DEBUG
CXXFLAGS += -DDEFINES=\"$(DEFINESDIR)/grap.defines\"
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
	rm -f grap $(OBJS) grap_lex.cc grap.cc  *.o y.tab.h

install:	grap grap.defines
	$(INSTALL) -c -g bin -o root -m 755 grap $(BINDIR)
	$(INSTALL) -d -g bin -o root -m 755 $(DEFINESDIR)
	$(INSTALL) -d -g bin -o root -m 755 $(DEFINESDIR)/examples
	$(INSTALL) -c -g bin -o root -m 644 grap.defines $(DEFINESDIR)
	$(INSTALL) -c -g bin -o root -m 644 examples/*.d examples/*.ms examples/Makefile $(DEFINESDIR)/examples

uninstall:
	$(RM) $(BINDIR)/grap
	$(RM) $(DEFINESDIR)/grap.defines
	$(RM) $(DEFINESDIR)/examples/*.d $(DEFINESDIR)/examples/*.ms $(DEFINESDIR)/examples/Makefile
	$(RMDIR) $(DEFINESDIR)/examples
	$(RMDIR) $(DEFINESDIR)
