
# Grap's source files.  The dance in nodist_grap_SOURCES and EXTRA_DIST is to
# include only the .yy and .ll files without the y.tab.h and generated .cc
# files.
bin_PROGRAMS = grap
grap_SOURCES = grap_draw.cc grap_pic.cc grap_parse.cc grap_tokenizer.cc 
nodist_grap_SOURCES= grap.yy grap_lex.ll y.tab.h
EXTRA_DIST = grap.h grap_data.h grap_draw.h grap_pic.h grap_string.h snprintf.h\
	     grap.yy grap_lex.ll grap.spec
BUILT_SOURCES=y.tab.h

# Support for compiling our own strdup and strerror if needed.  We don't use
# LIBOBJS directly because automake thinks the sources for LIBOBJS are C files.
GRAPLIBOBJS=@GRAPLIBOBJS@
grap_LDADD = $(GRAPLIBOBJS)
grap_DEPENDENCIES = $(GRAPLIBOBJS)
EXTRA_grap_SOURCES= strdup.cc strerror.cc

# Delete generated files on clean
CLEANFILES = grap.cc grap_lex.cc grap.man y.tab.h

# Man page
dist_man1_MANS = grap.doc

# Where to put grap.defines
definesdir = @DEFINES_DIR@
dist_defines_DATA = grap*.defines

# Examples
exampledir = @EXAMPLE_DIR@
dist_example_DATA = examples/*.d examples/*.result examples/Makefile \
		    examples/example.ms

# Other docs
docdir = @DOC_DIR@
dist_doc_DATA = README CHANGES COPYRIGHT grap.man

# Configure supplied C++ flags
AM_CXXFLAGS = @GXXFLAGS@ @CX0FLAGS@

# Rules for y.tab.h and grap.man
y.tab.h:	grap.yy
	${YACC} -d grap.yy && rm -f y.tab.c

grap.man:	grap.doc
	groff -mdoc -Tascii grap.doc > grap.man
