dnl a lower case to upper case utility function
define(tvf_upper,[translit($1,abcdefghijklmnopqrstuvwxyz,ABCDEFGHIJKLMNOPQRSTUVWXYZ)])

dnl set the variable in the first argument to the value in the second if 
dnl the c++ compiler is a GNU compiler.  Export the variable as a substitution
AC_DEFUN([TVF_PROG_GXX_SUBST],[
AC_REQUIRE([AC_PROG_CXX])
# Set g++ specific compiler options 
if test "$GXX" = "yes" ; then
	$1="$2"
else
	$1=""
fi
AC_SUBST($1)
])

dnl set the variable in the first argument to the value in the second if 
dnl the C compiler is a GNU compiler
AC_DEFUN([TVF_PROG_GCC_SUBST],[
AC_REQUIRE([AC_PROG_CC])
# Set g++ specific compiler options 
if test "$GCC" = "yes" ; then
	$1="$2"
else
	$1=""
fi
AC_SUBST($1)
])

dnl if the install doesn't handle -d properly, fall back to the install script
AC_DEFUN([TVF_PROG_INSTALL_D],[
AC_REQUIRE([AC_PROG_INSTALL])
AC_CACHE_CHECK(whether $INSTALL supports -d, tvf_cv_prog_install_d, 
	if $INSTALL -d /tmp/test$$ && test -d /tmp/test$$ ; then 
		tvf_cv_prog_install_d="yes"
	else
		tvf_cv_prog_install_d="no"
	fi
	rm -rf /tmp/test$$
)

if test "$tvf_cv_prog_install_d" = "no" ; then
	INSTALL=$ac_install_sh
fi
])

dnl check for various methods of making dependencies, from the mkdep
dnl script to copying precomputed defaults.  Both MKDEP and MKDEPFLAGS are
dnl set and seported via AC_SUBST
AC_DEFUN([TVF_PROG_MKDEP],[
AC_CHECK_PROGS(MKDEP,mkdep gcc, cp)
define(tvf_extra_flags,$1)
# depending on which mkdep method has been found, the args are
# slightly different.  -f is redundant on FreeBSD, but needed other places.  
# The test for that is completely superfluous.
if test $ac_ext = "C" || test $ac_ext = "cc" ; then 
	tvf_compflags='${CXXFLAGS}'
	tvf_mk_gcc=g++
	tvf_mk_include="<iostream>"
else
	tvf_compflags='${CFLAGS}'
	tvf_mk_gcc=gcc
	tvf_mk_include="<stdio.h>"
fi

# make sure that mkdep plays well with others.  Be careful.  Bad mkdep
# implementations are very cranky about parameter order.
if test "$MKDEP" = mkdep; then
	tvf_here=`pwd`
	cd /tmp
	mkdir test.$$ 
	cd test.$$
	# solaris mkdep wants a .depend there already
	touch .depend
	touch test.h
	cat > test.$ac_ext << END
#include $tvf_mk_include
#include "test.h"
int main(int argc, char **argv) { }
END
	$MKDEP -f .depend tvf_extra_flags -MM test.$ac_ext 2> /dev/null > /dev/null
	grep test.h .depend > /dev/null 2>&1
	if  test "$?" != "0"; then 
		# MKDEP does not play well with us, use gcc or cp
		cd $tvf_here
		unset ac_cv_prog_MKDEP
		unset MKDEP
		AC_CHECK_PROGS(MKDEP,gcc, cp)
	else
		cd $tvf_here
	fi
	rm -rf /tmp/test.$$
fi

case "$MKDEP" in 
	mkdep)
		if test `uname` = 'FreeBSD'; then 
			MKDEPFLAGS="tvf_extra_flags -MM $tvf_compflags \${SOURCES}"
		else
			MKDEPFLAGS="-f .depend tvf_extra_flags -MM $tvf_compflags \${SOURCES}"
		fi
	;;
	gcc)
		MKDEP=$tvf_mk_gcc
		MKDEPFLAGS="-MM $tvf_compflags \${SOURCES} >> .depend"
	;;
	cp)
		MKDEPFLAGS='default_depend .depend'
	;;
