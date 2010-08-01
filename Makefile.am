

bin_PROGRAMS = grap
grap_SOURCES = grap.yy grap_lex.ll grap_draw.cc grap_pic.cc grap_parse.cc \
	     grap_tokenizer.cc y.tab.h

MYLIBOBJS=@MYLIBOBJS@
grap_LDADD = $(MYLIBOBJS)
grap_DEPENDENCIES = $(MYLIBOBJS)
EXTRA_grap_SOURCES= strdup.cc str2dup.cc strerror.cc

CLEANFILES = grap.cc grap_lex.cc grap.man y.tab.h

BUILT_SOURCES=y.tab.h

dist_man1_MANS = grap.doc

definesdir = @DEFINES_DIR@
dist_defines_DATA = grap.defines

exampledir = @EXAMPLE_DIR@
dist_example_DATA = examples/*.d examples/*.result examples/Makefile \
		    examples/example.ms

docdir = @DOC_DIR@
dist_doc_DATA = README CHANGES COPYRIGHT grap.man


AM_CXXFLAGS = @GXXFLAGS@ @CX0FLAGS@

y.tab.h:	grap.yy
	${YACC} -d grap.yy && rm -f y.tab.c

grap.man:	grap.doc
	groff -mdoc -Tascii grap.doc > grap.man
