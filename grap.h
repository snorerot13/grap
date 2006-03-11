// -*-c++-*-
#ifndef GRAP_H
#define GRAP_H
// This file is (c) 1998-2001 Ted Faber (faber@lunabase.org) see COPYRIGHT
// for the full copyright and limitations of liabilities.
#ifndef DEFINES
#define DEFINES "/usr/share/grap/grap.defines"
#endif

#ifndef STDC_HEADERS
extern "C" {
#ifndef __GNUC__
    size_t strlen(const char*);
    char *strcpy(char *, const char *);
    int strcmp(const char *, const char *);
#endif
    char *strcat(char *, const char *);
    char *strncpy(char *, const char *, const size_t);
    int strncmp(const char *, const char *, const size_t);
};
#endif

#ifndef HAVE_SNPRINTF
// This is the only signature that snprintf is called with in grap.
// It's concievable that someone could smash the stack here, but
// there's not much privlege to gain, and I'd be impressed enough if
// you could print a float that caused a stack overflow and error that
// you can break the code.
inline int snprintf(char *s, int lim, const char *fmt, double d) {
    int tot;

#ifdef SPRINTF_NOT_INT
    // For some reason some old versions of SunOS have an sprintf that
    // doesn't return an int.  In this case, we can't bounds check at all.
    
    sprintf(s,fmt,d);
    tot = lim;
#else    
    if ( (tot = sprintf(s,fmt,d)) > lim ) {
	cerr << "Bad format to internal sprintf crashed the stack" << endl;
	abort();
    }
#endif

    return tot;
}
#else
// AIX seems to have snprintf, but not prototype it..
#ifndef SNPRINTF_DECLARED
extern "C" {
    int snprintf(char *, size_t, const char *, ...);
}
#endif
#endif

using namespace std;

#include <vector>
#include <string>
#include <list>
#include <algorithm>

class DisplayString;
class line;
class coord;
class macro;
class plot;
class tick;
class grid;
class circle;
class shiftdesc;
class keyword;


#ifndef HAVE_HASH_MAP
#include <map>
typedef less<string> Strcmp;

typedef map<string, double *, Strcmp> doubleDictionary;
typedef map<string, coord *, Strcmp> coordinateDictionary;
typedef map<string, line *, Strcmp> lineDictionary;
typedef map<string, macro *, Strcmp> macroDictionary;
typedef map<string, keyword, Strcmp> keywordDictionary;
#else
#include <hash_map>
// A functor for hashing strings - it is an adapter to get to the
// standard library char * hash function.
class Strhash : public unary_function<const string&, size_t> {
private:
    hash<const char *> h;
public:
    size_t operator()(const string& s) const {
	return h(s.c_str());
    }
};

typedef hash_map<string, double *, Strhash> doubleDictionary;
typedef hash_map<string, coord *, Strhash> coordinateDictionary;
typedef hash_map<string, line *, Strhash> lineDictionary;
typedef hash_map<string, macro *, Strhash> macroDictionary;
typedef hash_map<string, keyword, Strhash> keywordDictionary;
#endif
typedef list<plot *> plotSequence;
typedef vector<double> doublevec;
typedef list<double> doublelist;
typedef list<tick *> ticklist;
typedef list<grid *> gridlist;
typedef list<string *> linelist;
typedef list<string *> stringSequence;
typedef list<circle *> circleSequence;
typedef list<struct grap_buffer_state*> lexStack;
typedef list<DisplayString *> stringlist;
typedef list<shiftdesc *> shiftlist;

// number of functions taking 0,1,2 args.  The names of those
// functions are in grap_lex.l and the implementations in the
// jumptables in grap.y
const int NVF1=1;
const int NF0=2;
const int NF1=8;
const int NF2=3;

enum size { ht = 0, wid};

typedef struct {
    int op;
    double expr;
} bydesc;

// this is complex enough to need a constructor/destructor
class for_descriptor {
 public:
    double *loop_var;
    int dir;
    double limit;
    double by;
    int by_op;
    string *anything;
    for_descriptor() : 
	loop_var(0), dir(0), limit(0.0), by(0.0), by_op(0), anything(0) { }
    for_descriptor(double *lv, int d, double l, int b, int bo, string *a) :
	loop_var(lv), dir(d), limit(l), by(b), by_op(bo), anything(a) { }
    ~for_descriptor() {
	if ( anything) {
	    delete anything;
	    anything = 0;
	}
    }
};

typedef enum { GFILE=1,  GMACRO, GINTERNAL } grap_input;

class grap_buffer_state {
 public:
    struct yy_buffer_state *yy;
    for_descriptor *f;
    string *name;
    int line;
    int report_start;
    grap_input type;
    int tokenpos;
    grap_buffer_state() :
	yy(0), f(0), name(0), line(0), report_start(0), type(GFILE),
	tokenpos(0) { }
    grap_buffer_state(struct yy_buffer_state *yyb, for_descriptor *fo,
		      string *n, int l, int rs, grap_input t, int tp=0) :
	yy(yyb), f(fo), name(n), line(l), report_start(rs), type(t),
	tokenpos(tp) { }
    // this does *not* call yy_delete_buffer
    ~grap_buffer_state() {
        if ( f ) {
	    delete f;
	    f = 0;
	}
	if ( name ) {
	    delete name;
	    name = 0;
	}
    }
};


extern lexStack lexstack;

#ifdef HAVE_LIMITS
#include <limits>
#define EPSILON numeric_limits<double>::epsilon()
#define MIN_DOUBLE numeric_limits<double>::min()
#else
#define EPSILON		1e-6
#define MIN_DOUBLE	1e-6
#endif


#ifdef HAVE_RANDOM
#ifndef RANDOM_DECLARED
extern "C" {
    long random();
    void srandom(unsigned long);
}
#endif
#else 
#ifdef HAVE_RAND
#define random rand
#define srandom srand
#ifndef RAND_DECLARED
extern "C" {
    long rand();
    void srand(unsigned);
}
#endif
#endif 
#endif

#endif