esac
undefine([tvf_extra_flags])
AC_SUBST(MKDEPFLAGS)
])

dnl See if the given function is both present and declared.  The first
dnl argument is the function to check, the second is a space separated
dnl list of headers to check and the last is an optional CHECK or REPLACE
dnl that determines whether AC_CHECK_FUNCS or AC_REPLACE_FUNCS is called
dnl internally.  Both the usual HAVE_function and function_DECLARED are 
dnl AC_DEFINEd.
AC_DEFUN([TVF_FUNC_DECL],[
define(tvf_call,[AC_]ifelse($3,,CHECK,$3)[_FUNCS(]$1[)])
tvf_call
if test "$ac_cv_func_$1" = "yes" ; then
	AC_CACHE_CHECK(for declaration of $1,tvf_cv_decl_$1,
		for f in $2; do 
			AC_EGREP_HEADER($1,$f,tvf_cv_decl_$1="yes",
					tvf_cv_decl_$1="no")
			if test $tvf_cv_decl_$1 = "yes"; then
				break;
			fi
		done
	)
	if test "$tvf_cv_decl_$1" = "yes"; then
		AC_DEFINE(tvf_upper($1)_DECLARED)
	fi
fi
undefine([tvf_call])
])

dnl determine if one of rand or random is present (preferring random)
dnl and if they are declared.  HAVE_RANDOM and RANDOM_DECLARED (or their
dnl RAND analogs) are set.  stdlib.h and math.h are checked.  If the function 
dnl is declared in math.h RANDOM_IN_MATH or the analog is defined
AC_DEFUN([TVF_DECL_RANDOM], [
if test "x$ac_cv_header_stdc" = "x" -a "x$ac_cv_header_stdlib_h" = "x";
then
	AC_HEADER_STDC
	if test $ac_cv_header_stdc = "no"; then
		AC_CHECK_HEADERS(stdlib.h)
	fi
fi
AC_CHECK_FUNCS(random)
if test $ac_cv_func_random = "no"; then
	AC_CHECK_FUNCS(rand)
else
	# not really, but we never need it if we have random
	ac_cv_func_rand="no"
fi

if test "$ac_cv_func_random" = "no" -a "$ac_cv_func_rand" = "no";  then
	# It's possible to get here because the above tests failed due to
	# autoconf freakiness.  These tests are more portable.  Look for random
	# with either a long or int return type, and try rand with an int.  If
	# none of these show up, punt.
	AC_TRY_LINK([
		extern "C" { long random(); }
	], [
		long x = random();
	],
	AC_DEFINE(HAVE_RANDOM)
	ac_cv_func_random="yes", 
	AC_TRY_LINK([
		extern "C" { int random(); }
	], [
		int x = random();
	],
	AC_DEFINE(HAVE_RANDOM)
	ac_cv_func_random="yes"))
	AC_TRY_LINK([
		extern "C" { int rand(); }
	], [
		int x = rand();
	],
	AC_DEFINE(HAVE_RAND)
	ac_cv_func_random="yes")
	if test "$ac_cv_func_random" = "no" -a $ac_cv_func_rand = "no";  then
		AC_MSG_ERROR(requires either random or rand)
	fi
fi

if test "$ac_cv_func_random" = "yes" ; then
AC_CACHE_CHECK(for location of random() declaration,tvf_cv_header_random_declared,[
	if test "$ac_cv_header_stdc" = "yes" -o "x$ac_cv_header_stdlib_h" = "xyes";
	then
		AC_EGREP_HEADER(srandom,stdlib.h,tvf_cv_header_random_declared="stdlib.h",tvf_cv_header_random_declared="none")
	else
		tvf_cv_header_random_declared="none"
	fi

	if test "$tvf_cv_header_random_declared" = "none"; then 
		#check math.h
		AC_EGREP_HEADER(srandom,math.h,tvf_cv_header_random_declared="math.h",tvf_cv_header_random_declared="none")
	fi

]
)
case "$tvf_cv_header_random_declared" in
	"stdlib.h" )
		AC_DEFINE(RANDOM_DECLARED)
	;;
	"math.h" )
		AC_DEFINE(RANDOM_DECLARED)
		AC_DEFINE(RANDOM_IN_MATH)
	;;
