# This file is (c) 1998 Ted Faber (faber@lunabase.org)
.NULL: .out

.ifndef PREFIX
PREFIX=/usr/local/
.endif

BINDIR=${PREFIX}/bin
DEFINESDIR=${PREFIX}/share/grap
MANDIR=${PREFIX}/man/man1
INSTALL=install
RM=rm
RMDIR=rmdir
MKDIR=mkdir
LEX=flex

# Solaris : NO_RANDOM, NO_SNPRINTF
# SunOS  : NO_RANDOM, NO_GETOPT, NO_SNPRINTF

#CXXFLAGS =-g -pipe
CXXFLAGS += -Wall
#CXXFLAGS += -DLEX_DEBUG
CXXFLAGS += -DDEFINES=\"$(DEFINESDIR)/grap.defines\" 
#CXXFLAGS += -DNO_SNPRINTF
#CXXFLAGS += -DNO_RANDOM
#CXXFLAGS =+ -DNO_GETOPT

OBJS=grap.o grap_lex.o grap_draw.o grap_pic.o

all:	grap

.o.out:
	$(CXX) $(CXXFLAGS) $(LDFLAGS) $(.ALLSRC) $(LDLIBS) -o $(.TARGET)
.y.cc:
	$(YACC) -d $(.IMPSRC)
	mv y.tab.c $(.TARGET)

.l.cc:
	$(LEX) -o$(.TARGET) $(.IMPSRC) 

grap:	$(OBJS)

y.tab.h:	grap.cc
grap.cc:	grap.y
grap_lex.cc:	grap_lex.l y.tab.h

grap.o:		grap.cc grap.h grap_data.h grap_draw.h grap_pic.h
grap_lex.o:	grap_lex.cc grap.h y.tab.h grap_data.h grap_draw.h grap_pic.h
grap_draw.o:	grap_draw.cc grap.h grap_data.h grap_draw.h grap_pic.h
grap_pic.o:	grap_pic.cc grap_pic.h grap.h grap_data.h grap_draw.h

y.output:	grap.y
	$(YACC) -v $(.ALLSRC)

grap.1:	grap.doc
	perl -pe "s#DEFINES#$(DEFINESDIR)/grap.defines#g; s#EXAMPLES#$(DEFINESDIR)/examples#g;" < grap.doc > grap.1

clean:
	rm -f grap $(OBJS) grap_lex.cc grap.cc  *.o y.tab.h grap.1

install:	grap grap.defines grap.1
	strip grap
	$(INSTALL) -c -g bin -o root -m 755 grap $(BINDIR)
	$(INSTALL) -c -g bin -o root -m 644 grap.1 $(MANDIR)
	$(INSTALL) -d -g bin -o root -m 755 $(DEFINESDIR)
	$(INSTALL) -d -g bin -o root -m 755 $(DEFINESDIR)/examples
	$(INSTALL) -c -g bin -o root -m 644 grap.defines $(DEFINESDIR)
	$(INSTALL) -c -g bin -o root -m 644 README $(DEFINESDIR)
	$(INSTALL) -c -g bin -o root -m 644 examples/*.d examples/*.ms examples/Makefile $(DEFINESDIR)/examples

deinstall:
	$(RM) $(BINDIR)/grap
	$(RM) $(MANDIR)/grap.1
	$(RM) $(DEFINESDIR)/grap.defines
	$(RM) $(DEFINESDIR)/examples/*.d $(DEFINESDIR)/examples/*.ms $(DEFINESDIR)/examples/Makefile
	$(RMDIR) $(DEFINESDIR)/examples
	$(RMDIR) $(DEFINESDIR)
