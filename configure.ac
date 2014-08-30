dnl -*-m4-*-
dnl Process this file with autoconf to produce a configure script.
dnl NB grap.m4 moved to source dir for automake
m4_include([grap.m4])
AC_INIT(grap, 1.45, faber@lunabase.org)
AC_CONFIG_HEADER(config.h)
AM_INIT_AUTOMAKE
AC_LANG_CPLUSPLUS

dnl for autoheader
AH_TEMPLATE([DEFINES], [The pathname of the grap.defines file])
AH_TEMPLATE([DOCS_DIR], [The directory for documentation])
AH_TEMPLATE([EXAMPLES_DIR], [The directory for examples])
AH_TEMPLATE([GRAP_SAFER], [True if the grap sprintf command is disabled])
AH_TEMPLATE([HASH_SPACE], [C++ namespace where hash_map lives])
AH_TEMPLATE([OPTARG_DEFINED], [True if optarg is defined by headers])
AH_TEMPLATE([OS_VERSION], [OS version])
AH_TEMPLATE([RANDOM_DECLARED], [True if random() is declared])
AH_TEMPLATE([RANDOM_IN_MATH], [True if random() is declared in math.h])
AH_TEMPLATE([RAND_DECLARED], [True if rand() is declared])
AH_TEMPLATE([RAND_IN_MATH], [True if rand() is declared in math.h])
AH_TEMPLATE([SNPRINTF_DECLARED], [Is snprintf declared?])
AH_TEMPLATE([SPRINTF_NOT_INT], [True if sprintf does not return an integer])
AH_TEMPLATE([STRDUP_DECLARED], [True if strdup is declared])
AH_TEMPLATE([STRERROR_DECLARED], [True if strerror is declared])

dnl Note to self: it's possible to get separate tables out of byacc.  It
dnl is confusing because g++ optimizes away the const static tables that
dnl byacc generates, and compiling those tables aren't the problem
dnl anyway.  So don't try it again.

dnl Checks for programs.
AC_PROG_CXX

dnl Set g++ specific compiler options 
TVF_PROG_GXX_SUBST(GXXFLAGS,-Wall)
TVF_PROG_GXX_SUBST(NO_UNDEF,-Wno-unused)
TVF_PROG_GXX_SUBST(SUPPRESS_OPT,-O0)

AC_PROG_LEX
AC_PROG_YACC
AC_PROG_INSTALL
TVF_OS_VERSION

AC_MSG_CHECKING(if ${CXX} supports -std=c++0x)
old_cxxflags="$CXXFLAGS"
old_cppflags="$CPPFLAGS"
CXXFLAGS="$CXXFLAGS -std=c++0x"
CPPFLAGS="$CPPFLAGS -std=c++0x"
AC_TRY_COMPILE([], [], [
	CX0FLAGS="-std=c++0x"
	AC_MSG_RESULT(yes)
	], [
	CX0FLAGS=""
	CXXFLAGS="$old_cxxflags"
	CPPFLAGS="$old_cppflags"
	AC_MSG_RESULT(no)
])
AC_SUBST(CX0FLAGS)

AC_ARG_WITH(defines-dir, 
    [  --with-defines-dir=dir  directory in which to install grap.defines],
AC_SUBST(DEFINES_DIR,$withval),
AC_SUBST(DEFINES_DIR, "$datadir/grap"))

AC_ARG_WITH(example-dir, 
    [  --with-example-dir=dir  directory in which to install examples],
AC_SUBST(EXAMPLE_DIR,$withval),
AC_SUBST(EXAMPLE_DIR, "$datadir/examples/grap"))

AC_ARG_WITH(doc-dir, 
    [  --with-doc-dir=dir      directory in which to install documents],
AC_SUBST(DOC_DIR,$withval),
AC_SUBST(DOC_DIR,"$datadir/doc/grap"))

AC_SUBST(INSTALL_DOCS)

dnl Checks for libraries.

dnl Checks for header files.
AC_HEADER_STDC
if test $ac_cv_header_stdc = "no"; then
	AC_CHECK_HEADERS(stdlib.h)
fi
AC_CHECK_HEADERS(unistd.h errno.h limits)

AC_CHECK_HEADERS(unordered_map hash_map ext/hash_map, [
	AC_COMPILE_IFELSE(
		AC_LANG_PROGRAM([
#ifdef HAVE_UNORDERED_MAP
#include <unordered_map>
#endif
#ifdef HAVE_HASH_MAP
#include <hash_map>
#endif
#ifdef HAVE_EXT_HASH_MAP
#include <ext/hash_map>
#endif
],[
   std::hash<char *> h;
]),
[ AC_DEFINE(HASH_SPACE, std) break],
	AC_COMPILE_IFELSE(
		AC_LANG_PROGRAM([
#ifdef HAVE_UNORDERED_MAP
#include <unordered_map>
#endif
#ifdef HAVE_HASH_MAP
#include <hash_map>
#endif
#ifdef HAVE_EXT_HASH_MAP
#include <ext/hash_map>
#endif
],[
   __gnu_cxx::hash<char *> h;
]),
[ AC_DEFINE(HASH_SPACE, __gnu_cxx) break;],[]))]
)
dnl Checks for typedefs, structures, and compiler characteristics.
AC_TYPE_SIZE_T