esac
else
AC_CACHE_CHECK(for location of rand() declaration,tvf_cv_header_rand_declared,[
	if test "$ac_cv_header_stdc" = "yes"; then
		AC_EGREP_HEADER(srand,stdlib.h,tvf_cv_header_rand_declared="stdlib.h",tvf_cv_header_rand_declared="none")
	else
		tvf_cv_header_rand_declared="none"
	fi

	if test "$tvf_cv_header_rand_declared" = "none"; then 
		#check math.h
		AC_EGREP_HEADER(srand,math.h,tvf_cv_header_rand_declared="math.h",tvf_cv_header_rand_declared="none")
	fi

]
)
case "$tvf_cv_header_rand_declared" in
	"stdlib.h" )
		AC_DEFINE(RAND_DECLARED)
	;;
	"math.h" )
		AC_DEFINE(RAND_DECLARED)
		AC_DEFINE(RAND_IN_MATH)
	;;
esac
fi
])

dnl see if optarg is defined in unistd.h and cache the result.  
dnl OPTARG_DEFINED is set if optarg is found.
AC_DEFUN([TVF_DECL_OPTARG],[
if test "$ac_cv_header_unistd_h" = "yes" ; then
AC_CACHE_CHECK(for optarg in unistd.h,tvf_cv_header_optarg,
AC_EGREP_HEADER(optarg,unistd.h,tvf_cv_header_optarg="yes";
,tvf_cv_header_optarg="no"))
if test "$tvf_cv_header_optarg" = "yes"; then
AC_DEFINE(OPTARG_DEFINED)
fi
fi
])

dnl see the sh comment
AC_DEFUN([TVF_CREATE_DOT_DEPEND],[
AC_MSG_RESULT(creating default depend file)
# Create an empty .depend that is older than Makefile
# if touch will take a time, set the time explicitly, 
# if not wait a bit so that the created Makefile is newer

if test "$MKDEP" = "cp" ; then 
	cp default_depend .depend
else
	cat < /dev/null > .depend
	touch -t 9912311000 .depend > /dev/null 2>&1 || sleep 1
fi
])

dnl get the OS version.  Export it as OS_VERSION in an AC_SUBST
AC_DEFUN([TVF_OS_VERSION],[
AC_CACHE_CHECK(for OS version,tvf_cv_os_version,
	tvf_cv_os_version=`uname -sr`
)
OS_VERSION=$tvf_cv_os_version
AC_SUBST(OS_VERSION)
AC_DEFINE_UNQUOTED(OS_VERSION,"$OS_VERSION")
])

dnl determine if $MAKE uses .ifdef or ifdef .  If one of these choices
dnl works, the output variables MAKE_IFDEF, MAKE_IFNDEF, MAKE_ELSE,
dnl and MAKE_ENDIF are set to appropriate values.  If the routine
dnl can't tell which ones to use, the output variables are defined as
dnl comment characters.  Can be  overridden with --enable-make-ifdef=.

