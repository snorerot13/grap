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
#include "snprintf.h"
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


#if HAVE_HASH_MAP||HAVE_EXT_HASH_MAP||HAVE_UNORDERED_MAP

#ifdef HAVE_UNORDERED_MAP
#include <unordered_map>

typedef HASH_SPACE::unordered_map<string, double *> doubleDictionary;
typedef HASH_SPACE::unordered_map<string, coord *> coordinateDictionary;
typedef HASH_SPACE::unordered_map<string, line *> lineDictionary;
typedef HASH_SPACE::unordered_map<string, macro *> macroDictionary;
typedef HASH_SPACE::unordered_map<string, keyword> keywordDictionary;
#else
#ifdef HAVE_HASH_MAP
#include <hash_map>
#else
#include <ext/hash_map>
#endif
// A functor for hashing strings - it is an adapter to get to the
// standard library char * hash function.
class Strhash : public unary_function<const string&, size_t> {
private:
    HASH_SPACE::hash<const char *> h;
public:
    size_t operator()(const string& s) const {
	return h(s.c_str());
    }
};

typedef HASH_SPACE::hash_map<string, double *, Strhash> doubleDictionary;
typedef HASH_SPACE::hash_map<string, coord *, Strhash> coordinateDictionary;
typedef HASH_SPACE::hash_map<string, line *, Strhash> lineDictionary;
typedef HASH_SPACE::hash_map<string, macro *, Strhash> macroDictionary;
typedef HASH_SPACE::hash_map<string, keyword, Strhash> keywordDictionary;
#endif

#else
#include <map>
typedef less<string> Strcmp;

typedef map<string, double *, Strcmp> doubleDictionary;
typedef map<string, coord *, Strcmp> coordinateDictionary;
typedef map<string, line *, Strcmp> lineDictionary;
typedef map<string, macro *, Strcmp> macroDictionary;
typedef map<string, keyword, Strcmp> keywordDictionary;
#endif

typedef list<plot *> plotSequence;
typedef vector<double> doublevec;
typedef list<double> doublelist;
typedef list<tick *> ticklist;
typedef list<grid *> gridlist;
typedef list<string *> linelist;
typedef list<string *> stringSequence;
typedef list<circle *> circleSequence;
typedef list<class grap_buffer_state*> lexStack;
typedef list<DisplayString *> stringlist;
typedef list<shiftdesc *> shiftlist;

// number of functions taking 0,1,2 args.  The names of those
// functions are in grap_lex.l and the implementations in the
// jumptables in grap.y
const int NVF1=1;
const int NF0=2;
const int NF1=10;
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
    for_descriptor(double *lv, int d, double l, double b, int bo, string *a) :
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

// Set the coarse and fine limits for double comparisons.  COARSE comparisons
// are always within one millionth.  If fine comparisons are requested, either
// the values in limits are used or one trillionth (1e-12).
#ifdef HAVE_LIMITS
#include <limits>
#define FINE_EPSILON numeric_limits<double>::epsilon()
#define FINE_MIN_DOUBLE numeric_limits<double>::min()
#define COARSE_EPSILON		1e-6
#define COARSE_MIN_DOUBLE	1e-6
#else
#define FINE_EPSILON		1e-12
#define FINE_MIN_DOUBLE		1e-12
#define COARSE_EPSILON		1e-6
#define COARSE_MIN_DOUBLE	1e-6
#endif

extern double epsilon;
extern double min_double;


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