dnl Checks for library functions.
TVF_FUNC_DECL(snprintf,stdio.h)
TVF_FUNC_DECL(strdup, stdio.h string.h,REPLACE)
TVF_FUNC_DECL(strerror, stdio.h string.h,REPLACE)

TVF_DECL_RANDOM
TVF_DECL_OPTARG

if test "$ac_cv_func_snprintf" = "no"; then
AC_CACHE_CHECK(if sprintf returns an int, grap_cv_sprintf_int,
AC_TRY_RUN([
changequote(<<, >>)dnl
#include <stdio.h>
int main(int argc, char **argv) {
	char a<<[10]>>;
	if ( (char *) sprintf(a,"ten") == a ) return 1;
	else return 0;
}
changequote([, ])dnl
],grap_cv_sprintf_int="yes",grap_cv_sprintf_int="no",echo ""))

if test "$grap_cv_sprintf_int" = "no" ; then 
AC_DEFINE(SPRINTF_NOT_INT)
fi
fi

test "x$prefix" = xNONE && prefix="$ac_default_prefix"

# expand the data directory parameter.  Repeatedly eval the contents
# of ddir until it has no $ in it.
ddir=$datadir
while echo $ddir | grep '\$' > /dev/null ; do 
	ddir=`eval echo $ddir`
done
AC_DEFINE_UNQUOTED(DEFINES,"${ddir}/grap/grap.defines")

# expand the examples directory parameter.  Repeatedly eval the contents
# of ddir until it has no $ in it.
ddir=$EXAMPLE_DIR
while echo $ddir | grep '\$' > /dev/null ; do 
	ddir=`eval echo $ddir`
done
AC_DEFINE_UNQUOTED(EXAMPLES_DIR,"${ddir}")

# expand the data directory parameter.  Repeatedly eval the contents
# of ddir until it has no $ in it.
ddir=$DOC_DIR
while echo $ddir | grep '\$' > /dev/null ; do 
	ddir=`eval echo $ddir`
done
AC_DEFINE_UNQUOTED(DOCS_DIR,"${ddir}")



dnl if the caller has overridden the decision on suppressing
dnl optimization, use their decision, otherwise optimization has already
dnl been suppressed above
AC_MSG_CHECKING(whether to optimize grap_tokenizer)
AC_ARG_ENABLE(optimize-grap_tokenizer, 
[  --enable-optimize-grap_tokenizer   do not prevent optimization of the 
                                     grap_tokenize.cc file], 
ac_cv_grap_opt_tok="yes",
AC_CACHE_VAL(ac_cv_grap_opt_tok, ac_cv_grap_opt_tok="no"))
AC_MSG_RESULT($ac_cv_grap_opt_tok)

if test "$ac_cv_grap_opt_tok" = "yes" ; then 
	SUPPRESS_OPT=""
fi

AC_MSG_CHECKING(whether configure called from a FreeBSD port)
AC_ARG_WITH(freebsd-ports,
[  --with-freebsd-ports    configure called by a FreeBSD ports makefile],
ac_cv_grap_opt_port="yes",  
AC_CACHE_VAL(ac_cv_grap_opt_port, ac_cv_grap_opt_port="no"))
AC_MSG_RESULT($ac_cv_grap_opt_port)
if test $ac_cv_grap_opt_port = "no" ; then
	INSTALL_DEPS="all grap.defines grap.1 install-docs"
else
	INSTALL_DEPS="all grap.defines grap.1"
fi
AC_SUBST(INSTALL_DEPS)

AC_MSG_CHECKING(whether to force safer mode)
AC_ARG_WITH(safer-mode,
[  --with-safer-mode       disable sprintf to avoid attacks],
ac_cv_grap_safer_mode="yes",  
AC_CACHE_VAL(ac_cv_grap_safer_mode, ac_cv_grap_safer_mode="no"))
AC_MSG_RESULT($ac_cv_grap_safer_mode)
if test $ac_cv_grap_safer_mode = "yes" ; then
	AC_DEFINE(GRAP_SAFER)
fi

GRAPLIBOBJS=$LIBOBJS
AC_SUBST(GRAPLIBOBJS)
AC_OUTPUT(Makefile)
