#ifndef GRAP_H
#define GRAP_H
// This file is (c) 1998 Ted Faber (faber@lunabase.org) see COPYRIGHT
// for the full copyright and limitations of liabilities.

#ifdef __GNUC__
// No, I don't know why...
#define UnaryFunction unary_function
#endif

#ifndef STDC_HEADERS
extern "C" {
#ifndef __GNUC__
    int strlen(const char*);
    char *strcpy(char *, const char *);
    int strcmp(const char *, const char *);
#endif
    char *strcat(char *, const char *);
    char *strncpy(char *, const char *, const int);
    int strncmp(const char *, const char *, const int);
};
#endif

#ifndef HAVE_SNPRINTF
// This is the only signature that snprintf is called with in grap.
// It's concievable that someone could smash the stack here, but
// there' snot much privlege to gain, and I'd be impressed enough if
// you could print a float that caused a stack overflow and error that
// you can break the code.
inline int snprintf(char *s, int lim, char *fmt, double d) {
    int tot;
    
    if ( (tot = sprintf(s,fmt,d)) > lim ) {
	cerr << "Bad format to internal sprintf crashed the stack" << endl;
	abort();
    }
    return tot;
}
#endif

#include "grap_data.h"
class DisplayString;
class line;
class coord;
class macro;
class plot;
class tick;
class grid;
class circle;
class shiftdesc;

typedef less<String> Strcmp;

typedef map<String, double *, Strcmp> doubleDictionary;
typedef map<String, coord *, Strcmp> coordinateDictionary;
typedef map<String, line *, Strcmp> lineDictionary;
typedef map<String, macro *, Strcmp> macroDictionary;
typedef list<plot *> plotSequence;
typedef list<double> doublelist;
typedef list<tick *> ticklist;
typedef list<grid *> gridlist;
typedef list<String *> linelist;
typedef list<String *> stringSequence;
typedef list<circle *> circleSequence;
typedef list<struct grap_buffer_state*> lexStack;
typedef list<DisplayString *> stringlist;
typedef list<shiftdesc *> shiftlist;

#include "grap_draw.h"
#include "grap_pic.h"


#define RAND 0

#define LOGFCN 0
#define EXP 1
#define INT 2
#define SIN 3
#define COS 4
#define SQRT 5
#define EEXP 6

#define ATAN2 0
#define MINFUNC 1
#define MAXFUNC 2

enum size { ht = 0, wid};

// These can stay structs
typedef struct {
    int op;
    double expr;
} bydesc;

typedef struct {
    axis which;
    double min;
    double max;
} axisdesc;

typedef struct {
    double size;
    int rel;
    int just;
} strmod;

// this is comples enough to need a constructor/destructor
class for_descriptor {
 public:
    double *loop_var;
    int dir;
    double limit;
    double by;
    int by_op;
    String *anything;
    for_descriptor() : 
	loop_var(0), dir(0), limit(0.0), by(0.0), by_op(0), anything(0) { }
    for_descriptor(double *lv, int d, double l, int b, int bo, String *a) :
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
    String *name;
    int line;
    int report_start;
    grap_input type;
    grap_buffer_state() :
	yy(0), f(0), name(0), line(0), report_start(0), type(GFILE) { }
    grap_buffer_state(struct yy_buffer_state *yyb, for_descriptor *fo,
		      String *n, int l, int rs, grap_input t) :
	yy(yyb), f(fo), name(n), line(l), report_start(rs), type(t) { }
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

#define EPSILON	1e-6

#endif
