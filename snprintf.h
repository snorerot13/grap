// -*-c++-*-
#ifndef SNPRINTF_H
#define SNPRINTF_H
// This file is (c) 1998-2001 Ted Faber (faber@lunabase.org) see COPYRIGHT
// for the full copyright and limitations of liabilities.

#ifndef HAVE_SNPRINTF
// Snprintf is only called with the following 11 signatures.  Enumerating them
// is ugly, but probably more portable than varargs.  And very few systems have
// no snprintf.  It's conceivable that someone could smash the stack here, but
// there's not much privilege to gain, and I'd be impressed enough if you could
// print a float that caused a stack overflow and error that you can break the
// code.
inline int snprintf(char *s, int lim, const char *fmt) {
    int tot;

#ifdef SPRINTF_NOT_INT
    // For some reason some old versions of SunOS have an sprintf that
    // doesn't return an int.  In this case, we can't bounds check at all.
    
    sprintf(s,fmt);
    tot = lim;
#else    
    if ( (tot = sprintf(s,fmt)) > lim ) {
	std::cerr << "Bad format to internal sprintf crashed the stack" << std::endl;
	abort();
    }
#endif

    return tot;
}

inline int snprintf(char *s, int lim, const char *fmt, double d) {
    int tot;

#ifdef SPRINTF_NOT_INT
    // For some reason some old versions of SunOS have an sprintf that
    // doesn't return an int.  In this case, we can't bounds check at all.
    
    sprintf(s,fmt,d);
    tot = lim;
#else    
    if ( (tot = sprintf(s,fmt,d)) > lim ) {
	std::cerr << "Bad format to internal sprintf crashed the stack" << std::endl;
	abort();
    }
#endif

    return tot;
}