AC_DEFUN([TVF_MAKE_IFDEF], [
AC_ARG_ENABLE(make-ifdef,
[  --enable-make-ifdef=X   set the string format used for ifdef in Makefiles 
                          either .ifdef, ifdef or no ],
[ 
AC_MSG_CHECKING([make ifdef directive])
tvf_cv_make_ifdef=$enableval
AC_MSG_RESULT($tvf_cv_make_ifdef (arg))
],
AC_CACHE_CHECK([make ifdef directive],tvf_cv_make_ifdef,
	tvf_cv_make_ifdef="no"
	tvf_here=`pwd`
	cd /tmp
	mkdir make.$$
	cd make.$$
	cat > Makefile <<END
ifdef TEST
test:
	touch test
endif
END
	if ${MAKE-make} TEST=y -f ./Makefile > /dev/null 2> /dev/null && \
	   test -e ./test ; then
		tvf_cv_make_ifdef="ifdef"
	else
		rm -f test
		cat > Makefile <<END
.ifdef TEST
test:
	touch test
.endif

END
		if ${MAKE-make} TEST=y -f ./Makefile > /dev/null 2>/dev/null \
		   && test -e ./test ; then
			tvf_cv_make_ifdef=".ifdef"
		fi
	fi
	cd /tmp
	rm -rf make.$$
	cd $tvf_here
))
	case $tvf_cv_make_ifdef in
		no)
			MAKE_IFDEF='# ifdef'
			MAKE_IFNDEF='# ifndef'
			MAKE_ELSE='# else'
			MAKE_ENDIF='# endif'
		;;
		.ifdef)
			MAKE_IFDEF='.ifdef'
			MAKE_IFNDEF='.ifndef'
			MAKE_ELSE='.else'
			MAKE_ENDIF='.endif'
		;;
		ifdef)
			MAKE_IFDEF='ifdef'
			MAKE_IFNDEF='ifndef'
			MAKE_ELSE='else'
			MAKE_ENDIF='endif'
		;;
	esac
	AC_SUBST(MAKE_IFDEF)
	AC_SUBST(MAKE_IFNDEF)
	AC_SUBST(MAKE_ELSE)
	AC_SUBST(MAKE_ENDIF)
])

dnl determine if the -mdoc macros are available.  Export them into MAN_MACROS.
AC_DEFUN([TVF_MAN_MACROS],[
AC_CACHE_CHECK(for manpage macros, tvf_cv_man_macros,[
if troff -mdoc < /dev/null > /dev/null 2> /dev/null; then
	tvf_cv_man_macros=doc
else
	tvf_cv_man_macros=an
fi
])
MAN_MACROS=$tvf_cv_man_macros
AC_SUBST(MAN_MACROS)
])

dnl test a 3-place version number.  The first is the actual version,
dnl the second the limit.  The third is the program name
AC_DEFUN([TVF_CHECK_VERSION_THREE],[
changequote(<<,>>)
tvf_lim_major=`echo "$2" | sed 's/\..*//'`
tvf_lim_minor=`echo "$2" | sed 's/[^\.]*\.\([^.]*\)\..*/\1/'`
tvf_lim_three=`echo "$2" | sed 's/[^\.]*\.[^.]*\.\(.*\)/\1/'`
tvf_act_major=`echo "$1" | sed 's/\..*//'`
tvf_act_minor=`echo "$1" | sed 's/[^\.]*\.\([^.]*\)\..*/\1/'`
tvf_act_three=`echo "$1" | sed 's/[^\.]*\.[^.]*\.\(.*\)/\1/'`
changequote([,])
define([tvf_ok],ifelse("$3","",[true],$3))
define([tvf_bad],ifelse("$4","",[true],$4))
if test $tvf_act_major -lt $tvf_lim_major ; then
	tvf_bad
else
	if test $tvf_act_major -eq $tvf_lim_major && \
	test $tvf_act_minor -lt $tvf_lim_minor ; then 
		tvf_bad
	else
		if test $tvf_act_major -eq $tvf_lim_major && \
			test $tvf_act_minor -eq $tvf_lim_minor &&\
			test $tvf_act_three -lt $tvf_lim_three; then 
			tvf_bad
		else
			tvf_ok
		fi
	fi
fi
undefine([tvf_ok])
undefine([tvf_bad])
])
