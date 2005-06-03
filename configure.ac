dnl -*-m4-*-
dnl Process this file with autoconf to produce a configure script.
AC_INIT(grap, 1.36pre, faber@lunabase.org)
AC_CONFIG_HEADER(config.h)
AC_LANG_CPLUSPLUS

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
TVF_PROG_INSTALL_D
TVF_PROG_MKDEP
TVF_OS_VERSION

AC_SUBST(INSTALL_DOCS)

dnl Checks for libraries.

dnl Checks for header files.
AC_HEADER_STDC
if test $ac_cv_header_stdc = "no"; then
	AC_CHECK_HEADERS(stdlib.h)
fi
AC_CHECK_HEADERS(unistd.h errno.h hash_map)

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
main(int argc, char* argv) {
	char a<<[10]>>;
	if ( (char *) sprintf(a,"ten") == a ) exit(1);
	else exit(0);
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

TVF_CREATE_DOT_DEPEND
AC_OUTPUT(examples/Makefile Makefile)