inline int snprintf(char *s, int lim, const char *fmt, double d1, double d2) {
    int tot;

#ifdef SPRINTF_NOT_INT
    // For some reason some old versions of SunOS have an sprintf that
    // doesn't return an int.  In this case, we can't bounds check at all.
    
    sprintf(s,fmt,d1, d2);
    tot = lim;
#else    
    if ( (tot = sprintf(s,fmt,d1, d2)) > lim ) {
	std::cerr << "Bad format to internal sprintf crashed the stack" << std::endl;
	abort();
    }
#endif

    return tot;
}
inline int snprintf(char *s, int lim, const char *fmt, double d1, double d2,
	double d3) {
    int tot;

#ifdef SPRINTF_NOT_INT
    // For some reason some old versions of SunOS have an sprintf that
    // doesn't return an int.  In this case, we can't bounds check at all.
    
    sprintf(s,fmt,d1, d2, d3);
    tot = lim;
#else    
    if ( (tot = sprintf(s,fmt,d1, d2, d3)) > lim ) {
	std::cerr << "Bad format to internal sprintf crashed the stack" << std::endl;
	abort();
    }
#endif

    return tot;
}
inline int snprintf(char *s, int lim, const char *fmt, double d1, double d2,
	double d3, double d4) {
    int tot;

#ifdef SPRINTF_NOT_INT
    // For some reason some old versions of SunOS have an sprintf that
    // doesn't return an int.  In this case, we can't bounds check at all.
    
    sprintf(s,fmt,d1, d2, d3, d4);
    tot = lim;
#else    
    if ( (tot = sprintf(s,fmt,d1, d2, d3, d4)) > lim ) {
	std::cerr << "Bad format to internal sprintf crashed the stack" << std::endl;
	abort();
    }
#endif

    return tot;
}
inline int snprintf(char *s, int lim, const char *fmt, double d1, double d2,
	double d3, double d4, double d5) {
    int tot;

#ifdef SPRINTF_NOT_INT
    // For some reason some old versions of SunOS have an sprintf that
    // doesn't return an int.  In this case, we can't bounds check at all.
    
    sprintf(s,fmt,d1, d2, d3, d4, d5);
    tot = lim;
#else    
    if ( (tot = sprintf(s,fmt,d1, d2, d3, d4, d5)) > lim ) {
	std::cerr << "Bad format to internal sprintf crashed the stack" << std::endl;
	abort();
    }
#endif

    return tot;
}
inline int snprintf(char *s, int lim, const char *fmt, double d1, double d2,
	double d3, double d4, double d5, double d6) {
    int tot;

#ifdef SPRINTF_NOT_INT
    // For some reason some old versions of SunOS have an sprintf that
    // doesn't return an int.  In this case, we can't bounds check at all.
    
    sprintf(s,fmt,d1, d2, d3, d4, d5, d6);
    tot = lim;
#else    
    if ( (tot = sprintf(s,fmt,d1, d2, d3, d4, d5, d6)) > lim ) {
	std::cerr << "Bad format to internal sprintf crashed the stack" << std::endl;
	abort();
    }
#endif

    return tot;
}
inline int snprintf(char *s, int lim, const char *fmt, double d1, double d2,
	double d3, double d4, double d5, double d6, double d7) {
    int tot;

#ifdef SPRINTF_NOT_INT
    // For some reason some old versions of SunOS have an sprintf that
    // doesn't return an int.  In this case, we can't bounds check at all.
    
    sprintf(s,fmt,d1, d2, d3, d4, d5, d6, d7);
    tot = lim;
#else    
    if ( (tot = sprintf(s,fmt,d1, d2, d3, d4, d5, d6, d7)) > lim ) {
	std::cerr << "Bad format to internal sprintf crashed the stack" << std::endl;
	abort();
    }
#endif

    return tot;
}
inline int snprintf(char *s, int lim, const char *fmt, double d1, double d2,
	double d3, double d4, double d5, double d6, double d7, double d8) {
    int tot;

#ifdef SPRINTF_NOT_INT
    // For some reason some old versions of SunOS have an sprintf that
    // doesn't return an int.  In this case, we can't bounds check at all.
    
    sprintf(s,fmt,d1, d2, d3, d4, d5, d6, d7, d8);
    tot = lim;
#else    
    if ( (tot = sprintf(s,fmt,d1, d2, d3, d4, d5, d6, d7, d8)) > lim ) {
	std::cerr << "Bad format to internal sprintf crashed the stack" << std::endl;
	abort();
    }
#endif

    return tot;
}
inline int snprintf(char *s, int lim, const char *fmt, double d1, double d2,
	double d3, double d4, double d5, double d6, double d7, double d8, 
	double d9) {
    int tot;

#ifdef SPRINTF_NOT_INT
    // For some reason some old versions of SunOS have an sprintf that
    // doesn't return an int.  In this case, we can't bounds check at all.
    
    sprintf(s,fmt,d1, d2, d3, d4, d5, d6, d7, d8, d9);
    tot = lim;
#else    
    if ( (tot = sprintf(s,fmt,d1, d2, d3, d4, d5, d6, d7, d8, d9)) > lim ) {
	std::cerr << "Bad format to internal sprintf crashed the stack" << std::endl;
	abort();
    }
#endif

    return tot;
}
inline int snprintf(char *s, int lim, const char *fmt, double d1, double d2,
	double d3, double d4, double d5, double d6, double d7, double d8, 
	double d9, double d10) {
    int tot;

#ifdef SPRINTF_NOT_INT
    // For some reason some old versions of SunOS have an sprintf that
    // doesn't return an int.  In this case, we can't bounds check at all.
    
    sprintf(s,fmt,d1, d2, d3, d4, d5, d6, d7, d8, d9, d10);
    tot = lim;
#else    
    if ( (tot = sprintf(s,fmt,d1, d2, d3, d4, d5, d6, d7, d8, d9, d10)) 
	    > lim ) {
	std::cerr << "Bad format to internal sprintf crashed the stack" << std::endl;
	abort();
    }
#endif

    return tot;
}
#endif
#endif
